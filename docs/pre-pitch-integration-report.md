# Citadel Pre-Pitch Integration Report

**Baseline commit:** `3b7dc01` (branch `main`, working tree clean at start)
**Date:** 2026-09-10
**Executed on:** Windows development laptop, Python 3.10.11
**NOT executed on:** the Raspberry Pi, the ESP32, or any Flutter toolchain

> **Read this first.** The instructions for this work were written for a session
> running on the Pi (`~/citadel`). This session ran on the laptop. The Pi
> answered ping at `192.168.1.31` (~22 ms) but refused key-based SSH
> (`Permission denied (publickey,password)`), so it could not be driven from
> here.
>
> Everything below is therefore either **implemented and covered by tests that
> actually ran**, or **implemented and not yet executed anywhere**. Nothing here
> is "tested on the Pi" or "physically demonstrated". Those two columns are
> empty on purpose.

---

## 1. Executive verdict

### NOT READY

Not because the work is incomplete — the contract bugs that would have broken
the demo are fixed and covered by 40 new passing tests — but because **the three
things that decide whether the demo works have not been executed anywhere**:

1. Whether `tflite-runtime` installs and the model loads **on the Pi**.
2. Whether the Flutter app compiles and passes its new tests (no Dart SDK here).
3. Whether the rewritten firmware compiles, flashes, and drives the relay.

A verdict of READY WITH LIMITATIONS would require at minimum §9's commands to
have been run on the Pi. They have not. Budget two focused hours on the Pi and
this plausibly becomes READY WITH LIMITATIONS; it cannot become READY, because
the pest model does not exist and the soil sensor is not wired.

---

## 2. Changes implemented

### 2.1 Crop-health inference made Pi-native (Phase 2)

- **Problem.** `inference.py` imported full TensorFlow unconditionally and
  called `tf.lite.Interpreter`. On a Pi 3B+ with 1 GB RAM that import alone is
  hundreds of MB of RSS. `app/vision.py` also required an `ml/vision/.venv` that
  its own docstring admitted does not exist.
- **Root cause.** The training environment and the inference environment were
  never separated; the edge service assumed a second venv nobody creates.
- **Files.** `ml/vision/src/inference.py` (rewritten), `services/edge-api/app/vision.py`,
  new `ml/vision/requirements-pi.txt`.
- **Solution.** Runtime selection tries `tflite_runtime` first and **never
  imports TensorFlow when it succeeds**. The interpreter is loaded, allocated
  and validated **once per process** and cached. Input shape, output shape and
  class count are validated against the model's own `.json` sidecar — a
  mismatch refuses to guess rather than silently mislabelling. The CLI entry
  point is preserved (the subprocess boundary is still required: `ml/vision` and
  `citadel_pest_risk` both claim the top-level package name `src`). Interpreter
  resolution now falls back to `sys.executable`, so **one shared venv on the Pi
  is sufficient**.
- **Infrastructure vs inconclusive.** New exit code 3 → `VisionUnavailable` →
  **HTTP 503**. `inconclusive` now means exactly one thing: the model ran and
  confidence was below 0.50.
- **Tests.** 20 new, in `ml/vision/tests/test_runtime_inference.py`. **All pass.**

### 2.2 `/health` stopped probing the wrong artifact

- **Problem.** `vision.py` checked `crop_health_mobilenetv2.tflite` while
  `inference.py` loaded `..._v1.1.tflite`. Verified by checksum: the unversioned
  file is byte-identical to **v1.0** (`5f48efea…`), not v1.1 (`1da264e4…`).
- **Solution.** Both now resolve `v1.1`, overridable via `CITADEL_CROP_MODEL`.
  `/health` also reports which runtime would be selected, using
  `importlib.util.find_spec` so answering a health check never costs a
  TensorFlow import.

### 2.3 Flutter crop-scan integration (Phase 3)

- **Problem.** Every failure path returned a **fabricated** `CropHealthResult`
  with `label: 'inconclusive'`. A dead AI pipeline was indistinguishable from a
  working one that was merely unsure.
- **Files.** `crop_health_result.dart`, `http_farm_state_repository.dart`,
  `farm_state_repository.dart`, `scan_screen.dart`.
