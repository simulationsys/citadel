// Citadel ESP32 field node.
//
// Closes the loop with the edge API: posts a reading, parses the relay command
// that rides the response, applies it, and acknowledges the actual relay state
// on the next reading.
//
// Three safety properties this file is responsible for, none of which the
// server can guarantee on its own:
//   1. The relay is OFF at boot and after any reset, always.
//   2. A malformed, unknown or unsafe command is ignored — never defaulted to ON.
//   3. A local dead-man timer turns the relay OFF when maxRuntimeSec expires,
//      even if Wi-Fi drops, the Pi crashes, or no further response ever arrives.
//
// Sensor integrity: a failed sensor is OMITTED from the payload, never
// substituted. The edge API accepts partial readings by design, and the risk
// engine skips rules whose inputs are missing. Sending 25 C for a dead DHT11
// would be a fabricated measurement that the advisory engine cannot tell apart
// from a real one.
//
// Requires: ArduinoJson (Library Manager, v7.x), DHT sensor library.

#include <ArduinoJson.h>
#include <DHT.h>
#include <HTTPClient.h>
#include <WiFi.h>

// Wi-Fi and endpoint live in an untracked config.h. Copy config.example.h to
// field_node/config.h. Credentials must never be committed.
#if __has_include("config.h")
#include "config.h"
#endif

#ifndef WIFI_SSID
#define WIFI_SSID "your-network"
#endif
#ifndef WIFI_PASSWORD
#define WIFI_PASSWORD "your-password"
#endif
#ifndef EDGE_API_URL
// Must be the Pi's LAN address. Never "localhost" — that resolves to the ESP32.
#define EDGE_API_URL "http://192.168.1.31:3001/v1/readings"
#endif
#ifndef DEVICE_ID
#define DEVICE_ID "field-node-01"
#endif
#ifndef ZONE_ID
#define ZONE_ID "zone-a"
#endif
#ifndef EXPECTED_ACTUATOR_ID
// Must match actuator_id_for(zone) in services/edge-api/app/db.py: zone-a keeps
// the historical id "pump-relay-01"; other zones are "pump-<zoneId>".
#define EXPECTED_ACTUATOR_ID "pump-relay-01"
#endif
#ifndef WIFI_ENABLED
#define WIFI_ENABLED true
#endif
#ifndef SOIL_SENSOR_WIRED
#define SOIL_SENSOR_WIRED false
#endif
#ifndef RELAY_ACTIVE_HIGH
#define RELAY_ACTIVE_HIGH true
#endif

// No rain-gauge reader exists until the team selects the actual sensor and
// calibrates its output. Keep this false so the app shows `--` instead of a
// fabricated 0 mm measurement.
const bool RAIN_GAUGE_WIRED = false;

// ── Pins ─────────────────────────────────────────────────────────────────
const int STATUS_LED_PIN    = 2;
const int SOIL_MOISTURE_PIN = 34;
const int WATER_LEVEL_TRIG  = 32;
const int WATER_LEVEL_ECHO  = 33;  // through the 1k/2k divider, never direct
const int DHT_PIN           = 4;
const int RELAY_PIN         = 26;

// ── Hardware present on this build ───────────────────────────────────────
// The soil sensor is not purchased and GPIO34 floats at a meaningless ~100%,
// which would *suppress* the irrigation advisory — a fabricated reading that
// actively hides the condition it is meant to detect. Flip to true only after
// wiring AND calibrating SOIL_DRY_VALUE / SOIL_WET_VALUE against real soil.
// Relay polarity. Most blue relay boards are active-LOW: the coil energises
// when the pin is pulled LOW. Get this wrong and "off" energises the pump.
// Verify with the board's own LED before wiring any load.

// ── Calibration ──────────────────────────────────────────────────────────
const int   SOIL_DRY_VALUE = 3200;
const int   SOIL_WET_VALUE = 1400;
const float TANK_EMPTY_CM  = 100.0;
const float TANK_FULL_CM   = 10.0;

const unsigned long READ_INTERVAL_MS = 10000;
// Bounds mirror set_desired_state() in services/edge-api/app/db.py (60-3600).
const long MIN_RUNTIME_SEC = 60;
const long MAX_RUNTIME_SEC = 3600;

#define DHT_TYPE DHT11
DHT dht(DHT_PIN, DHT_TYPE);

// ── State ────────────────────────────────────────────────────────────────
unsigned long lastReadTime   = 0;
uint32_t      sampleCounter  = 0;
// Random per boot. Without it the counter restarts at 1 after every reset and
// collides with ids the server already stored, so the first readings after a
// reboot would be silently swallowed as duplicates and never persisted.
uint32_t      bootNonce      = 0;
char          currentEventId[64] = {0};

