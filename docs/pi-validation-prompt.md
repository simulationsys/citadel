# Pi validation prompt

Copy this file to the Pi and paste its contents (everything below the line) into
Claude Code running there.

---

## Session preamble — read before section 1

Facts established on the development laptop on 2026-09-10. Verify them, do not
assume them.

**Provenance of the code you are about to audit.** The two reports named below
were produced from a Windows laptop, not from a Pi. The laptop session changed
33 files and added 7. If `git log` on this Pi shows `3b7dc01` as HEAD with a
clean tree, **that work is not present here** and both reports describe code you
do not have. Say so immediately and stop, rather than auditing the old tree.

**Environment requirements**

- Python **3.11+** is mandatory. `ml/pest-risk/pyproject.toml` declares
  `requires-python = ">=3.11"`; Raspberry Pi OS Bullseye ships 3.9 and the
  editable install will refuse. Check `python3 --version` first.
- `uname -m` must be `aarch64` for `tflite-runtime` wheels.
- Virtualenv install order matters: `pip install -e ../../ml/pest-risk` **before**
  `pip install -r requirements.txt`.
- The Pi inference stack is `ml/vision/requirements-pi.txt` (`tflite-runtime` +
  `opencv-python-headless`). Do **not** install `ml/vision/requirements.txt` —
  it pulls the full TensorFlow training stack, which a 1 GB Pi 3B+ cannot carry.

**Do not "fix" these — they are deliberate**

- `httpx2>=2,<3` in `ml/pest-risk/requirements.txt` is **intentional**, not a
  typo for `httpx`. Current Starlette emits
  `StarletteDeprecationWarning: Using httpx with starlette.testclient is
  deprecated; install httpx2 instead`. Changing it will break the test client.
- `POST /v1/irrigation/requests` returns the request **flat**;
  `/approve` and `/decline` return it **wrapped** as `{"request": ...}`. The
  asymmetry is documented and the Flutter client accepts both
  (`IrrigationRequest.fromAny`). Do not normalise one side alone — reading
  `body['request']['id']` from the flat create response is the exact bug that
  made approval fail silently.
- `services/edge-api/app/vision.py` shells out to a subprocess on purpose:
  `ml/vision` and `citadel_pest_risk` both claim the top-level package name
  `src`, so one interpreter cannot import both.

**Prerequisites to have ready before you start**

- A real tomato-leaf photo on the Pi. There is **no** test image in the
  repository (only `docs/field-node-wiring-diagram.png`). Section 4.10 needs one;
  ask for it rather than fabricating inference output.
- **ArduinoJson v7** for section 6. The firmware now depends on it and will not
  compile without it. Installing it is a package install — ask first.

**Known-untested at handover** — none of this has run anywhere:

- `tflite-runtime` on this Pi; the model has never been loaded on real hardware
- 34 Dart tests in `apps/farmer-app/test/edge_contract_test.dart`, written but
  never executed (no Dart SDK on the laptop). The Flutter changes were extensive;
  expect compile errors.
- The firmware has never been compiled or flashed. It uses `esp_random()` and
  `__has_include`.
- The relay has never been energised. The dead-man timer is untested code.

**Security note for section 10.** The Wi-Fi credential was removed from the
working tree but remains in earlier commits. The repository was made public at
one point (see `docs/field-node-progress-and-backend-setup.md` section 3.4), so
treat the credential as compromised and rotate first. Do not print it.

---

Act as Citadel's senior integration, safety, and release engineer.

Repository:
~/citadel

Primary report:
docs/pre-pitch-integration-report.md

Supporting report:
docs/pre-pitch-audit-static.md

Mission:
Independently investigate the entire Citadel system, fix every in-scope defect you find, and prove whether the complete offline-first demonstration works on the actual Raspberry Pi.

Do not trust the existing report blindly. Read it completely, reproduce its findings, inspect surrounding code, and search for additional integration, safety, security, and reliability problems.

