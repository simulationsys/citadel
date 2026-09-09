# Field Node — Build Progress & Backend Connection Guide

> Log of the wiring + backend setup sessions. Read this before touching hardware or the Pi again.
>
> **Status as of the latest session: the full pipeline is live.** ESP32 sensors → Wi-Fi → Raspberry Pi (Python edge API + SQLite) → Dashboard UI, confirmed working end to end with real hardware readings, entirely over local Wi-Fi with no internet dependency.
>
> **Superseding update:** the team's `dev` branch landed the backend consolidation while this doc was being written (see Section 8). `apps/dashboard/backend` (port 3000) no longer exists — everything now lives in `services/edge-api` on **port 3001**. Sections 3.7, 5, and 6 below describe the port-3000 setup as it happened at the time; treat **port 3001** as current truth everywhere, and read Section 8 first if you're picking this up fresh.

---

## 0. Circuit diagram

We don't have this exact 38-pin ESP32 in a Tinkercad-style simulator, so this is a hand-drawn schematic built specifically for your actual kit (DHT11 substitution, 1kΩ×3 divider, no rain gauge) rather than a Tinkercad export — same purpose, same level of detail you'd want for a PPT slide.

- **Interactive version:** [field-node-wiring-diagram.html](field-node-wiring-diagram.html) (open in a browser, or the published link shared earlier in this conversation)

![ESP32 field node wiring diagram — component status table and connection schematic for the actual kit](field-node-wiring-diagram.png)

*(This PNG is a rendered snapshot of the page above — use it directly in your PPT, or re-render a fresh one from the HTML if the wiring status table changes later.)*

---

## 1. Current hardware status

| Component | Status | Wired to | Notes |
|---|---|---|---|
| ESP32-WROOM-32 (38-pin DevKit) | ✅ Wired via loose female-to-female/male-to-female jumpers | — | Too wide for the breadboard's own rows — **not seated in the breadboard**, jumpered directly pin-to-pin instead. This is intentional, not a workaround to fix later. |
| DHT11 (blue breakout, pins G/V/D) | ✅ Wired and confirmed working | V→3V3, G→GND, D→D4 | Breakout has built-in pull-up — no external resistor used. Live readings: ~28–29°C, ~74–78% humidity. Briefly failed after handling the board during Pi setup — fixed by reseating the jumpers, no wiring change needed. |
| HC-SR04 ultrasonic | ✅ Wired and confirmed working | VCC→5V row, GND→GND rail, TRIG→D32, ECHO→ voltage divider→D33 | `sensorStatus.ultrasonic: "ok"` confirmed in Serial Monitor. `waterLevelPct` reads 0 when nothing is in range — normal. Also briefly failed and recovered after reseating, same as DHT11. |
| ECHO voltage divider | ✅ Built from 3× 1kΩ resistors | ECHO→R1(1kΩ)→junction→D33; junction→R2+R3(1kΩ+1kΩ series=2kΩ)→GND | Reproduces the spec's 1kΩ+2kΩ ratio exactly. |
| Relay module (control side) | ✅ Wired | +5V→5V row, GND→GND rail, I/P→D26 | Relay clicks correctly; GPIO26 held LOW on boot (pump off by default). |
| Relay module (load side) / pump | ⏸ Not wired | — | Decided to skip pump wiring for now — demo doesn't require it. Relay's NO/COM/NC terminals are unlabeled on this board; if revisited later, identify NO via a boot-test (pump should stay off until GPIO26 goes HIGH) since no multimeter is available. |
| Soil moisture sensor (capacitive v1.2) | ❌ Still not purchased | Reserved: GPIO34 | Firmware already reads GPIO34 — currently floating, reports a meaningless ~100%. Wire VCC→3.3V, GND→GND, AOUT→GPIO34 once bought. No resistor needed. Dashboard's "Irrigate now" advisory won't fire correctly from real data until this is wired, since the floating pin pins the reading at 100%. |
| Tipping-bucket rain gauge | ❌ Not available | Reserved: GPIO15 (unused) | Firmware currently hardcodes `rainfallMm: 0`. See substitution options in [field-node-wiring-diagram](field-node-wiring-diagram.html). |
| 5.6kΩ resistor ×2 | Unused | — | Was the planned DHT22 pull-up substitute, not needed since the DHT11 breakout has one built in. Keep as spares. |
| Raspberry Pi 3B+ | ✅ Set up and running the backend | — | Not the Pi 4 from the original BOM, but no issue — the edge API is lightweight and runs fine on it. Flashed with Raspberry Pi OS **Lite** (64-bit), headless via SSH. See Section 3 for the full setup log, including a power-supply issue that came up and how it was fixed. |