bool          relayOn        = false;   // our own view of the physical relay
unsigned long relayOnSinceMs = 0;
unsigned long relayBudgetMs  = 0;       // 0 = no active lease
char          lastAppliedCommand[24] = {0};  // suppresses redundant re-triggers

// ── Relay ────────────────────────────────────────────────────────────────
void writeRelay(bool on) {
  digitalWrite(RELAY_PIN, (on == RELAY_ACTIVE_HIGH) ? HIGH : LOW);
  relayOn = on;
}

void relayOff(const char* reason) {
  if (relayOn) Serial.printf("→ relay OFF (%s)\n", reason);
  writeRelay(false);
  relayOnSinceMs = 0;
  relayBudgetMs  = 0;
}

void relayOnFor(long runtimeSec) {
  relayOnSinceMs = millis();
  relayBudgetMs  = (unsigned long)runtimeSec * 1000UL;
  writeRelay(true);
  Serial.printf("→ relay ON for %lds (local dead-man armed)\n", runtimeSec);
}

// Runs every loop iteration, deliberately not gated behind the post interval or
// any network call. This is the shutoff that survives the Pi disappearing.
void enforceDeadMan() {
  if (!relayOn || relayBudgetMs == 0) return;
  if (millis() - relayOnSinceMs >= relayBudgetMs) {
    relayOff("local runtime limit reached");
    lastAppliedCommand[0] = '\0';  // a fresh ON must be re-applied explicitly
  }
}

// ── Sensors ──────────────────────────────────────────────────────────────
// Each reader returns false when the sensor is absent or failed. The caller
// omits the field entirely rather than inventing a value.
bool readSoilMoisturePct(float* out) {
  if (!SOIL_SENSOR_WIRED) return false;
  int raw = analogRead(SOIL_MOISTURE_PIN);
  float pct = (float)(SOIL_DRY_VALUE - raw) / (SOIL_DRY_VALUE - SOIL_WET_VALUE) * 100.0;
  *out = constrain(pct, 0.0, 100.0);
  return true;
}

bool readWaterLevelPct(float* out) {
  digitalWrite(WATER_LEVEL_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(WATER_LEVEL_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(WATER_LEVEL_TRIG, LOW);

  long duration = pulseIn(WATER_LEVEL_ECHO, HIGH, 30000);
  if (duration == 0) return false;  // echo timeout: unknown, not 0%

  float distanceCm = duration * 0.0343 / 2.0;
  float pct = (TANK_EMPTY_CM - distanceCm) / (TANK_EMPTY_CM - TANK_FULL_CM) * 100.0;
  *out = constrain(pct, 0.0, 100.0);
  return true;
}

// ── Networking ───────────────────────────────────────────────────────────
bool connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return true;
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    enforceDeadMan();  // the relay lease keeps ticking while we wait
    delay(500);
    attempts++;
  }
  return WiFi.status() == WL_CONNECTED;
}

// Parse and apply the relay command carried by the reading response.
// Rejects anything it cannot fully validate. There is no path here that turns
// the relay ON from malformed input.
void applyCommandFrom(const String& responseBody) {
  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, responseBody);
  if (error) {
    Serial.printf("→ ignoring response: bad JSON (%s)\n", error.c_str());
    return;
  }

  JsonObject command = doc["command"];
  if (command.isNull()) {
    Serial.println("→ response carried no command; relay unchanged");
    return;
  }

  const char* actuatorId = command["actuatorId"];
  const char* relayState = command["relayState"];
  if (actuatorId == nullptr || relayState == nullptr) {
    Serial.println("→ ignoring malformed command (missing fields)");
    return;
  }
  if (strcmp(actuatorId, EXPECTED_ACTUATOR_ID) != 0) {
    Serial.printf("→ ignoring command for unknown actuator '%s'\n", actuatorId);
    return;
  }

  if (strcmp(relayState, "OFF") == 0) {
    if (relayOn) relayOff("commanded OFF");
    strncpy(lastAppliedCommand, "OFF", sizeof(lastAppliedCommand) - 1);
    return;
  }

  if (strcmp(relayState, "ON") != 0) {
    Serial.printf("→ ignoring unknown relayState '%s'\n", relayState);
    return;
  }

  // ON requires a bounded runtime. An unbounded ON is the flood.
  long runtime = command["maxRuntimeSec"] | 0L;
  if (runtime < MIN_RUNTIME_SEC || runtime > MAX_RUNTIME_SEC) {
    Serial.printf("→ refusing ON with out-of-range maxRuntimeSec=%ld\n", runtime);
    return;
  }

  char signature[24];
  snprintf(signature, sizeof(signature), "ON:%ld", runtime);
  if (relayOn && strcmp(lastAppliedCommand, signature) == 0) {
    // Same standing command replayed on a duplicate reading. Do not restart
    // the lease — that would let a retry loop extend runtime indefinitely.
    return;
  }

  relayOnFor(runtime);
  strncpy(lastAppliedCommand, signature, sizeof(lastAppliedCommand) - 1);
}

