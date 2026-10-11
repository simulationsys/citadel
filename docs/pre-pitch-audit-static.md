# Citadel — Pre-Pitch Audit (Static / Contract Half)

**Scope:** commit `3b7dc01`, working tree clean, branch `main`.
**Run from:** Windows laptop, Python 3.10.11 — **not the Raspberry Pi.**
**Date:** 2026-09-10

> **Read this first.** Every verdict below is derived from source code, file
> checksums, and one test suite that runs without third-party dependencies.
> Nothing here validates the Pi's runtime. Sections requiring the Pi
> (§1, §3, §5, §6, §8-partial, §9, §15, §17) are marked **NOT TESTED** and must
> be run on the Pi before the pitch.

---

## A. Executive verdict

### NOT READY — 3 hard blockers, all fixable, none yet fixed

The backend is in good shape: the consolidation to `services/edge-api` on port
3001 has genuinely landed, the safety model around irrigation is well designed,
and the risk engine passes its tests. The problems are all at the **edges** —
the two places where software meets hardware and meets the phone.

The single most likely way this demo fails on stage: **the crop-health scan
returns 503 (or a fake "inconclusive") because `ml/vision/.venv` does not exist
on the Pi**, and creating it requires installing full TensorFlow and OpenCV on a
Pi 3B+ with 1 GB of RAM.

---

## B. Environment

| Item | Value | Source |
|---|---|---|
| Branch / commit | `main` @ `3b7dc01` "merge: reconcile with dev's backend consolidation (services/edge-api on 3001)" | `git log` |
| Working tree | Clean | `git status --short` (empty) |
| Audit host | Windows, Python 3.10.11 | `sys.version` |
| Pi reachability | `192.168.1.31` and `citadel-pi.local` both respond, ~22 ms | `ping` |
| Pi SSH from this session | **Unavailable** — `Permission denied (publickey,password)` | `ssh -o BatchMode=yes` |
| Pi model / RAM / OS / Python | **NOT TESTED** | requires Pi |

---

## C. Component readiness

| Component | Verdict | Evidence | Blocker | Next action |
|---|---|---|---|---|
| ESP32 ingestion (uplink) | **PARTIAL** | Firmware posts to `http://192.168.1.31:3001/v1/readings`, `WIFI_ENABLED = true`, 10 s interval. Payload fields match `SensorReadingInput`. | No `eventId`; no `relayReported` | Add both to the JSON payload |
| SQLite storage | **PASS (code)** | WAL enabled, migrations in `migrate.py`, `event_id` UNIQUE drives dedup | — | Confirm `farm.db` writable on Pi |
| Environmental-risk engine | **PASS (tested)** | 9/10 tests pass locally, incl. flood-suppresses-irrigation, low-confidence-pest, healthy-is-not-disease | — | None |
| Crop-health model | **FAIL (as deployed)** | `vision.py` requires `ml/vision/.venv/bin/python`; its own docstring says "does not exist today" | venv absent + TF/OpenCV on 1 GB Pi | See Blocker 1 |
| Pest model | **FAIL (by design, honest)** | No `.tflite` anywhere; `/v1/pest/analyze` always 503 `model_not_ready` | No artifact exists | Do not demo. Say "not built yet" |
| Edge API | **NOT TESTED** | Code imports cleanly by inspection; 16 tests exist | — | Run §8/§9 on Pi |
| Dashboard | **PARTIAL** | `static/index.html` present, served same-origin at `/` | — | Load it on the Pi |
| Flutter compatibility | **FAIL** | 3 contract mismatches, §E | Irrigation approve is dead | See Blockers 2 and 4 |
| Irrigation approval (server) | **PASS (code)** | Approval is the only ON path; declines audited; runtime bounded 60–3600 s; auto-OFF in `reconcile()` | — | Verify at runtime |
| Relay downlink | **FAIL** | Firmware never reads the response body — greps for `getString`/`deserializeJson` return nothing | Loop is open | See Blocker 3 |
| Hardware acknowledgement | **FAIL** | No `relayReported` sent; `in_sync()` treats NULL as in-sync so nothing looks wrong | Silent | Add the echo field |
| Cloud synchronization | **PARTIAL** | `sync.py` is real, push-only, idempotent, dormant unless `CITADEL_CLOUD_URL` set | Almost certainly unset | Leave dormant for the pitch |
| Offline operation | **PASS (design)** | No internet in the live path at all | — | See §G |
| Reboot recovery | **FAIL** | No systemd unit, no compose file, no `infra/` directory anywhere in the repo | Manual start only | See §H |

