# Wokwi circuit diagram — Citadel field node

A ready-to-use Wokwi diagram matching your actual wired build (DHT11, HC-SR04 + resistor divider, relay control side). Renders as a detailed 2D schematic — Wokwi doesn't offer a true 3D/orbit view.

## How to use it

1. Go to [wokwi.com/projects/new/esp32](https://wokwi.com/projects/new/esp32) in your own browser (sign-in not required to view/build, only to save).
2. Click the **diagram.json** tab.
3. Select all (Ctrl+A) and delete.
4. Paste in the contents of [`diagram.json`](diagram.json) from this folder.
5. Click the green **Play** button — the board and parts should render and wire up automatically.

## What's included vs. left out

| Wired in real life | Shown here | Note |
|---|---|---|
| ESP32-WROOM-32 (38-pin DevKit) | ✅ `board-esp32-devkit-c-v4` | Direct jumper wiring shown here too (no breadboard) — matches your real build, since your ESP32 is too wide for a standard breadboard's spare rows. |
| DHT11 (blue breakout) | ✅ shown as `wokwi-dht22` | Wokwi's part library doesn't have a separate DHT11 element — DHT22's part is the same visual package/pin layout (VCC/SDA/GND), used here as a stand-in. Functionally your real DHT11 wiring is identical. |
| HC-SR04 + 1kΩ×3 voltage divider | ✅ `wokwi-hc-sr04` + 3× `wokwi-resistor` | Same 1kΩ + (1kΩ+1kΩ series) divider ratio as your real build. |
| Relay module (control side only) | ✅ `wokwi-relay-module` | Load side (pump/NO-COM) isn't wired here either, matching your real build — you decided to skip pump wiring for now. |
| Soil moisture sensor | ❌ not included | Not purchased yet as of the last build session — add a `wokwi-analog-joystick`-style analog part or similar once you have the real one and want to simulate it. |
| Rain gauge | ❌ not included | Not available; see the substitution notes in [`../field-node-wiring-diagram.html`](../field-node-wiring-diagram.html). |

## Pin mapping (matches the real build exactly)

| Signal | ESP32 pin | Component |
|---|---|---|
| DHT11 VCC | 3V3 | dht1 |
| DHT11 GND | GND | dht1 |
| DHT11 DATA | D4 | dht1 |
| HC-SR04 VCC | VIN (5V) | hc1 |
| HC-SR04 GND | GND | hc1 |
| HC-SR04 TRIG | D32 | hc1 |
| HC-SR04 ECHO | D33 (via 1kΩ/2kΩ divider) | hc1 → r1/r2/r3 |
| Relay VCC | VIN (5V) | relay1 |
| Relay GND | GND | relay1 |
| Relay IN | D26 | relay1 |

## A note on how this was built

This was authored directly as `diagram.json` (Wokwi's underlying circuit format) rather than clicked together part-by-part in the visual editor, and validated against Wokwi's own part search to confirm exact part IDs (`wokwi-relay-module` confirmed via live search) and pin names. The live ESP32/relay *simulation* itself couldn't be rendered in the automated browser session used to build this — that's a sandboxing limitation of that specific environment (WebAssembly-related), not a problem with the diagram — passive parts (sensors, resistors) did render correctly there, confirming the file structure is valid. It's expected to work normally in a regular browser.
