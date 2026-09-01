# Workstream 01 — Firmware and IoT field node

## Context

The field node is Citadel’s source of local truth. It must convert physical conditions into trustworthy readings and, where safe, receive an irrigation-control command. It should not rely on an always-on internet connection. An ESP32 is a sensible controller for sensor acquisition and relay control, while a Raspberry Pi or similar edge device can handle heavier vision workloads.

## Phase 1 MVP outcome

A powered field node reliably samples the selected sensors, identifies itself and its farm zone, and makes the readings available to the local system. The Phase 1 demonstration needs soil moisture, temperature/humidity, and one environmental-risk input such as rainfall or water level. It should visibly demonstrate status and preserve a safe pump/relay default.

The existing starting point is `firmware/esp32-field-node/field_node.ino`. It includes analog soil/water readings, serial JSON output, and a relay that starts OFF. It is intentionally a scaffold rather than a finished board-specific design.

## Scope

- Sensor selection, wiring, calibration, and sampling behaviour.
- Stable device readings: moisture, temperature, humidity, and the chosen risk sensor.
- Local data transport from ESP32 to the edge system. Serial is useful for initial bring-up; Wi-Fi, BLE, HTTP, or MQTT are possible paths once the hardware is stable.
- Relay/irrigation-control behaviour, including manual override and fail-safe states.
- Device identity, zone identity, status indication, and handling of sensor failure or disconnected transport.
- Power and enclosure considerations needed to make the demo believable in field conditions.

## Interfaces

The rest of Citadel only needs normalized readings and clearly identifiable device state. The current edge endpoint is `POST /v1/readings` in `services/edge-api`. A reading should use percentage values where possible and include a capture time when the device has time access.

Irrigation control must be treated as an explicit request rather than an implication of an advisory. The advisory engine may suggest an action; the exact approval route—manual button, app confirmation, or controlled automatic mode—remains a system decision.

## Practical MVP evidence

- Serial monitor or local API visibly changes as soil moisture/risk conditions change.
- A calibrated dry/wet demonstration produces meaningful relative moisture values.
- The relay is demonstrably OFF on boot and can be toggled only through the selected safe pathway.
- A temporary network loss does not stop local sensing.

## Design space still open

Sensor quality, filtering/calibration approach, transport protocol, reporting interval, power strategy, and whether a camera lives on this controller or alongside the edge computer should follow the available hardware and field constraints. Document assumptions and the observed limitations; they are useful engineering evidence, not failures.