void setup() {
  Serial.begin(115200);

  pinMode(RELAY_PIN, OUTPUT);
  writeRelay(false);  // before anything else: pump off, whatever the polarity

  pinMode(STATUS_LED_PIN, OUTPUT);
  pinMode(WATER_LEVEL_TRIG, OUTPUT);
  pinMode(WATER_LEVEL_ECHO, INPUT);

  dht.begin();

  bootNonce = esp_random();

  if (WIFI_ENABLED) {
    if (connectWiFi()) {
      Serial.printf("Wi-Fi connected. IP: %s\n", WiFi.localIP().toString().c_str());
    } else {
      Serial.println("Wi-Fi unavailable — continuing with Serial output only.");
    }
  }

  Serial.printf("Citadel field node ready. soil=%s rain=%s relay=%s\n",
                SOIL_SENSOR_WIRED ? "wired" : "ABSENT",
                RAIN_GAUGE_WIRED ? "wired" : "ABSENT",
                RELAY_ACTIVE_HIGH ? "active-high" : "active-low");
}

void loop() {
  // First and unconditionally. The shutoff must not depend on the network,
  // the post interval, or anything that can block.
  enforceDeadMan();

  if (millis() - lastReadTime < READ_INTERVAL_MS) return;
  lastReadTime = millis();

  // One stable id per physical sample, reused across every retry of that
  // sample. The edge API deduplicates on it, so a retry after a lost response
  // updates nothing and still returns the current command.
  //
  // Limitation, stated plainly: there is NO persistent retry queue. A reading
  // whose POST fails is dropped, and the next interval produces a genuinely new
  // sample with a new id. The id is stable for the transport-level retries
  // inside a single post attempt, which is what makes the server's
  // deduplication meaningful — it is not durable offline buffering, and this
  // firmware does not claim to be.
  sampleCounter++;
  snprintf(currentEventId, sizeof(currentEventId), "%s-%08lx-%08lu",
           DEVICE_ID, (unsigned long)bootNonce, (unsigned long)sampleCounter);

  float soil = 0, temperature = 0, humidity = 0, water = 0;
  bool haveSoil  = readSoilMoisturePct(&soil);
  bool haveWater = readWaterLevelPct(&water);

  temperature = dht.readTemperature();
  humidity    = dht.readHumidity();
  bool haveTemperature = !isnan(temperature);
  bool haveHumidity    = !isnan(humidity);
  if (!haveTemperature || !haveHumidity) {
    Serial.println("WARNING: DHT11 read failed — omitting those fields.");
  }
  if (!haveWater) {
    Serial.println("WARNING: HC-SR04 read failed — omitting waterLevelPct.");
  }

  JsonDocument payload;
  payload["eventId"]  = currentEventId;
  payload["deviceId"] = DEVICE_ID;
  payload["zoneId"]   = ZONE_ID;
  // Absent sensors are absent. The backend treats missing as unknown; sending
  // a placeholder would let the risk engine reason about a value we never read.
  if (haveSoil)        payload["soilMoisturePct"] = soil;
  if (haveTemperature) payload["temperatureC"]    = temperature;
  if (haveHumidity)    payload["humidityPct"]     = humidity;
  if (haveWater)       payload["waterLevelPct"]   = water;
  if (RAIN_GAUGE_WIRED) payload["rainfallMm"]     = 0.0;
  // Our acknowledgement of the physical relay, so the server can compare
  // desired against reported and show a real fault if they diverge.
  payload["relayReported"] = relayOn ? "ON" : "OFF";

  String body;
  serializeJson(payload, body);
  Serial.println(body);

  if (WIFI_ENABLED && connectWiFi()) {
    HTTPClient http;
    http.begin(EDGE_API_URL);
    http.addHeader("Content-Type", "application/json");
    int httpCode = http.POST(body);

    // 201 = stored, 200 = duplicate replay. Both carry the current command,
    // and the node needs it in both cases — a replay happens precisely because
    // the previous response was lost.
    if (httpCode == 201 || httpCode == 200) {
      Serial.printf("→ Edge API accepted reading (%d).\n", httpCode);
      applyCommandFrom(http.getString());
    } else {
      Serial.printf("→ Edge API error: %d (relay unchanged)\n", httpCode);
    }
    http.end();
  }

  digitalWrite(STATUS_LED_PIN, !digitalRead(STATUS_LED_PIN));
}