- **Solution.** New `CropScanException` with a typed `CropScanFailure`
  (`modelUnavailable` 503 · `badModelOutput` 502 · `timeout` 504 ·
  `networkUnavailable` · `malformedResponse` · `serverError`), each with
  farmer-facing copy that says the node is unavailable and never implies a
  diagnosis was attempted. The scan screen surfaces the error instead of
  dereferencing a null result.
- **Multipart confirmed correct** — the app already sent `MultipartFile` with
  field `image`, matching `UploadFile = File(...)`. My earlier audit's concern
  here was unfounded; the nested `result` unwrapping was also already correct.

### 2.4 Partial sensor payloads (Phase 4)

- **Problem.** `Reading.fromJson` force-cast `(json['soilMoisturePct'] as num)`.
  The documented flood demo payload omits it, so parsing threw, and
  `HybridFarmStateRepository` **silently substituted mock data**. The phone
  would have shown invented readings with no error.
- **Files.** `reading.dart`, `farm_state.dart`, `advisory.dart`,
  `hybrid_farm_state_repository.dart`, `mock_farm_state_repository.dart`,
  `home_screen.dart`, `main.dart`, `app_constants.dart`.
- **Solution.** Every sensor is `double?`. Missing renders as `--`, never 0 and
  never a stand-in. `capturedAt` stays null rather than being back-filled with
  `DateTime.now()` (which made stale data look current). `reading` is nullable
  for cold start. **The silent mock fallback is removed**: farm state falls back
  to cache marked `fromCache` (forced to `stale`), and crop scans and irrigation
  decisions do not fall back at all. Home-screen hardcoded fallbacks (`'64%'`,
  `'31°C'`, `'34°C'`) are gone.
- **Server freshness is now used.** The app previously dropped the `freshness`
  field and recomputed client-side.

### 2.5 Irrigation approval — two separate bugs (Phase 5)

- **Problem A (found in the audit).** The repository read
  `body['request']['id']` from the **flat** create response, got null, and
  returned early. Silent.
- **Problem B (found during this work, worse).** `advisory_detail_screen.dart`
  never called the repository at all. `_handleApprove()` was
  `setState(() => _isApproved = true)` plus a dialog reading *"Command sent to
  edge controller."* **The screen reported approval to the farmer without
  contacting the backend.** Decline only showed a snackbar.
- **Files.** New `irrigation_request.dart`; `http_farm_state_repository.dart`,
  `farm_state_repository.dart`, `advisory_detail_screen.dart`.
- **Solution.** `IrrigationRequest.fromAny` accepts both the flat create shape
  and the wrapped approve/decline shape, so the asymmetry cannot break this
  again. Every status is checked; 404/409/timeout/malformed all raise
  `IrrigationException`. **Approval is reported only when the backend returns
  `status: "approved"`** — a 200 that does not confirm is treated as failure.
  The provider exposes a real state machine (`recommended → creating → pending →
  approved/declined/failed`), repeat taps are disabled while in flight, and farm
  state refreshes afterwards. The success dialog no longer claims the pump
  started; it says a command is waiting for the node to collect.
- **Backend response shapes were left unchanged** and documented instead, per
  the instruction not to reshape a backend to match one incorrect client
  assumption.

### 2.6 ESP32 downlink loop closed (Phase 6)

- **Problem.** The firmware checked `httpCode` and discarded the body. No
  `eventId`, no `relayReported`, no local dead-man timer, no
  `digitalWrite(RELAY_PIN, HIGH)` anywhere — the relay could not turn on at all.
  DHT failure was substituted with 25 °C / 50 %, and the unwired soil pin
  reported a floating ~100 % that **suppresses** the irrigation advisory.
- **Files.** `firmware/esp32-field-node/field_node/field_node.ino` (rewritten),
  `config.example.h`, `.gitignore`.