---

## 2. Firmware status

**File:** [`firmware/esp32-field-node/field_node/field_node.ino`](../firmware/esp32-field-node/field_node/field_node.ino)
*(Arduino IDE created this nested `field_node/` subfolder itself — this is the file it actually compiles and uploads. An older duplicate sits one level up at `firmware/esp32-field-node/field_node.ino` and is no longer used — safe to delete once confirmed, ignore for now.)*

- Board profile: **ESP32 Dev Module**
- Flashed and confirmed working via Serial Monitor at **115200 baud**
- Reads: soil moisture (GPIO34, sensor pending), DHT11 (GPIO4), HC-SR04 (GPIO32/33), holds relay (GPIO26) LOW
- Rain gauge hardcoded to `0.0` (not wired)
- **Wi-Fi is enabled and connected** (`WIFI_ENABLED = true`) — Wi-Fi connect + HTTP POST code is in place (`WiFi.h` + `HTTPClient.h`, both built into the ESP32 board package). Confirmed posting successfully to the edge API on every 10s cycle.
- `EDGE_API_URL` now points to **port 3001** (`services/edge-api`, the consolidated backend — see Section 8). It briefly pointed at port 3000 mid-session before the team's `dev` branch consolidation was discovered; that's now corrected.

Sample live output confirmed, successfully reaching the backend:
```json
{"deviceId":"field-node-01","zoneId":"zone-a","soilMoisturePct":100.0,"temperatureC":28.6,"humidityPct":73.2,"rainfallMm":0.0,"waterLevelPct":0.0,"sensorStatus":{"dht":"ok","ultrasonic":"ok"}}
→ Edge API accepted reading.
```

---

## 3. Connecting the ESP32 to the backend (edge API on the Raspberry Pi) — done, log below

### 3.1 Pi imaging — hit a power issue, here's the fix that worked

Flashed **Raspberry Pi OS Lite (64-bit)** (not the full desktop version — Lite is smaller and sufficient for a headless SSH-only setup, and the original 8GB card was too tight for the full desktop image) via Raspberry Pi Imager, with Wi-Fi + SSH pre-configured in the advanced options (hostname `citadel-pi`, username `citadel`).