Do not commit or push anything. Do not activate a real pump. Use a relay indicator, Wokwi, or an isolated low-voltage test load. Do not rewrite Git history, rotate credentials, install system services, change firewall rules, or expose the Pi publicly without explicit approval.

The required end-to-end flow is:

ESP32 sensors
→ local Wi-Fi
→ Raspberry Pi Edge API on port 3001
→ SQLite
→ environmental-risk intelligence
→ local crop-health TFLite inference
→ Flutter farmer app and web dashboard
→ farmer irrigation approval
→ relay command in the reading response
→ ESP32 execution and acknowledgement
→ local dead-man shutoff
→ optional cloud synchronization

## 1. Confirm the execution environment

Before changing anything, prove whether this session is running on a Raspberry Pi.

Report:

- Hostname
- Raspberry Pi model
- OS and release
- Kernel
- CPU architecture
- RAM and available memory
- Disk capacity and free space
- Python version
- Git branch and commit
- Working-tree status
- LAN IP addresses
- Existing virtual environments
- Whether port 3001 is occupied
- Whether an ESP32 is connected
- Whether Flutter/Dart and Android tooling are available

If this is not the Raspberry Pi, state that immediately. Continue with safe code analysis and host-independent tests, but do not claim Pi readiness.

Save the initial evidence in the final report.

## 2. Establish a clean baseline

Read:

- docs/pre-pitch-integration-report.md
- docs/pre-pitch-audit-static.md
- README.md
- docs/system-architecture.md
- docs/backend-integration.md
- docs/hardware-integration-handoff.md
- docs/demo.md
- services/edge-api/app/
- services/edge-api/tests/
- services/cloud-api/
- ml/vision/
- ml/pest-risk/
- apps/farmer-app/lib/
- apps/farmer-app/test/
- firmware/esp32-field-node/
- .github/workflows/backend-ci.yml
- package.json

Run all existing tests before modifications.

Record exact results for:

- Edge API tests
- Cloud API tests
- Pest-risk tests
- Crop-health tests
- Flutter analyze
- Flutter tests
- Firmware compilation, if toolchains are available

The previous laptop result was 72 Python tests passing. Reproduce this on the Pi rather than assuming it applies.

Do not delete or weaken tests to obtain a green result.

## 3. Explore beyond the existing reports

Perform a new independent audit.

Search specifically for:

- UI actions that change only local state without calling the backend
- Exceptions that are caught and silently ignored
- Fake/mock data entering production flows
- Infrastructure failures presented as successful AI results
- Request and response contract mismatches
- Incorrect endpoint names
- Incorrect JSON nesting
- Missing HTTP-status validation
- Nullable backend values force-cast as non-null in Flutter
- Stale data presented as live
- Commands reported as executed before hardware acknowledgement
- Default credentials or secrets
- Hard-coded LAN addresses
- Unsafe relay defaults
- Missing runtime bounds
- Blocking network operations that can prevent the dead-man timer
- Duplicate-event handling problems
- SQLite concurrency or persistence risks
- Cloud synchronization data loss
- Unbounded queues or storage
- Missing authentication or unsafe CORS exposure
- Outdated documentation
- Tests that mock away the actual cross-component contract

For every new finding, provide:

- Severity
- Evidence
- User or safety impact
- Root cause
- Proposed fix
- Verification method

Fix in-scope defects and add regression tests.

## 4. Validate crop-health inference on the real Pi

The most important readiness check is:

GET /health
→ modelStatus.cropHealth.available

Do not accept file existence as proof.

Verify:

1. `tflite-runtime` imports on the Pi.
2. Full TensorFlow is not imported when `tflite-runtime` succeeds.
3. The model loads:
   `ml/vision/models/crop_health_mobilenetv2_v1.1.tflite`
4. The sidecar metadata loads.
5. Class order matches the model:
   - healthy
   - early_blight
   - late_blight
   - leaf_spot
   - yellow_leaf_curl_virus