- **Solution.**
  - **Stable event id** `deviceId-bootNonce-counter`. The boot nonce is
    `esp_random()`, without which the counter restarts at 1 after every reset
    and collides with stored ids — post-reboot readings would be silently
    swallowed as duplicates.
  - **Response parsing** with ArduinoJson. Validates that `command` exists, the
    actuator id matches, `relayState` is exactly ON/OFF, and `maxRuntimeSec` is
    within 60–3600. Anything else is ignored. **No path turns the relay ON from
    malformed input.**
  - **Local dead-man timer** runs first in `loop()` and inside the Wi-Fi retry
    wait — ungated by the network or the post interval. It fires if Wi-Fi drops,
    the Pi crashes, or no further response arrives.
  - **Idempotent re-application:** a repeated identical ON on a duplicate reading
    does not restart the lease, so a retry loop cannot extend runtime.
  - **Sensor integrity:** failed or unwired sensors are **omitted** from the
    payload. `SOIL_SENSOR_WIRED` and `RAIN_GAUGE_WIRED` are `false`.
  - **Relay polarity** is explicit (`RELAY_ACTIVE_HIGH`), and OFF is written
    before anything else in `setup()`.
  - **Credentials removed** from the tracked source into an untracked
    `field_node/config.h`.
- **Tests.** None. This is unflashed, uncompiled C++. See §10.

### 2.7 Backend safety invariants pinned (Phase 7)

No behaviour changed — the server-side model was already correct. 20 tests now
prevent it from being weakened. See §7.

### 2.8 Dependencies and CI (Phase 8)

- **`httpx2` is intentional, not a typo.** My earlier audit called it "probably
  a typo for httpx". It is a real package (Pydantic-maintained, Tom Christie),
  and current Starlette emits `StarletteDeprecationWarning: Using httpx with
  starlette.testclient is deprecated; install httpx2 instead`. **Left as-is.**
- Added `ml/vision/requirements-pi.txt` (`tflite-runtime` +
  `opencv-python-headless`, explicitly **not** TensorFlow).
- Added a `crop-health` CI job. It installs only numpy + headless OpenCV,
  because the tests drive the interpreter through a fake.
- CI already installed `pest-risk` editable before the edge-API tests; the
  documented local setup now says so too.

### 2.9 Startup and recovery (Phase 9)

`deploy/citadel-edge.service`, `deploy/edge.env.example`, `deploy/README.md`.
**Not installed, not enabled.** Non-root user, explicit `CITADEL_DB_PATH`
(a relative default under systemd is how you end up with two `farm.db` files),
`--host 0.0.0.0`, port 3001, `Restart=on-failure`, journald logging, modest
hardening, and rollback commands.

### 2.10 Documentation (Phase 12)

Rewrote `README.md` (claimed Expo/React Native — it is Flutter; referenced the
deleted `apps/dashboard`, a non-existent `infra/`, and `npm run dev:edge`) and
`services/edge-api/README.md` (documented a non-existent
`POST /v1/pest-detection`, raw-bytes crop upload, and an "in-memory store").
Rewrote `docs/demo.md` around port 3001 with honest caveats. Updated
`docs/system-architecture.md` and `docs/architecture-diagram-prompt.md`, both of
which I wrote before the consolidation landed and which still described the
port-3000 dual-backend.

`docs/CITADEL-SOLUTION-OVERVIEW.md` was listed in the instructions but **does
not exist** in the repository.

---

## 3. Component readiness

