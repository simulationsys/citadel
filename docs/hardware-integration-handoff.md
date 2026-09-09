# Citadel Hardware Integration Handoff

This guide explains how to connect completed farm hardware to the existing Citadel software. It is an integration and verification checklist, not firmware source code.

## 1. Purpose

Citadel is an offline-first farm monitoring and advisory system. Field devices collect readings and images, while a Raspberry Pi receives the data, runs local AI and risk analysis, stores recent farm state, and serves the farmer app and dashboard. Internet access is optional for the core field loop.

The hardware team should treat the Raspberry Pi API as the boundary between electronics and application software. Sensor models and pin assignments may change without changing this boundary.

## 2. Existing architecture

The repository currently supports this flow:

```text
Environmental sensors -> ESP32 field node ----\
                                              \
Field camera -> ESP32-CAM ---------------------> Raspberry Pi
                                                    |
                                                    +-- Edge API, port 3001
                                                    +-- AI service, port 8001
                                                    +-- Crop-health TFLite model
                                                    +-- Pest detector adapter
                                                    +-- Environmental risk engine
                                                    |
                                              Farmer app and dashboard
```

Current software responsibilities:

| Component | Responsibility | Current state |
| --- | --- | --- |
| ESP32 field node | Read sensors, format readings, transmit them, and control the relay only after an approved command | Sensor and relay foundation exists; network integration must be finalized on the hardware |
| ESP32-CAM or field camera node | Capture JPEG images and upload them to the Pi | Hardware upload flow must be integrated |
| Edge API | Accept readings/images, retain farm state, call AI, create advisories, and serve clients | Available on port 3001 |
| AI service | Run crop-health, pest, and environmental-risk processing | Available on port 8001 |
| Crop-health engine | Validate image quality and classify tomato leaf health | Model and endpoint are available |
| Pest engine | Validate images and decode a TFLite detector result | Endpoint is available; deployment also requires the final pest model and matching labels |
| Farmer app/dashboard | Display readings, observations, warnings, history, and approval state | Designed to connect to the Pi over the local network |

## 3. Future target architecture

The production design keeps the same hardware-facing contracts while strengthening the Pi:

```text
Multiple field nodes and cameras
              |
              v
Raspberry Pi edge gateway
  - authenticated device ingestion
  - persistent SQLite event storage
  - queued and retried processing
  - crop and pest model management
  - one authoritative advisory engine
  - actuator command and acknowledgement log
              |
       local app/dashboard
              |
       optional cloud sync
```

Future improvements should not require reflashing devices unless a device contract changes. The Pi will eventually add device authentication, durable queues, model updates, fleet monitoring, and delayed cloud synchronization.

## 4. Hardware roles

### ESP32 field node

The field node is responsible only for measurement and hardware control. It should:

1. Read all installed sensors.
2. Apply calibration values locally.
3. Detect disconnected or invalid sensors.
4. Attach a stable device ID and zone ID.
5. Send readings to the Raspberry Pi at a controlled interval.
6. Retry temporary network failures without freezing sensor collection.
7. Keep the relay in its safe OFF state during startup or communication failure.
8. Execute only a valid, approved actuator command.
9. Report command acknowledgement and the resulting relay state.

The ESP32 should not run the main disease or pest models and should not decide agricultural treatment by itself.

### ESP32-CAM or camera node

The camera node should:

1. Capture JPEG images at a usable resolution.
2. Avoid direct glare, darkness, excessive distance, and motion blur.
3. Identify the source device and field zone.
4. Upload images to the Pi over the local network.
5. Use crop-health or pest-detection mode according to the camera placement.
6. Retry failed uploads with a delay and an upper retry limit.
7. Avoid capturing a new image while a previous upload is still active.

A wide field camera may be suitable for pest traps or canopy monitoring. Close-up crop-health classification requires the leaf to occupy a meaningful part of the image.

### Raspberry Pi

The Pi is the local brain. It should be powered continuously and connected to the same local network as the ESP32 devices and farmer phone. It receives hardware data, runs AI, stores results, and exposes the user-facing API.

## 5. Stable hardware-facing interfaces

Use the Raspberry Pi's LAN address, not `localhost`, in hardware configuration. Reserve its address in the router or configure a stable hostname so it does not change unexpectedly.

| Purpose | Method and path | Data expected |
| --- | --- | --- |
| Submit sensor readings | `POST /v1/readings` on port 3001 | JSON sensor reading |
| Submit a crop image | `POST /v1/crop-health?zoneId=<zone>` on port 3001 | Raw JPEG or PNG bytes |
| Submit a pest image | `POST /v1/pest-detection?zoneId=<zone>` on port 3001 | Raw JPEG or PNG bytes |
| Read current farm state | `GET /v1/farm-state?zoneId=<zone>` on port 3001 | No request body |
| Check Pi availability | `GET /health` on port 3001 | No request body |

Each sensor reading must contain these fields:

| Field | Meaning | Rule |
| --- | --- | --- |
| `deviceId` | Permanent identifier for the physical node | Must not change between restarts |
| `zoneId` | Field/greenhouse section | Use the same identifier across sensors, cameras, and app |
| `soilMoisturePct` | Calibrated soil moisture | Number from 0 to 100 |
| `temperatureC` | Ambient temperature | Number in degrees Celsius |
| `humidityPct` | Relative humidity | Number from 0 to 100 |
| `rainfallMm` | Accumulated rainfall for the defined sampling period | Zero or positive number |
| `waterLevelPct` | Tank/channel level | Number from 0 to 100 |

Do not replace a missing sensor with a believable-looking measurement. Report the sensor fault through the agreed status mechanism and keep the last known value distinguishable from a new reading.

