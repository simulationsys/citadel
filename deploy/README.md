# Raspberry Pi deployment

Templates only. **Nothing here has been installed or run on the Pi** — every
command below is untested against real hardware and should be executed by a
person who can watch it.

## 0. Prerequisites

```bash
python3 --version      # must be 3.11+ (Raspberry Pi OS Bookworm ships 3.11)
uname -m               # must be aarch64 for tflite-runtime wheels
free -h                # a Pi 3B+ has ~1 GB; confirm swap exists
df -h /                # need ~1 GB free
```

If `python3 --version` reports 3.9 (Bullseye), stop: `ml/pest-risk` declares
`requires-python = ">=3.11"` and the editable install will refuse.

## 1. One virtual environment, shared

The edge API and the crop-health CLI can run under the same interpreter —
`app/vision.py` falls back to `sys.executable` when `ml/vision/.venv` is absent.
That is one environment to build, not two to keep in sync.

```bash
cd ~/citadel/services/edge-api
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -e ../../ml/pest-risk     # must come first
.venv/bin/pip install -r requirements.txt
.venv/bin/pip install -r ../../ml/vision/requirements-pi.txt
```

`requirements-pi.txt` installs `tflite-runtime`, **not** TensorFlow. Do not
install `ml/vision/requirements.txt` on the Pi: it pulls the full training stack.

Verify the runtime the inference path will actually pick:

```bash
.venv/bin/python -c "from tflite_runtime.interpreter import Interpreter; print('tflite-runtime OK')"
cd ~/citadel && services/edge-api/.venv/bin/python ml/vision/src/inference.py /path/to/leaf.jpg
```

The second command prints one line of JSON on success, or exits **3** with
`{"error": {"code": "model_unavailable", ...}}` if the runtime or model is
missing. Exit 3 is what the API turns into a 503.

## 2. Run the tests before trusting any of it

```bash
cd ~/citadel/services/edge-api && .venv/bin/python -m unittest discover -s tests -v
cd ~/citadel/ml/pest-risk     && ../../services/edge-api/.venv/bin/python -m unittest discover -s tests -v
cd ~/citadel/ml/vision        && ../../services/edge-api/.venv/bin/python -m unittest discover -s tests -v
```

## 3. Service user and install

```bash
sudo useradd --system --home /home/citadel --shell /usr/sbin/nologin citadel 2>/dev/null || true
sudo chown -R citadel:citadel /home/citadel/citadel

sudo install -d -m 750 -o root -g citadel /etc/citadel
sudo install -m 640 -o root -g citadel deploy/edge.env.example /etc/citadel/edge.env
sudo nano /etc/citadel/edge.env          # adjust paths; leave cloud sync commented

sudo install -m 644 deploy/citadel-edge.service /etc/systemd/system/citadel-edge.service
sudo systemctl daemon-reload
```

> The unit assumes the repo is at `/home/citadel/citadel` and runs as user
> `citadel`. If your checkout is at `/home/pi/citadel` under user `pi`, edit
> `User=`, `Group=`, `WorkingDirectory=`, `ExecStart=` and `ReadWritePaths=`
> to match — all five, or the service will fail to start.

## 4. Enable, start, inspect

```bash
sudo systemctl enable citadel-edge      # start on boot
sudo systemctl start citadel-edge
systemctl status citadel-edge
journalctl -u citadel-edge -f           # live logs
journalctl -u citadel-edge -n 100 --no-pager
```

## 5. Stop, restart, roll back

```bash
sudo systemctl restart citadel-edge
sudo systemctl stop citadel-edge

# Full removal
sudo systemctl disable --now citadel-edge
sudo rm /etc/systemd/system/citadel-edge.service
sudo systemctl daemon-reload
sudo systemctl reset-failed citadel-edge
```

SQLite runs in WAL mode, so a stop needs no special teardown.

## 6. Verify paths resolved correctly under systemd

The most likely silent failure is a second, empty database.

```bash
curl -s localhost:3001/health | python3 -m json.tool
ls -l ~/citadel/services/edge-api/farm.db          # should grow as readings arrive
sudo -u citadel ls -l "$(grep CITADEL_DB_PATH /etc/citadel/edge.env | cut -d= -f2)"
```

`/health` also reports `modelStatus.cropHealth` — check `available: true` and
`runtime: "tflite_runtime"` before relying on the scan demo.

## 7. Networking

The service binds `0.0.0.0:3001`. Both the phone and the ESP32 must use the
Pi's LAN address — **never `localhost`**, which on each device means that
device.

```bash
hostname -I | awk '{print $1}'          # the address to put in both clients
sudo ss -tlnp | grep 3001               # confirm 0.0.0.0, not 127.0.0.1
sudo ufw status                         # if ufw is active, allow from the LAN only
# sudo ufw allow from 192.168.1.0/24 to any port 3001 proto tcp
```

Do not port-forward 3001. There is no authentication on this API; it is designed
for a trusted LAN.