| Component | Status | Evidence | Remaining limitation | Required action |
|---|---|---|---|---|
| ESP32 sensors | **PARTIAL** | Firmware omits unwired sensors | Soil + rain not wired; DHT/HC-SR04 unverified since rewrite | Wire + calibrate soil, or demo synthetically |
| ESP32 HTTP upload | **NOT TESTED** | Code complete, targets `:3001` | Never compiled or flashed | Flash and watch serial |
| Event deduplication | **PARTIAL** | Server side proven by test; firmware id unflashed | **No persistent retry queue** — a failed POST is dropped | Accept, or add NVS buffering |
| Crop-health model | **PARTIAL** | 20 tests pass with a fake interpreter; v1.1 class order verified against sidecar | **Never loaded on real hardware.** `tflite-runtime` unproven on this Pi | §9 step 1 |
| Image-quality gate | **PASS** | 4 tests; rejects low-res/dark/non-leaf before inference | Green-ratio heuristic, not detection | None |
| Pest risk rules | **PASS** | 14 tests pass | Demo thresholds, not agronomy | None for the pitch |
| Pest model | **FAIL** | No `.tflite` anywhere; `/v1/pest/analyze` 503 | Feature does not exist | **Do not demo.** Say it is not built |
| Edge API | **PASS (tests)** | 36/36 pass | Never started on the Pi at this commit | §9 |
| SQLite | **PASS (tests)** | WAL, migration idempotency, dedup all covered | Path under systemd unverified | §9 step 6 |
| Flutter live readings | **NOT TESTED** | Code complete, 34 tests written | **No Dart SDK here.** Never compiled | `flutter analyze && flutter test` |
| Flutter cached readings | **NOT TESTED** | Cache marked `fromCache`, forced stale; tests written | Same | Same |
| Flutter crop scan | **NOT TESTED** | Typed failures, no fake results; tests written | Same | Same |
| Flutter irrigation approve | **NOT TESTED** | Two bugs fixed incl. a screen that never called the backend | Same | Same — **verify this one by hand** |
| Flutter irrigation decline | **NOT TESTED** | Now calls `/decline` | Same | Same |
| Relay downlink | **PARTIAL** | Server side proven (`test_full_downlink_and_acknowledgement_cycle`); firmware unflashed | Loop closed in source only | Flash and observe relay LED |
| Relay acknowledgement | **PARTIAL** | Server round-trip proven by test | Firmware side unflashed | Same |
| Dead-man timer | **PARTIAL** | Server expiry proven by test | **Firmware timer never executed** | Bench-test before any load |
| Dashboard | **NOT TESTED** | `static/index.html` served at `/` | Not loaded at this commit | §9 |
| Cloud synchronization | **PARTIAL** | 2 cloud tests pass; dormant unless `CITADEL_CLOUD_URL` set | **Never demonstrated end to end.** Rejected rows are stamped synced, so rejects are dropped not retried | Label untested |
| Offline operation | **PARTIAL** | No internet in any live path by construction | **Not demonstrated.** Network state never altered | §10 of the audit, with approval |
| Automatic startup | **PARTIAL** | Templates in `deploy/` | **Not installed** | `deploy/README.md` §3–4, with approval |

---

## 4. Contract matrix

| Producer | Consumer | Endpoint | Request | Response | Automated test | Real device |
|---|---|---|---|---|---|---|
| ESP32 | Edge API | `POST /v1/readings` | JSON, optional sensors, `eventId`, `relayReported` | 201/200 + `command` | ✅ edge-api ×4 | ❌ |
| Edge API | ESP32 | (response body) | — | `{actuatorId, relayState, maxRuntimeSec}` | ✅ full cycle test | ❌ |
| Flutter | Edge API | `GET /v1/farm-state` | query `zoneId` | reading (nullable) + `freshness` + advisories + actuator | ✅ Dart ×4 (unrun) + Python parity | ❌ |
| Flutter | Edge API | `POST /v1/crop-health` | **multipart**, field `image` | `{result, observation, state}` | ✅ Dart ×8 (unrun) + Python 422-guard | ❌ |
| Flutter | Edge API | `POST /v1/irrigation/requests` | JSON | **flat** request | ✅ Dart ×2 (unrun) + Python | ❌ |
| Flutter | Edge API | `.../{id}/approve` | JSON | **wrapped** `{request, actuator, command}` | ✅ Dart ×4 (unrun) + Python ×3 | ❌ |
| Flutter | Edge API | `.../{id}/decline` | JSON | wrapped `{request, note}` | ✅ Dart + Python | ❌ |
| Edge API | inference CLI | subprocess argv | image path | JSON, exit 0/3 | ✅ vision ×2 | ❌ |
| Edge API | `citadel_pest_risk` | in-process | `format_reading()` dict | advisory dicts | ✅ pest-risk ×14 | ❌ |
| Edge API | Cloud API | `POST /v1/sync/batch` | batched rows | `{accepted, rejected}` | ✅ cloud ×2 | ❌ |
| Dashboard | Edge API | `GET /v1/farm-state` | — | `relayState`, `latestVision` (deprecated fields) | ✅ contract test | ❌ |