---

## D. Test results

Ran `python -m unittest discover -s tests -v` in `ml/pest-risk`:

```
Ran 10 tests in 0.120s — FAILED (errors=1)
```

**9 passed**, covering the §7 behaviours you asked about:

- `test_flood_suppresses_irrigation_advice` ✅ — flood does override irrigation
- `test_dry_heat_and_pest_create_explainable_advisories` ✅ — evidence attached
- `test_low_confidence_pest_is_not_an_alert` ✅ — confidence threshold holds
- `test_confident_healthy_leaf_is_not_a_disease` ✅
- `test_rejects_low_resolution_before_inference` ✅ — quality gate runs pre-inference
- `test_rejects_overexposed_image_before_inference` ✅
- `test_rejects_empty_and_corrupt_images` ✅
- `test_reading_rejects_invalid_percentages` ✅
- `test_pest_rejects_invalid_confidence` ✅

**1 error**, environmental not logical: `test_api` → `ModuleNotFoundError: No module named 'fastapi'`. This laptop has no venv; says nothing about the Pi.

Also encountered: `pip install -e .` **refused** —
`Package 'citadel-pest-risk' requires a different Python: 3.10.11 not in '>=3.11'`.
Harmless here, **critical on the Pi**: see Blocker 5.

`services/edge-api/tests/test_edge_api.py` has 16 tests that map almost exactly onto your §10–§12 (`test_event_id_replay_is_a_no_op`, `test_readings_response_carries_the_relay_downlink`, `test_desired_state_auto_offs_after_the_runtime_budget`, `test_decline_records_the_farmers_no`, `test_crop_health_is_503_when_vision_is_absent`). **Not run** — needs fastapi/httpx. Run these on the Pi first; they are the cheapest possible confidence.

---

## E. Contract mismatches

### E1 — Flutter irrigation approval never fires *(demo-breaking, silent)*

`http_farm_state_repository.dart:139`:

```dart
final id = (jsonDecode(created.body) as Map)['request']?['id'] as String?;
if (id == null) return;
```

But `POST /v1/irrigation/requests` has `response_model=IrrigationRequestResponse` and returns the request **flat**:

```json
{"id": "irrigation-...", "zoneId": "zone-a", "status": "pending", ...}
```

There is no `request` wrapper. So `id` is always `null`, the method **returns early**, and the approve/decline call is never made. Both the create failure and any exception are swallowed by the surrounding `try/catch`, so **the app shows no error** — the farmer taps Approve, the UI proceeds, and the pump command is never issued.

Confusingly, the *approve* endpoint **does** wrap (`{"request": ..., "actuator": ..., "command": ...}`). The two endpoints disagree with each other. Fix either the app (drop `['request']`) or the API (wrap the create response) — the app-side fix is one line and lower risk.

### E2 — Partial readings crash app parsing

`reading.dart:26-28` uses non-null casts:

```dart
soilMoisturePct: (json['soilMoisturePct'] as num).toDouble(),
temperatureC:    (json['temperatureC'] as num).toDouble(),
humidityPct:     (json['humidityPct'] as num).toDouble(),
```

The backend deliberately makes **every** sensor optional (`schemas.py:20-27`, with the comment "an ESP32 with no thermometer must not 422"), and `docs/demo.md` tells you to POST `{"waterLevelPct":82,"rainfallMm":32}` for the flood demo. That payload makes `Reading.fromJson` throw → caught → falls back to cache → if no cache, `HybridFarmStateRepository` falls through to **mock data**.

So if you run the documented flood demo, the phone will show **fabricated readings** and no error. Backend correct, app wrong, failure invisible.