6. Input tensor shape and dtype are correct.
7. Output tensor count matches the class count.
8. Interpreter is cached.
9. Image-quality rejection works.
10. A real valid tomato-leaf image produces a genuine prediction.
11. A low-confidence prediction becomes `inconclusive`.
12. Missing runtime/model becomes an explicit 503.
13. Infrastructure failure never appears as `inconclusive`.
14. Temporary uploads are deleted.
15. Inference works without public internet.

Measure:

- Model-load time
- API startup time
- Cold inference latency
- Warm inference latency
- Memory before and after model load
- Peak memory if measurable
- CPU usage during inference

If no real test image exists, ask for one. Do not use fabricated inference output.

If dependencies are missing, propose the smallest Pi-compatible installation. Prefer an isolated virtual environment and `tflite-runtime`. Ask before installing packages.

## 5. Validate the full Flutter application

Do not stop at `flutter analyze`.

Run:

- `flutter pub get`
- `flutter analyze`
- all Flutter tests
- a debug build
- an actual physical-phone run if the phone is available

Inspect every action path to ensure it reaches the repository and backend.

Prove:

- The phone uses the Pi's LAN IP, not localhost.
- `/health` works from the phone.
- Farm state loads from the Pi.
- Complete readings render.
- Partial readings render with `--` for unavailable sensors.
- Null readings do not crash.
- Backend freshness is used.
- Cached information is clearly stale/offline.
- No failed live request silently switches to mock data.
- Crop upload is multipart with field name `image`.
- Nested crop result is parsed correctly.
- 503 is displayed as AI unavailable.
- Irrigation approval calls the backend.
- Irrigation decline calls the backend.
- UI success appears only after backend confirmation.
- Repeated taps are prevented.
- The UI distinguishes:
  - recommendation;
  - pending request;
  - approved request;
  - command returned;
  - hardware acknowledged;
  - failure.

Capture evidence using logs, screenshots, or recorded requests without exposing secrets.

Add tests for every defect discovered.

## 6. Compile and validate the firmware

The firmware must be compiled before the project can be considered ready.

Use the correct ESP32 board configuration and available Arduino/PlatformIO tooling.

Verify at compile time and by inspection:

- Required libraries are declared.
- Wi-Fi and HTTP code compile.
- JSON response parsing compiles.
- Buffer sizes are sufficient.
- Credentials are not printed.
- Stable event IDs survive retries of the same sample.
- A new sample receives a new event ID.
- `relayReported` is sent.
- Failed sensors are omitted or explicitly marked unavailable.
- No fake temperature, humidity, moisture, rainfall, or water values are sent.
- Relay polarity is explicit.
- Relay defaults OFF.
- Malformed commands cannot produce ON.
- Unknown actuator IDs are rejected.
- `maxRuntimeSec` is validated.
- The dead-man timer is independent of network success.
- Blocking HTTP calls cannot prevent timely shutoff.
- Replayed commands do not repeatedly energize the relay.
- Restart returns the relay to OFF.

If the ESP32 is available:

1. Flash the firmware.
2. Use the relay LED or safe low-voltage load.
3. Do not connect a real pump.
4. Record serial output.
5. Verify real sensor POSTs.
6. Verify command parsing.
7. Verify acknowledgement.
8. Disconnect the Pi or Wi-Fi while the relay is ON.
9. Confirm the local dead-man timer turns it OFF.
10. Restart the ESP32 and confirm OFF.

Ask for explicit approval immediately before any test that sends an ON command to connected hardware.

## 7. Prove the backend irrigation lifecycle

Use a temporary SQLite database or isolated test configuration.

Prove:

1. An advisory does not activate irrigation.
2. Creating a request leaves desired state OFF.
3. Declining leaves desired state OFF.
4. Approval changes desired state to ON.
5. The next ESP32 reading response contains the ON command.
6. The ESP32 reports ON in a later reading.
7. Desired and reported states become synchronized.
8. Runtime expiry changes desired state back to OFF.
9. The next response contains OFF.
10. The ESP32 applies OFF and acknowledges it.
11. Duplicate reading event IDs are stored once.
12. Duplicate submissions still receive the current command.
13. Every actuator transition is audited.
14. Invalid, repeated, expired, and unknown requests fail safely.

