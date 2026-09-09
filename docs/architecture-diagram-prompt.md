# Architecture diagram prompt (paste into Eraser / Excalidraw AI / Napkin / Claude / ChatGPT)

Copy everything below the line.

---

Create a clean, presentation-grade system architecture diagram for **Citadel**, an offline-first smart-farming platform. Left-to-right flow, five vertical swimlanes. Use a muted palette (greens for field/hardware, blue for services, amber for ML, grey for clients). Solid arrows = live data path; dashed arrows = fallback or not-yet-built. Label every arrow with its protocol and interval.

**Lane 1 — Field Hardware (green).** Sensors wired to an ESP32-WROOM-32 (38-pin DevKit):

- DHT11 temperature + humidity → GPIO4 (live)
- HC-SR04 ultrasonic water level → TRIG GPIO32 / ECHO GPIO33 via a 1 kΩ + 2 kΩ voltage divider (5 V → 3.3 V) (live)
- Relay module for the irrigation pump → GPIO26, held LOW on boot = pump OFF (control side live, pump load side NOT wired — draw dashed)
- Capacitive soil-moisture sensor → GPIO34 (NOT purchased — draw dashed/greyed)
- Tipping-bucket rain gauge → GPIO15 reserved (NOT available — draw dashed/greyed)
- Status LED → GPIO2

**Lane 2 — Transport.** Two arrows out of the ESP32, every 10 seconds:

- Solid: Wi-Fi → HTTP POST JSON → the edge API
- Dashed: USB Serial @115200 baud, labelled "always-on fallback, works with no network"

Show the JSON payload as a small note box: `deviceId, zoneId, soilMoisturePct, temperatureC, humidityPct, rainfallMm, waterLevelPct, sensorStatus{dht, ultrasonic}`.

**Lane 3 — Edge compute (blue), all on a Raspberry Pi 3B+ running Raspberry Pi OS Lite 64-bit at LAN 192.168.1.31.** Draw a box around the Pi containing:

- **Python Edge/Dashboard API — FastAPI, port 3000 (THE LIVE PATH, highlight it).** Endpoints: `POST /v1/readings`, `GET /v1/farm-state`, `GET /v1/history`, `POST /v1/crop-health`, `POST /v1/vision-results`, `POST /v1/actuator-command`, `GET /health`. Also serves the dashboard UI at `/`.
- **SQLite `farm.db`** attached to it, with tables `readings`, `vision_results`, `actuator_logs`, `actuator_state`.
- **Advisory engine** module inside the Python API.
- **Node Edge API — port 3001**, in-memory FarmStore, zone-aware, irrigation request/approve workflow. Mark it "parallel implementation, to be consolidated" — draw with a dashed border.
- **Pest & Risk Intelligence — FastAPI, port 8001.** Rules engine for water stress, heat stress, disease-inspection prompts, flood risk, pest activity, against crop profiles. Arrow from the Node API to it labelled "1.2 s timeout, falls back to local rules".

**Lane 4 — ML (amber).**

- **Crop-health model:** MobileNetV2 → TensorFlow Lite, 2.40 MB, 34.3 ms inference, 95.3 % accuracy on a frozen 749-image test set. Classes: healthy, early_blight, late_blight, leaf_spot, yellow_leaf_curl_virus (tomato only). Show a small decision node: image quality gate → confidence policy (≥ 0.80 normal · 0.50–0.79 with caveat · < 0.50 → "inconclusive"). Invoked as a subprocess by the Python API.
- **Pest detector (TFLite):** dashed/greyed, labelled "returns 503 model_not_ready until a real model is supplied".

**Lane 5 — Clients (grey).**

- **Flutter farmer app (Android + iOS).** Show its three-tier fallback chain as a stack: live HTTP → SharedPreferences cache → mock data, labelled "UI never goes blank". Polls `/v1/farm-state` every 30 s. Freshness banner: fresh < 2 min, stale < 15 min, critical beyond. Camera → JPEG bytes → `POST /v1/crop-health`.
- **Web dashboard**, static HTML/JS served from the Python API.

**Also draw, off to the side:**

- A dashed box for **Cloud API (port 3002) — placeholder, future multi-farm sync**, with a dashed arrow from the Pi labelled "delayed batch sync (not built)".
- A callout box titled **"Offline-first"** listing the degradation ladder: no cloud → fully functional · no Wi-Fi → Serial output + phone cache · pest service down → local fallback rules · vision model missing → inconclusive, not a crash · sensor NaN → safe defaults + error flag.
- A callout titled **"Human in the loop"**: advisories never actuate the pump directly; the farmer approves, the command is audited, and the relay defaults OFF on every boot.

Draw a boundary around lanes 1–4 labelled **"Local Wi-Fi LAN — no internet dependency"**.