**Resolved mismatches:** flat-vs-wrapped irrigation id · `disease` vs
`disease_risk` (backend emits `disease_risk`; app constant and
`advisory_card.dart` corrected) · non-null sensor casts · dropped `freshness` ·
health check probing v1.0 while inference used v1.1.

**Remaining, accepted:** the create/approve shape asymmetry is documented rather
than normalised, and the client tolerates both.

---

## 5. Test results

```
$ cd services/edge-api && python -m unittest discover -s tests
Ran 36 tests — OK          (16 pre-existing + 20 new)

$ cd services/cloud-api && python -m unittest discover -s tests
Ran 2 tests — OK

$ cd ml/pest-risk && python -m unittest discover -s tests
Ran 14 tests — OK

$ cd ml/vision && python -m unittest discover -s tests
Ran 20 tests — OK          (all new)
```

**Baseline before changes: 32 passing. Now: 72 passing, 0 failing, 0 skipped.**

Warnings (not failures): `StarletteDeprecationWarning` about `httpx2`, and an
`anyio.abc.BlockingPortal` deprecation from Starlette's test client. Neither is
ours.

One test failed while being written —
`test_desired_and_reported_state_stay_separate` asserted `reportedState is
None` when the posted reading contained `relayReported: "OFF"`. **The test was
wrong, not the code**; it now asserts the meaningful property (desired ON,
reported OFF, `inSync` false).

**Not run:**
- `flutter analyze`, `flutter test` — no Dart SDK on this machine. The 34 Dart
  tests in `apps/farmer-app/test/edge_contract_test.dart` are **written but
  never executed**. Treat them as unverified until they run.
- Anything on the Pi.
- Arduino compilation.

---

## 6. Raspberry Pi measurements

**NOT COLLECTED.** Model load time, cold and warm inference latency, memory,
architecture, free storage, and startup time all require the Pi. The audit's
laptop-side facts (Pi reachable at `192.168.1.31`, SSH key auth unavailable) are
the only network measurements taken.

Where the numbers will come from once you are on the Pi: `classify()` returns
`_model_load_ms` and `_latency_ms` in its result, and `/health` reports the
selected runtime.

---

## 7. Safety evidence

Proven by `services/edge-api/tests/test_safety_and_e2e.py` (20 tests, all
passing):

| Property | Test |
|---|---|
| An advisory cannot turn the actuator ON | `test_an_advisory_cannot_turn_the_actuator_on` — dry+hot produces the advisory, `desiredState` stays OFF, command `maxRuntimeSec` 0 |
| Creating a request cannot turn it ON | `test_creating_a_request_cannot_turn_the_actuator_on` |
| Declining keeps it OFF | `test_declining_keeps_desired_state_off` |
| Approval is the only normal ON path | `test_approval_is_the_only_normal_on_transition` |
| Override is separately auditable | `test_explicit_override_is_separately_auditable` |
| Runtime clamped 60–3600 s | `test_runtime_is_clamped_to_the_safe_range` (5→60, 99999→3600) |
| Expiry returns to OFF, audited | `test_runtime_expiry_returns_desired_state_to_off` |
| Desired ≠ reported, divergence visible | `test_desired_and_reported_state_stay_separate` |
| Full downlink + acknowledgement | `test_full_downlink_and_acknowledgement_cycle` |
| Replay: no duplicate, still gets command | `test_replayed_event_id_does_not_duplicate_but_still_carries_the_command` |
| Repeat decisions are 409, unknown is 404 | 2 tests |
| Invalid action rejected, state unchanged | `test_invalid_actuator_action_is_rejected` |
| Every change audited | `test_every_actuator_change_is_audited` |
| AI failure never looks like a diagnosis | `test_ai_infrastructure_failure_never_looks_like_a_diagnosis` |

**Default OFF:** firmware writes OFF before any other pin setup; server seeds
`actuator_state` as OFF.
**Two independent shutoffs:** server `reconcile()` and the firmware's own timer.
Neither is trusted alone.
**Hardware acknowledgement:** `relayReported` on the next reading; `inSync`
exposes divergence. Implemented, never exercised on hardware.