Preserve the server-side safety model. Do not weaken approval, reconciliation, audit, or runtime enforcement.

## 8. Investigate cloud synchronization

The current report says cloud synchronization is implemented but unproven and may stamp rejected rows as synchronized, effectively dropping them.

Independently inspect and test:

- Edge pending-record selection
- Batch formation
- Cloud validation
- Accepted-record handling
- Rejected-record handling
- Temporary network failure
- HTTP 4xx
- HTTP 5xx
- Timeout
- Invalid cloud response
- Partial acceptance
- Duplicate batch replay
- Edge restart during synchronization
- Cloud restart
- Ordering and idempotency
- Whether rejected records remain recoverable
- Whether malformed poison records block the queue
- Whether any failure silently loses data

Required behavior:

- Accepted records may be marked synchronized.
- Retryable failures must remain pending.
- Permanently invalid records must not disappear silently.
- If permanent rejection is quarantined, preserve the record and reason for inspection.
- Cloud unavailability must not affect local operation.
- Duplicate replay must not duplicate cloud records.

Implement a safe rejected-record policy and tests if needed.

Do not claim cloud recovery until an actual edge-to-cloud synchronization test passes.

## 9. Treat pest detection honestly

Verify whether a real pest `.tflite` artifact and matching labels exist.

If absent:

- Keep health status unavailable.
- Keep the endpoint returning `model_not_ready`.
- Ensure Flutter does not claim pest detection succeeded.
- Ensure environmental pest-risk rules can still be tested with injected fixtures.
- Document pest inference as unavailable.

Do not generate a fake model or substitute crop classification for pest detection.

## 10. Security investigation

The report says a Wi-Fi password exists in Git history.

Investigate without printing the credential.

Report:

- Which file and commit introduced it
- Whether it remains in the current tree
- Whether GitHub or forks contain it
- Whether other credentials are present
- Whether the credential must be considered compromised

Do not include the actual secret in terminal output or the report.

Required recommendation:

1. Rotate the Wi-Fi password first.
2. Update devices through a local untracked configuration.
3. Prevent future commits using ignored config files or build-time secrets.
4. Decide whether history rewriting is necessary.
5. Explain the effect on every collaborator and fork.

Do not rewrite history or force-push without explicit team approval.

Also inspect:

- CORS configuration
- LAN exposure
- Missing device authentication
- Unauthenticated actuator endpoints
- Default identities
- Hard-coded farm IDs
- Public exposure risk

Separate pitch-safe trusted-LAN limitations from production requirements.

## 11. Configure reliable Pi startup

Determine whether automatic startup exists.

If absent, prepare—but do not enable without approval—a systemd setup that:

- Runs as a non-root user
- Uses the project virtual environment
- Uses the correct working directory
- Binds to `0.0.0.0:3001`
- Restarts after failure
- Starts after networking
- Keeps secrets in an external environment file
- Preserves the SQLite database
- Writes useful logs to journald
- Shuts down cleanly

Provide commands for:

- Installation
- Enable
- Start
- Stop
- Restart
- Status
- Logs
- Disable
- Removal

Validate the unit with `systemd-analyze verify` if available.

## 12. Perform the real offline-first test

Ask for approval before altering connectivity.

The test must remove public internet while preserving local Wi-Fi.

With internet unavailable, prove:

- ESP32 continues posting readings.
- Pi stores readings.
- Farm state remains available.
- Environmental advisories continue.
- Real crop inference continues.
- Flutter continues receiving current local data.
- Dashboard continues working.
- Farmer can create and approve an irrigation request.
- Pi returns a relay command.
- ESP32 executes and acknowledges the command.
- Local runtime protection turns the relay OFF.

Then restore public internet.

If cloud synchronization is configured, prove queued records reach the cloud once without duplication.

Record exactly what was physically demonstrated. Do not generalize beyond the evidence.

## 13. Verify documentation and pitch claims

Update documentation to match reality.

Remove or correct references to:

