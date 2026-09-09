# Demo script

Everything below runs on the local LAN. No internet is used at any point.

Substitute the Pi's own address for `<PI_LAN_IP>` (`hostname -I | awk '{print $1}'`).
The phone and the ESP32 must both use that address — never `localhost`, which on
each device resolves to that device.

## 0. Start the node

Real hardware mode is the default. Ensure `CITADEL_SEED_DEMO_DATA` is unset so
a fresh database shows "waiting for node" instead of synthetic readings.

```bash
cd ~/citadel
services/edge-api/.venv/bin/python -m uvicorn app.main:app \
    --app-dir services/edge-api --host 0.0.0.0 --port 3001
```

Confirm before presenting:

```bash
curl -s http://<PI_LAN_IP>:3001/health | python3 -m json.tool
```

Check `modelStatus.cropHealth.available`. If it is `false`, the leaf-scan demo
will return 503 — skip step 4 rather than discovering it live.

## 1. Live sensor data

Open `http://<PI_LAN_IP>:3001/` and show real readings arriving from the ESP32
every 10 s. Point out on the serial monitor that the node prints the same JSON
it posts, so it keeps working with no network at all.

Note honestly: soil moisture and rainfall are **absent** from the payload,
because those sensors are not wired. The firmware omits them rather than
sending a placeholder — a floating soil pin reads ~100% and would suppress the
very irrigation advisory this system exists to raise.

## 2. Dry-soil advisory

Because soil moisture is not wired, drive this synthetically:

```bash
curl -X POST http://<PI_LAN_IP>:3001/v1/readings \
  -H 'Content-Type: application/json' \
  -d '{"eventId":"demo-dry-1","soilMoisturePct":8,"temperatureC":38,"humidityPct":35}'
```

The dashboard shows irrigation and heat-stress advisories, each carrying the
evidence it was derived from.

## 3. Flood overrides irrigation

```bash
curl -X POST http://<PI_LAN_IP>:3001/v1/readings \
  -H 'Content-Type: application/json' \
  -d '{"eventId":"demo-flood-1","waterLevelPct":82,"rainfallMm":32}'
```

This payload deliberately carries **no** soil, temperature or humidity. Two
things to point out: the API accepts partial readings by design, and the flood
rule *suppresses* the irrigation advice rather than emitting both — the system
will not tell a farmer to irrigate a flooded field.

## 4. Crop-health scan

In the farmer app, photograph a tomato leaf. The image is posted as multipart
to `/v1/crop-health` and classified on the Pi by a 2.4 MB TFLite model.

Worth saying out loud: a photo that fails the quality gate is rejected with a
recapture prompt *before* inference, and confidence below 0.50 is reported as
`inconclusive` rather than a guess. If the model is unavailable the app says so
— it does not invent a diagnosis.

## 5. Irrigation approval

Trigger the dry-soil advisory (step 2), then approve it in the app or on the
dashboard.

The sequence to narrate:

1. The advisory alone changes nothing — the relay stays OFF.
2. Creating a request changes nothing either. It records intent.
3. **Approval** is the only thing that sets desired state to ON.
4. The command rides down on the node's *next* reading response.
5. The node applies it, then reports `relayReported: "ON"` on the reading after
   that — at which point desired and reported are in sync.
6. Both the Pi and the ESP32 independently enforce the runtime limit. Either
   one alone will turn the relay off.

**No pump is connected.** The relay module's own indicator LED shows the
switching. Do not wire a load for this demo.

## 6. Offline

Cloud sync is off by default (`CITADEL_CLOUD_URL` unset), so there is nothing to
disconnect — everything above already ran with no internet. If you want to
demonstrate it explicitly, drop the Pi's default route while leaving the LAN up,
and repeat steps 1–5.

Do not claim cloud recovery. The sync code is implemented and dormant; it has
not been demonstrated end to end.

## 7. Farmer analytics report

Open **Insights** in the Flutter app, choose 24 hours, 7 days, or 30 days, and
tap **Get to know my farm**. The report is calculated from the local SQLite
sensor readings, crop scans, risk events, and irrigation history.

It explains what every sensor means for the crop, shows averages, ranges,
trends and data completeness, summarizes crop-health scans, and prioritizes
next actions. It follows the farmer's selected English, Hindi, Haryanvi, or
Punjabi language. No internet, cloud database, API key, or generative-AI
service is used.

## 8. Online voice assistant

The assistant is the only demo feature that requires public internet. Copy
`services/edge-api/.env.example` to `services/edge-api/.env` and set:

```env
GEMINI_API_KEY=your_google_ai_studio_key
CITADEL_ASSISTANT_MODEL=gemini-2.5-flash
```

Restart the Edge API, then confirm `/health` returns
`onlineAssistant.configured: true`. Tap the microphone in the Flutter home
header, speak or type a farm question, and wait for Citadel to answer aloud.

The demo RAG layer retrieves only from Citadel's curated farming guidance and
the selected zone's latest seven-day local analytics. It refuses unsupported
diagnosis, pesticide dosage, and irrigation activation. If the key, internet,
speech recognition, or Gemini is unavailable, the assistant alone reports an
error; sensor ingestion, local analytics, crop scanning, dashboard access, and
irrigation continue independently.