**No real pump was activated. No relay was energised. No hardware was touched
at all during this work** — no Pi access, no ESP32 access, no flashing.

---

## 8. Offline demonstration result

**Not performed.** Network state was not altered; that requires your approval
and physical presence.

What is true by construction: cloud sync does not start unless
`CITADEL_CLOUD_URL` is set, so the default configuration has no internet
dependency anywhere in the live path.

What cannot be claimed: that sync recovers after reconnection. The code is
implemented and has 2 passing unit tests against a mocked cloud, but the
edge→cloud path has never run end to end. Note also that `push_once` stamps
**rejected** rows as synced to unblock the queue — defensible for queue health,
but it means rejected data is dropped rather than retried. Do not describe this
as guaranteed delivery.

---

## 9. Pitch-day commands

Run in order on the Pi. Stop at the first failure.

```bash
# 0. Preconditions
ssh citadel@citadel-pi.local
cd ~/citadel && git pull
python3 --version        # must be 3.11+
uname -m                 # must be aarch64
free -h && df -h /
```

```bash
# 1. One shared virtualenv
cd ~/citadel/services/edge-api
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -e ../../ml/pest-risk
.venv/bin/pip install -r requirements.txt
.venv/bin/pip install -r ../../ml/vision/requirements-pi.txt
```

```bash
# 2. Prove the runtime and the model before trusting either
.venv/bin/python -c "from tflite_runtime.interpreter import Interpreter; print('ok')"
cd ~/citadel && services/edge-api/.venv/bin/python ml/vision/src/inference.py <leaf.jpg>
```

```bash
# 3. Tests
cd ~/citadel/services/edge-api && .venv/bin/python -m unittest discover -s tests -v
cd ~/citadel/ml/vision  && ../../services/edge-api/.venv/bin/python -m unittest discover -s tests -v
cd ~/citadel/ml/pest-risk && ../../services/edge-api/.venv/bin/python -m unittest discover -s tests -v
```

```bash
# 4. Start
cd ~/citadel
services/edge-api/.venv/bin/python -m uvicorn app.main:app \
    --app-dir services/edge-api --host 0.0.0.0 --port 3001
```

```bash
# 5. Health — check modelStatus.cropHealth.available and .runtime
curl -s http://$(hostname -I | awk '{print $1}'):3001/health | python3 -m json.tool
```

```bash
# 6. Dashboard + farm state
xdg-open http://$(hostname -I | awk '{print $1}'):3001/
curl -s "http://$(hostname -I | awk '{print $1}'):3001/v1/farm-state?zoneId=zone-a" | python3 -m json.tool
```

```bash
# 7. Safe synthetic reading (dry soil -> irrigation advisory)
curl -X POST http://$(hostname -I | awk '{print $1}'):3001/v1/readings \
  -H 'Content-Type: application/json' \
  -d '{"eventId":"pitch-dry-1","soilMoisturePct":8,"temperatureC":38,"humidityPct":35}'
```

```bash
# 8. Crop scan from the CLI (same path the API uses)
curl -X POST -F "image=@leaf.jpg" \
  "http://$(hostname -I | awk '{print $1}'):3001/v1/crop-health?zoneId=zone-a"
```

```bash
# 9. Logs / stop
journalctl -u citadel-edge -f     # if installed as a service
# otherwise Ctrl-C. SQLite is WAL; no special teardown.
```

Phone and ESP32 both use `http://<PI_LAN_IP>:3001`. **Never `localhost`.**

---

## 10. Remaining limitations

1. **Nothing has run on the Pi.** The single highest-risk item —
   `tflite-runtime` on this specific Pi — is unproven.
2. **No Flutter code was compiled.** 34 new Dart tests have never executed.
   There may be compile errors; the changes were extensive.
3. **The firmware has never been compiled or flashed.** It now depends on
   ArduinoJson v7, which must be installed via Library Manager. `esp_random()`
   and `__has_include` are ESP32-Arduino features but unverified in this build.
4. **The relay has never been energised.** The dead-man timer is untested code.
   Bench-test it against the relay's own LED before any load.