- Deleted Node.js services
- Incorrect ports
- Old API shapes
- Fake fallback results
- Unavailable pest inference
- Unverified cloud recovery
- Uncompiled firmware
- Laptop-only validation
- Missing Pi startup

Create a concise pitch-readiness section stating what the team may and may not claim.

The stage claims must be evidence-based.

Allowed only after proof:

- Crop AI runs locally on the Raspberry Pi.
- The Flutter app receives live local farm data.
- Internet is not required for the immediate farm loop.
- Irrigation requires farmer approval.
- The ESP32 receives, executes, and acknowledges commands.
- A local dead-man timer stops irrigation after the runtime limit.

Not allowed without proof:

- Pest detection works.
- Cloud synchronization reliably recovers.
- A real pump has been validated.
- The system is production-ready.
- Yield or water savings are guaranteed.

## 14. Final verification

After changes, run all available checks again.

At minimum:

- Edge API tests
- Cloud API tests
- Pest-risk tests
- Crop-health tests
- Flutter tests
- Flutter analyze
- Flutter debug build
- Firmware compile
- OpenAPI generation
- End-to-end API contract tests
- Git diff checks
- Secret scan without exposing found values

No regressions are acceptable.

## 15. Required final report

Update or replace:

docs/pre-pitch-integration-report.md

Use this structure:

# Citadel Pre-Pitch Integration Report

## Executive verdict

Choose exactly one:

- READY
- READY WITH LIMITATIONS
- NOT READY

## Execution environment

Explicitly state whether testing occurred on:

- Laptop
- Raspberry Pi
- Physical Android phone
- Physical ESP32
- Wokwi
- Real relay
- Real pump

## Changes implemented

For each change:

- Problem
- Root cause
- Files changed
- Fix
- Tests
- Result

## New findings beyond the previous report

Include severity and evidence.

## Component readiness

Use PASS / PARTIAL / FAIL / NOT TESTED for:

- Physical sensors
- ESP32 Wi-Fi upload
- Stable event IDs
- SQLite persistence
- Environmental-risk engine
- Crop-health model on Pi
- Pest model
- Edge API
- Flutter live state
- Flutter cached state
- Flutter crop scan
- Flutter irrigation approval
- Flutter irrigation decline
- Dashboard
- Relay downlink
- Relay acknowledgement
- Local dead-man timer
- Cloud synchronization
- Offline operation
- Automatic startup
- Security posture

## Contract matrix

For every cross-component interface include:

- Producer
- Consumer
- Endpoint or message
- Request shape
- Response shape
- Automated-test result
- Physical-test result

## Test results

Include exact commands and summaries.

## Raspberry Pi measurements

Include:

- Startup time
- Model-load time
- Cold inference
- Warm inference
- RAM usage
- CPU architecture
- Disk usage

## Physical integration evidence

Describe exactly what the ESP32, phone, and relay did.

## Safety evidence

Include:

- Default OFF
- Human approval
- Runtime limits
- Desired versus reported state
- Acknowledgement
- Failure behavior
- Whether a real pump was connected

## Offline demonstration evidence

State exactly which functions continued without public internet.

## Security findings

Do not expose credentials.

## Remaining limitations

Be explicit.

## Pitch-day commands

Provide copy-paste commands for:

- Starting services
- Checking health
- Viewing logs
- Checking farm state
- Posting a safe synthetic reading
- Running a crop scan
- Verifying model readiness
- Stopping services safely

## Go/no-go checklist

Order checks by importance.

At the end, state:

- Files changed
- Tests passed, failed, and skipped
- Whether Pi inference was demonstrated
- Whether Flutter was built and run
- Whether firmware was compiled and flashed
- Whether the relay loop was demonstrated
- Whether offline operation was demonstrated
- Whether cloud recovery was demonstrated
- Whether pest inference is available
- Whether it is safe for a relay-only pitch demonstration

Do not commit or push. Stop and ask for approval before:

- Installing packages
- Flashing hardware
- Sending a live ON command
- Changing firewall settings
- Installing/enabling systemd
- Disconnecting internet
- Rotating credentials
- Rewriting Git history