### E3 — Server-provided freshness is ignored

The API computes `freshness` server-side (`main.py:_freshness`, live ≤120 s / stale ≤900 s) precisely so a stale payload can't look fresh. `_farmStateFromEdge` reads only `reading` and `advisories` — **`freshness` is dropped**, and the app recomputes from `capturedAt`. Worse, when `capturedAt` is missing the app substitutes `DateTime.now()`, actively making old data look current.

### E4 — Advisory type vocabulary drift *(cosmetic)*

Backend emits `disease_risk` (`risk_engine.py:9`, mirrored in `schemas.py`). The app has `typeDisease = 'disease'` (`app_constants.dart:20`) and `advisory_card.dart:94` switches on `case 'disease':`. Disease advisories will render with the **default** icon/colour rather than the disease styling. No crash.

### E5 — Health check probes the wrong model file

`vision.py:33` checks `crop_health_mobilenetv2.tflite`, but `inference.py:147` actually loads `crop_health_mobilenetv2_v1.1.tflite`. `/health.modelStatus` can therefore report the model present while inference uses a different artifact (or vice versa).

---

## F. Safety findings

**The server-side safety model is genuinely good.** Recording it plainly because it is the strongest part of the system and worth saying out loud in the pitch:

- Approval is the *only* path to ON besides an explicit audited override (`main.py:approve_irrigation_request`).
- `reconcile()` is called on every read and write path, so no caller can skip the auto-OFF.
- Runtime is bounded to 60–3600 s; `desired_command` returns `maxRuntimeSec: 0` when OFF, so the node can refuse an unbounded ON.
- Every state change writes to `actuator_logs`.
- Replays are 200 + the current command, never 409 — correct, because a retrying node lost the command.

**Against that, the device side has no safety of its own:**

| Requirement (§12/§14) | Status |
|---|---|
| Relay defaults OFF at boot | ✅ `digitalWrite(RELAY_PIN, LOW)` in `setup()` |
| Local dead-man switch on ESP32 | ❌ **Absent.** The only runtime limit is server-side |
| Response command parsed | ❌ Firmware checks `httpCode` only |
| Relay state acknowledged | ❌ No `relayReported` field sent |

Currently benign — the firmware contains no `digitalWrite(RELAY_PIN, HIGH)` anywhere, so the pump **cannot** turn on. That's safe, and it's also why the relay half of the demo cannot work end-to-end. Whoever adds the ON path must add the local timer in the same commit.

**Misleading-sensor risk (§14, last bullet):** DHT failure substitutes 25 °C / 50 % — benign, won't trigger a false heat alert. But the **unwired soil sensor floats and reports ~100 %**, which will *suppress* the irrigation advisory. Your headline demo ("Irrigate now") cannot fire from real hardware. Plan to demo it with a synthetic POST.

---

## G. Offline-demo readiness

Architecturally this is the strongest claim you have, and it holds up: there is **no internet in the live path at all**. Sensors → Pi → SQLite → advisories → dashboard/phone are all LAN-local.

Cloud sync status: **implemented, dormant.** `sync.py` only starts if `CITADEL_CLOUD_URL` is set (`main.py:lifespan`). Push-only, batched, marks rows synced only on 2xx.

One thing to be aware of before claiming it: on a cloud rejection, `push_once` stamps **rejected** rows as synced too ("malformed rows will never become well-formed") — defensible for queue health, but it means rejected data is silently dropped, not retried. Don't claim guaranteed delivery.

**I did not run the §16 network test.** The proposed safe version — keep LAN up, remove only the WAN route, exercise the full local flow, restore — is sound, but it needs your approval and it needs to happen on the Pi. Given sync is almost certainly dormant, the "restore internet and verify synchronization" step will demonstrate nothing unless you first stand up `services/cloud-api` and set `CITADEL_CLOUD_URL`.

---

## H. Commands for pitch day

**Unverified — these are derived from the code, not yet run on the Pi.**