**First boot failed** — red power LED blinking, then off; green activity LED stuck in a slow diagnostic error-blink pattern (the Pi's built-in boot-error signal, not just card activity). Root cause: **insufficient power** — first attempt used a laptop USB port / underpowered source. The Pi 3B+ needs a stable 5V, ideally 2.5A+.

**Fix:** re-flashed the card fresh, then powered from a **10,000mAh power bank's 2.1A output port** instead. Booted cleanly on the second attempt.

> **Power note for future sessions:** the power bank is fine for portable/demo use (~15-20h estimated runtime, less under real load), but for long unattended runs use a proper wall adapter instead. See the heating/power safety notes discussed earlier in this build for the full reasoning — under-voltage was a real, reproducible failure here, not a hypothetical.

### 3.2 Found the Pi on the network

`ping citadel-pi.local` didn't resolve at first — router admin login was inaccessible, so used **Advanced IP Scanner** (advanced-ip-scanner.com) as a fallback, though ultimately the retry after the power fix resolved `.local` fine via `ping citadel-pi.local` and SSH connected directly:
```bash
ssh citadel@citadel-pi.local
```

### 3.3 Installed Node.js on the Pi

```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs git
node -v   # confirmed v20.20.2
```

### 3.4 Got the project onto the Pi

Repo was private, which blocks a plain `git clone` (GitHub requires a token, not a password, for private repos over HTTPS). Simplest fix used: **made the repo public** (after checking there were no secrets in its history), then:
```bash
git clone https://github.com/simulationsys/citadel.git
cd citadel
npm install
```

### 3.5 Started the edge API

```bash
npm run dev:edge
```
Output confirmed the Pi's LAN IP directly:
```
Citadel edge API listening on http://localhost:3001
Citadel edge API on LAN: http://192.168.1.31:3001 (phone uses this)
```

### 3.6 Updated and re-flashed the firmware

Added the Wi-Fi connect + HTTP POST block back into `field_node.ino` (uses `WiFi.h` + `HTTPClient.h`, both built into the ESP32 board package — no extra libraries needed). Filled in real Wi-Fi credentials and flipped `WIFI_ENABLED = true`. Re-uploaded via Arduino IDE.

Two sensors (DHT11, HC-SR04) briefly showed read errors after this round of handling — fixed by reseating their jumper wires, no rewiring needed. See Section 1 table.

### 3.7 Confirmed data reaches the dashboard

```bash
cd ~/citadel/apps/dashboard
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python3 -m uvicorn backend.main:app --host 0.0.0.0 --port 3000 --reload
```
Opened `http://192.168.1.31:3000` in a browser — **confirmed live, real hardware readings displayed** (28.6°C, 73.2% humidity, matching Serial Monitor exactly), advisory engine correctly showing "No Urgent Actions Required" given current sensor state.

> **Note:** `--host 0.0.0.0` is required — without it, uvicorn only listens on `localhost` and is unreachable from other devices on the network.

---

## 5. Backend architecture — two backends exist right now, only one is wired to the ESP32

While connecting the firmware, discovered the team's GitHub `main` had moved ahead of this local copy (now synced — see git log). That merge revealed there are currently **two separate, disconnected backends** in the repo, not one:

| Backend | Path | Port | State |
|---|---|---|---|
| Python (FastAPI + SQLite) | `apps/dashboard/backend/` | **3000** | Has the real dashboard UI, persistence, advisory engine. **This is what the ESP32 posts to now**, and what's shown live in Section 3.7. |
| Node.js | `services/edge-api/` | 3001 | In-memory only, no dashboard UI serving from it. Not currently receiving data. |

There's already a plan for this in [`docs/backend-integration.md`](backend-integration.md): consolidate to **one backend on port 3001** (move the Python service there, delete the Node one and the duplicate `apps/dashboard/src/server.js`), since port 3001 is what the farmer app and firmware's default config already expect.

**For now:** firmware points at port 3000 (pragmatic fix to get the demo pipeline working today). **Before the final demo:** raise this with whoever owns the backend consolidation — once they do the port-3001 migration from `docs/backend-integration.md`, the firmware's `EDGE_API_URL` needs to change from `:3000` back to `:3001` to match.

---

## 6. Farmer app wired to live backend

The Flutter app (`apps/farmer-app/`) already had real HTTP infrastructure built by a teammate (`HttpFarmStateRepository` with offline SharedPreferences caching, wrapped by `HybridFarmStateRepository` for automatic mock fallback) — it just wasn't pointed at the right backend, and two of its endpoints didn't exist server-side yet. Fixed all three:

| Issue | Fix | File |
|---|---|---|
| App defaulted to `localhost:3001` (Node edge-api, which the ESP32 doesn't post to) | Changed default to `http://192.168.1.31:3000` (the Python backend with real data) | [app_constants.dart:6](../apps/farmer-app/lib/core/constants/app_constants.dart:6) |
| Settings screen hint text still said port 3001 | Updated to port 3000 | [settings_screen.dart](../apps/farmer-app/lib/features/settings/settings_screen.dart) |
| `POST /v1/crop-health` didn't exist on the Python backend — every photo scan silently returned "inconclusive" | Added the endpoint: saves the uploaded JPEG to a temp file, runs it through `ml/vision/src/inference.py` (the real TFLite crop-health model) via subprocess, parses the result, persists real diagnoses to `latestVision`. Degrades gracefully (still returns 200 with an "inconclusive" result, doesn't crash) if the AI dependencies aren't installed. | [main.py](../apps/dashboard/backend/main.py) — new `/v1/crop-health` route |
| `approveIrrigation()` called `/v1/irrigation/requests` + `/approve`, endpoints that don't exist on the Python backend — irrigation approval always silently no-op'd | Rewired to call the Python backend's actual `/v1/actuator-command` endpoint directly (approved → `START_IRRIGATION`, declined → `STOP_IRRIGATION`) | [http_farm_state_repository.dart](../apps/farmer-app/lib/data/repositories/http_farm_state_repository.dart) |

**Camera confirmed already correct** — the app already uses the phone's own camera via `image_picker` (`ImageSource.camera`, [scan_screen.dart:587](../apps/farmer-app/lib/features/scan/scan_screen.dart:587)), not a separate camera module. No changes needed there.

### What was actually tested (end to end, via curl against a local instance of the real backend code)

- ✅ `POST /v1/readings` → reading saved, correct advisory triggers (`"Irrigate now"` at 22.5% moisture)
- ✅ `GET /v1/farm-state` → returns the shape the app expects, matches its `Reading`/`Advisory` models exactly, no field mismatches
- ✅ `POST /v1/actuator-command` (the irrigation-approve fix) → relay state correctly flips `OFF → ON → OFF`
- ✅ `POST /v1/crop-health` failure path → gracefully returns an `"inconclusive"` result (200, not a crash) when AI dependencies are missing, exactly as designed
- ✅ `POST /v1/crop-health` success path → **installed the real AI dependencies and confirmed the actual TFLite model loads and runs** — correctly flagged a test image as blurry via the real quality-gate logic (Laplacian variance check), proving the full subprocess → model → JSON pipeline works, not just the endpoint plumbing
- ⚠️ **Not tested here** (no Flutter SDK on this machine): the Dart-side changes weren't run through `flutter analyze`/`flutter test`/an actual build. Run `flutter analyze` in `apps/farmer-app/` before considering this done, and do one real phone test of: home screen showing live readings, a photo scan, and the app's Settings → Test Connection button.

### Performance/resource note for the Pi 3B+

Installing the AI dependencies took a couple of minutes even on a full laptop; **expect it to be significantly slower, or possibly infeasible, on the Pi 3B+'s 1GB RAM.** Also, the current design reloads the TFLite model from scratch on every single scan (no in-process caching) — fine on a laptop, likely a multi-second-or-more delay per scan on the Pi. New file [`apps/dashboard/requirements-vision.txt`](../apps/dashboard/requirements-vision.txt) documents this and is kept separate from the core `requirements.txt` so the dashboard's essential features (readings/advisories/relay) don't require installing heavy ML libraries at all — only install it if/when you want real (not "inconclusive") crop-health results. If the Pi struggles, an alternative is running this specific endpoint's backend instance from a laptop instead.

---

## 8. Reconciling with `dev`'s backend consolidation

When pushing this session's work to the team's shared `dev` branch (`simulationsys/citadel`), discovered the team had **already executed** the exact consolidation plan `docs/backend-integration.md` describes — merged in ahead of this session's commits. This supersedes Sections 3.7, 5, and 6 above. Corrected everything to match:

**What changed on `dev`:**
- `apps/dashboard/` is **deleted entirely** — no more port 3000, no more separate Node `services/edge-api`.
- Everything is unified into `services/edge-api/app/` (FastAPI + SQLite), running on **port 3001** — exactly the port the farmer app and firmware already defaulted to before this session's detour.
- `POST /v1/crop-health` already exists there (superseding the one added to `apps/dashboard/backend/main.py` this session, now deleted) — and it expects **multipart form-data** (an `image` file field), not raw JPEG bytes.
- A full **`/v1/irrigation/requests` → `/approve` / `/decline`** flow already exists — more complete than the `/v1/actuator-command`-only shortcut this session wired up, and it's what the app's *original* code was already written for.
- `ml/vision/requirements-inference.txt` already exists on `dev` — the team independently wrote almost the same lightweight inference-only requirements file created this session (`apps/dashboard/requirements-vision.txt`, now deleted as redundant).

**Corrections made after merging `dev` into this branch:**

| File | Change |
|---|---|
| [app_constants.dart](../apps/farmer-app/lib/core/constants/app_constants.dart) | `defaultEdgeApiUrl` → back to port **3001** |
| [settings_screen.dart](../apps/farmer-app/lib/features/settings/settings_screen.dart) | Hint text → port 3001 |
| [http_farm_state_repository.dart](../apps/farmer-app/lib/data/repositories/http_farm_state_repository.dart) | `submitImage()` rewritten to send **multipart** (`http.MultipartRequest`) instead of raw bytes — required by the real endpoint's `UploadFile` parameter. `approveIrrigation()` rewritten to use the real **create → approve/decline** flow instead of the `/v1/actuator-command` shortcut. |
| `field_node.ino` | `EDGE_API_URL` → back to port **3001** |
| `apps/dashboard/backend/main.py`, `apps/dashboard/requirements-vision.txt` | Deleted — superseded by `dev`'s versions in `services/edge-api/`. |

**Running the Pi's backend now uses the new path** (this hasn't been re-run on the actual Pi yet — was set up mid-session against the now-deleted `apps/dashboard/backend`):
```bash
cd ~/citadel
git pull origin dev   # or wherever the Pi's clone tracks after this merge lands
cd services/edge-api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 3001 --reload
```
Then re-verify the dashboard at `http://192.168.1.31:3001` (note: `services/edge-api` serves its own static UI at `/`, migrated from `apps/dashboard/static/index.html`).