## 6. Integration order after hardware assembly

### Stage 1: Electrical verification

1. Verify common ground and correct supply voltages.
2. Confirm no ESP32 input receives more than 3.3 V.
3. Confirm the relay starts OFF after reset and power loss.
4. Test each sensor independently through serial output.
5. Record raw readings at known reference conditions.
6. Calibrate percentages before sending them to Citadel.

Do not connect a mains-powered or high-current pump during initial software integration. Begin with the relay indicator or a safe low-voltage test load.

### Stage 2: Raspberry Pi preparation

1. Install and start the edge API and AI service.
2. Confirm port 3001 and port 8001 are listening locally.
3. Confirm the edge health response says the risk service is configured.
4. Confirm AI health reports crop health as ready.
5. Install and validate the final pest model and labels before expecting pest-camera results.
6. Assign the Pi a stable LAN address.
7. Configure both services to restart automatically after Pi reboot.

### Stage 3: Sensor-node connection

1. Configure the ESP32 with the Wi-Fi network and Pi address.
2. Keep serial logging enabled during the first connection.
3. Send one reading manually from the powered hardware.
4. Confirm the Pi accepts it.
5. Open farm state and confirm the same device, zone, and sensor values appear.
6. Test automatic periodic transmission.
7. Disconnect Wi-Fi temporarily and verify the node recovers without being reset.

### Stage 4: Camera connection

1. Start with one manually triggered capture.
2. Upload the original JPEG bytes without wrapping them in JSON.
3. Confirm crop images reach the crop-health endpoint.
4. Confirm pest-trap images reach the pest-detection endpoint.
5. Verify that dark, blurry, corrupt, oversized, or unsuitable images are rejected safely.
6. Confirm low-confidence results request another image rather than claiming a diagnosis.
7. Add scheduled capture only after manual capture is reliable.

### Stage 5: App and dashboard verification

1. Connect the phone to the same network as the Pi.
2. Set the app's edge URL to the Pi address on port 3001.
3. Confirm live sensor values match the hardware output.
4. Confirm camera results appear under the correct zone.
5. Confirm advisories cite the sensor or AI evidence that triggered them.
6. Turn off internet access and repeat the test to prove offline operation.

### Stage 6: Relay and pump flow

1. Generate an irrigation recommendation using controlled test readings.
2. Confirm that a recommendation alone does not switch the relay.
3. Approve the request from the app or dashboard.
4. Deliver the approved command to the correct ESP32 node.
5. Have the ESP32 report receipt, execution result, and relay state.
6. Test duplicate commands and confirm they do not cause repeated unsafe switching.
7. Test Pi, Wi-Fi, and ESP32 restarts; the safe default must remain OFF.

## 7. Camera operating guidance

- Prefer consistent lighting and a fixed camera angle.
- Keep the subject in focus and avoid motion during capture.
- Use close-up views for leaf disease classification.
- Use a stable trap/background for pest detection and counting.
- Keep images within the API's 5 MB limit.
- Do not repeatedly upload identical frames when nothing has changed.
- Store timestamps on the Pi, but keep the camera clock synchronized where possible.

## 8. Failure behaviour

| Failure | Required behaviour |
| --- | --- |
| Pi temporarily unreachable | Hardware continues sampling and retries later with backoff |
| Wi-Fi disconnected | Relay remains safe; node reconnects automatically |
| Invalid sensor reading | Do not transmit it as a valid measurement |
| Camera image rejected | Capture another image using the returned guidance |
| Crop model unavailable | Report model unavailable; do not invent a result |
| Pest model unavailable | Return `model_not_ready`; sensor and crop functions continue working |
| AI timeout | Keep the image/event eligible for retry and keep the rest of the edge API available |
| Cloud unavailable | Continue all local Pi, app, sensor, and advisory functions |
| Duplicate reading or command | Identify and ignore duplicates using event/command identifiers in the future contract |

## 9. Acceptance checklist

Hardware integration is complete only when all of the following are demonstrated:

- [ ] Every installed sensor is calibrated and reports plausible values.
- [ ] Missing or faulty sensors are distinguishable from valid zero values.
- [ ] The ESP32 reconnects after Wi-Fi and Pi restarts.
- [ ] Real readings appear in the Pi farm-state response under the correct zone.
- [ ] The camera uploads a valid image without manual file transfer.
- [ ] Crop-health inference runs on the Pi.
- [ ] The pest endpoint behaves safely, and the final pest artifact is validated if installed.
- [ ] Low-quality and low-confidence images do not create confident diagnoses.
- [ ] The app/dashboard display the same readings and observations stored by the Pi.
- [ ] The complete local flow works with internet access disabled.
- [ ] Irrigation requires explicit approval.
- [ ] Relay state is acknowledged by hardware and defaults to OFF after failure.
- [ ] No Wi-Fi password, API credential, or private key is committed to Git.

## 10. First full-system demonstration

Use this sequence for the first end-to-end demonstration:

1. Power the Raspberry Pi, ESP32 sensor node, camera node, and safe relay test load.
2. Show that the Pi services and AI readiness checks are healthy.
3. Let the ESP32 submit a real environmental reading.
4. Show the same values in the app or dashboard.
5. Trigger a field-camera capture.
6. Show the quality check, AI result, confidence, and resulting advisory.
7. Create a dry-soil scenario and show the irrigation recommendation.
8. Show that the relay remains unchanged until approval.
9. Approve the request and show the hardware acknowledgement.
10. Disconnect the internet and repeat a sensor/image cycle to demonstrate offline-first operation.

This proves the complete Citadel loop: physical observation, local intelligence, explainable advice, human approval, and safe hardware action.