```bash
ssh citadel@citadel-pi.local
cd ~/citadel && git pull

# 1. Edge API (required)
cd services/edge-api
python3 -m venv .venv && source .venv/bin/activate
pip install -e ../../ml/pest-risk
pip install -r requirements.txt
python3 -m uvicorn app.main:app --app-dir services/edge-api --host 0.0.0.0 --port 3001
```

Note the documented uvicorn command uses `--app-dir services/edge-api`, so run it from the **repo root**, not from inside `services/edge-api`.

Then verify, from the Pi:

```bash
curl -s localhost:3001/health | python3 -m json.tool
curl -s "localhost:3001/v1/farm-state?zoneId=zone-a" | python3 -m json.tool
```

Check `modelStatus.cropHealth.available` in that output — if it is `false`, the leaf-scan demo will 503.

**Expected startup:** seconds for the API. Crop-health cold start is a **separate Python process launched per request** with a 30 s timeout — on a Pi 3B+ importing TensorFlow, first scan could plausibly approach that. Warm it once before you present.

**Logs to watch:** uvicorn stdout. Sync logs under the `citadel.sync` logger (silent while dormant).

**Safe shutdown:** Ctrl-C. SQLite is in WAL mode; no special teardown.

---

## I. Top five blockers

**1. Crop-health inference will not run on the Pi as configured.**
`vision.py` requires `ml/vision/.venv/`, whose own docstring notes it "does not exist today". Populating it means `tensorflow>=2.16,<2.18` **plus** `opencv-python` (`ml/vision/requirements.txt`) on a Pi 3B+ with **1 GB RAM**. `inference.py:154` calls `tf.lite.Interpreter` — full TensorFlow, not `tflite-runtime`.
*Fix:* install `tflite-runtime` + `opencv-python-headless` and point `CITADEL_VISION_PYTHON` at that interpreter — but `inference.py` imports `tensorflow` unconditionally, so this **requires a source change** you have not approved. Decide tonight, not on stage.
*Fallback:* the scan degrades to a 503, and the app silently shows "inconclusive". Not a crash, but not a demo.

**2. Flutter irrigation approval is silently dead.** §E1. One-line app fix.

**3. The relay downlink loop is not closed in firmware.** No response parsing, no `eventId`, no `relayReported`, no local dead-man timer. The server speaks; the node never listens. Demo the approval on the **dashboard**, and describe the downlink as designed-not-yet-wired.

**4. Documented demo payloads crash the app's parser.** §E2 — and it fails *invisibly*, into mock data.

**5. Python version and a suspect dependency.**
`ml/pest-risk/pyproject.toml` requires `>=3.11`. Pi OS **Bookworm** ships 3.11 (fine); **Bullseye** ships 3.9 (**everything fails**). Check `python3 --version` first.
Separately, `ml/pest-risk/requirements.txt` pins **`httpx2>=2,<3`** — that looks like a typo for `httpx`. Verify it resolves on the Pi before you need it to.

---

## J. Go / no-go checklist

Run on the Pi, in order. Stop at the first failure.

- [ ] `python3 --version` ≥ 3.11
- [ ] `free -h` — RAM headroom, and confirm swap exists
- [ ] `df -h` — disk space (TensorFlow is large)
- [ ] `ss -tlnp | grep 3001` — port free
- [ ] `pip install -e ../../ml/pest-risk` succeeds
- [ ] `pip install -r requirements.txt` succeeds (watch `httpx2`)
- [ ] `python -m unittest discover -s tests -v` in `services/edge-api` — 16/16
- [ ] API starts, `/health` returns 200
- [ ] `modelStatus.cropHealth.available == true` ← **the pitch hinges on this**
- [ ] Dashboard loads at `http://192.168.1.31:3001/`
- [ ] ESP32 Serial shows "Edge API accepted reading"
- [ ] Reading appears in `/v1/farm-state`
- [ ] Phone (same Wi-Fi) → Settings → base URL `http://192.168.1.31:3001` → Test Connection
- [ ] One real leaf scan end-to-end, timed
- [ ] Decide: demo irrigation on dashboard (works) or app (broken until §E1 fixed)

**Use `http://192.168.1.31:3001` for both the phone and the ESP32. Never `localhost`** — on a phone that resolves to the phone.