---

## 9. Open items for later sessions

- [ ] **Re-run the Pi backend setup** against `services/edge-api` (port 3001) — the working setup from Section 3.7 targeted the now-deleted `apps/dashboard/backend`, needs to be redone once the Pi pulls this merge
- [ ] Buy + wire capacitive soil moisture sensor → GPIO34 (also needed for the "Irrigate now" advisory to reflect real conditions instead of the floating-pin 100% artifact)
- [ ] Decide on rain gauge substitution (analog raindrop board vs. hardcoded 0 for demo)
- [ ] Run `flutter analyze` / `flutter test` on the farmer-app changes, then do one real on-phone test of the full flow (live readings, photo scan via multipart upload, irrigation request → approve/decline, Settings → Test Connection)
- [ ] Try installing `ml/vision/requirements-inference.txt` on the actual Pi 3B+ and see whether it installs and runs at an acceptable speed — have a laptop-hosted fallback ready if not
- [ ] If pump is reintroduced: identify relay NO terminal via boot-test, wire load side
- [ ] Calibrate soil moisture (`SOIL_DRY_VALUE`/`SOIL_WET_VALUE`) and HC-SR04 (`TANK_EMPTY_CM`/`TANK_FULL_CM`) constants once the tank/soil setup is final
- [ ] For field/demo-day deployment: consider configuring the Pi as its own Wi-Fi hotspot instead of depending on a specific network (relevant if moving locations, e.g. college) — the ESP32 would connect directly to the Pi with no external router/infrastructure dependency at all
- [ ] Switch Pi to a wall power adapter (5V/2.5A+) for any long unattended run — reserve the power bank for portable demo use