5. **No persistent retry queue on the ESP32.** A failed POST is dropped. Stated
   in the firmware header; do not claim durable offline buffering.
6. **The pest model does not exist.** `/v1/pest/analyze` always 503s.
7. **Soil moisture and rainfall are not wired.** The firmware now omits them
   rather than fabricating, which is correct but means the irrigation advisory
   cannot fire from real hardware — demo it synthetically.
8. **Cloud sync is untested end to end** and drops rejected rows.
9. **No autostart is installed.**
10. **Wi-Fi credentials remain in git history** for earlier commits. Removing
    them from the working tree does not remove them from history; rotate that
    Wi-Fi password or rewrite history deliberately.
11. `docs/CITADEL-SOLUTION-OVERVIEW.md` does not exist and was not created.
12. A `.venv-audit/` directory was created at the repo root for this work and
    added to `.gitignore`. Delete it when convenient.

---

## 11. Go / no-go checklist

**Blocking — the demo does not work without these:**

- [ ] Pi: `python3 --version` ≥ 3.11, `uname -m` = aarch64
- [ ] Pi: venv builds; `pip install -e ../../ml/pest-risk` succeeds
- [ ] Pi: `tflite-runtime` imports
- [ ] Pi: `inference.py <leaf.jpg>` prints JSON and exits 0
- [ ] Pi: 36/36 edge-api tests pass
- [ ] Pi: API starts; `/health` shows `cropHealth.available: true`
- [ ] Pi: dashboard loads over the **LAN IP** from another device
- [ ] Laptop: `flutter analyze` clean, `flutter test` green
- [ ] Phone: connects, shows live readings, `--` where sensors are absent
- [ ] Phone: **approve irrigation and confirm the backend recorded it**
      (`sqlite3 farm.db "select * from irrigation_requests"`)

**Blocking if you demo the relay:**

- [ ] Firmware compiles with ArduinoJson v7 installed
- [ ] Serial shows "Edge API accepted reading" and a parsed command
- [ ] Relay LED follows approve → ON, decline → stays OFF
- [ ] Dead-man verified: approve with `maxRuntimeSec: 60`, unplug the Pi,
      confirm the relay turns itself off
- [ ] Reboot mid-ON returns to OFF
- [ ] **No pump connected**

**Non-blocking — decide what you say:**

- [ ] Pest detection described as not built
- [ ] Soil/rain described as not wired, advisory demoed synthetically
- [ ] Cloud sync described as implemented but untested
- [ ] Autostart installed, or a documented manual start

---

## Final accounting

**Files changed (25 modified, 7 added):**

*Modified* — `.github/workflows/backend-ci.yml`, `.gitignore`, `README.md`,
`docs/architecture-diagram-prompt.md`, `docs/demo.md`,
`docs/system-architecture.md`, `firmware/.../config.example.h`,
`firmware/.../field_node.ino`, `ml/vision/src/inference.py`,
`services/edge-api/README.md`, `services/edge-api/app/vision.py`, and 14 files
under `apps/farmer-app/lib/`.

*Added* — `apps/farmer-app/lib/data/models/irrigation_request.dart`,
`apps/farmer-app/test/edge_contract_test.dart`, `deploy/` (3 files),
`ml/vision/requirements-pi.txt`, `ml/vision/tests/test_runtime_inference.py`,
`services/edge-api/tests/test_safety_and_e2e.py`.

**Nothing was committed or pushed.**

- **Tests passed:** 72 Python (36 edge-api, 20 vision, 14 pest-risk, 2 cloud-api)
- **Tests failed:** 0
- **Tests written but never executed:** 34 Dart
- **Physical ESP32 testing occurred:** **No.** No hardware was touched.
- **Real crop inference occurred on the Pi:** **No.** All inference tests use a
  fake interpreter. No `.tflite` was loaded anywhere.
- **Offline operation demonstrated:** **No.** Network state was not altered.
- **Safe for a relay-only pitch demonstration:** **Not yet.** The software
  safety model is sound and well covered, but the firmware enforcing half of it
  has never been compiled, let alone run. It becomes safe once the four firmware
  checks in §11 pass on the bench with no pump connected.
