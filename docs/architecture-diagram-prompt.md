# Architecture diagram prompt (paste into Eraser / Excalidraw AI / Napkin / Claude / ChatGPT)

Copy everything below the line.

---

Create a clean, presentation-grade system architecture diagram for **Citadel**, an offline-first smart-farming platform. Left-to-right flow, five vertical swimlanes. Use a muted palette (greens for field/hardware, blue for services, amber for ML, grey for clients). Solid arrows = live data path; dashed arrows = fallback or not-yet-built. Label every arrow with its protocol and interval.

**Lane 1 — Field Hardware (green).** Sensors wired to an ESP32-WROOM-32 (38-pin DevKit):

- DHT11 temperature + humidity → GPIO4 (live)
- HC-SR04 ultrasonic water level → TRIG GPIO32 / ECHO GPIO33 via a 1 kΩ + 2 kΩ voltage divider (5 V → 3.3 V) (live)
- Relay module for the irrigation pump → GPIO26, OFF at boot, polarity configurable (control side live, pump load side NOT wired — draw dashed)
- Capacitive soil-moisture sensor → GPIO34 (NOT purchased — draw dashed/greyed)
- Tipping-bucket rain gauge → GPIO15 reserved (NOT available — draw dashed/greyed)
- Status LED → GPIO2

**Lane 2 — Transport.** Two arrows out of the ESP32, every 10 seconds:

- Solid: Wi-Fi → HTTP POST JSON → the edge API
- Dashed: USB Serial @115200 baud, labelled "always printed, works with no network"
- A RETURN arrow back up from the edge API to the ESP32, labelled "relay command rides the POST response" — this is the downlink, draw it prominently

Show the JSON payload as a small note box: `eventId, deviceId, zoneId, temperatureC, humidityPct, waterLevelPct, relayReported`. Note that unwired/failed sensors are OMITTED, not defaulted.

**Lane 3 — Edge compute (blue), all on a Raspberry Pi 3B+ running Raspberry Pi OS Lite 64-bit at LAN 192.168.1.31.** Draw a box around the Pi containing:

- **Edge API — FastAPI, port 3001 (the only backend, highlight it).** Endpoints: `POST /v1/readings`, `GET /v1/farm-state`, `GET /v1/history`, `POST /v1/crop-health` (multipart), `POST /v1/irrigation/requests` + approve/decline, `POST /v1/actuator-command`, `GET /health`. Also serves the dashboard UI at `/`.
- **SQLite `farm.db`** attached to it, with tables `readings`, `observations`, `irrigation_requests`, `actuator_state`, `actuator_logs`.
- **Advisory engine** module inside the Python API.
- **Pest & Risk rules (`citadel_pest_risk`), imported in-process; also a standalone FastAPI on port 8001.** Rules engine for water stress, heat stress, disease-inspection prompts, flood risk, pest activity, against crop profiles.

**Lane 4 — ML (amber).**

- **Crop-health model:** MobileNetV2 → TensorFlow Lite, 2.40 MB, 34.3 ms inference, 95.3 % accuracy on a frozen 749-image test set. Classes: healthy, early_blight, late_blight, leaf_spot, yellow_leaf_curl_virus (tomato only). Show a small decision node: image quality gate → confidence policy (≥ 0.80 normal · 0.50–0.79 with caveat · < 0.50 → "inconclusive"). Invoked as a subprocess by the Python API.
- **Pest detector (TFLite):** dashed/greyed, labelled "returns 503 model_not_ready until a real model is supplied".

**Lane 5 — Clients (grey).**

- **Flutter farmer app (Android + iOS).** Polls `/v1/farm-state` every 30 s and uses the server's `freshness` field. Offline: farm state falls back to a local cache **labelled stale**; crop scans and irrigation decisions do NOT fall back, they show an error. Camera → multipart `image` → `POST /v1/crop-health`. Show the irrigation state machine as a chain: recommended → creating → pending → approved/declined → command available → hardware acknowledged.
- **Web dashboard**, static HTML/JS served from the Python API.

**Also draw, off to the side:**

- A dashed box for **Cloud API (port 3002)**, with a dashed arrow from the Pi labelled "push-only batch sync, OFF unless CITADEL_CLOUD_URL is set".
- A callout box titled **"Offline-first"**: no cloud → fully functional · no Wi-Fi → Serial output, local dead-man still runs, phone cache marked stale · vision runtime missing → visible 503, never a fake "inconclusive" · sensor failed → field omitted, so no rule fires on it.
- A callout titled **"Two independent shutoffs"**: advisories never actuate the pump; only a human approval does. Runtime is clamped 60–3600 s, and BOTH the Pi and the ESP32 enforce it separately, so either alone will turn the relay off.

Draw a boundary around lanes 1–4 labelled **"Local Wi-Fi LAN — no internet dependency"**.
