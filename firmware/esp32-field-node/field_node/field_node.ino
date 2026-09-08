// Citadel ESP32 field node.
// Matches the wired build: soil moisture (GPIO34, add sensor when bought),
// DHT11 (GPIO4), HC-SR04 (TRIG 32 / ECHO 33 via divider), relay (GPIO26).
// Rain gauge is not wired yet, so rainfallMm is reported as 0.
// Always prints JSON over Serial; also POSTs to the edge API if Wi-Fi connects.

#include <DHT.h>

// ── Wi-Fi + edge API (fill in once you're ready to connect over the network) ──
const char* WIFI_SSID    = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
const char* EDGE_API_URL  = "http://192.168.1.100:3001/v1/readings"; // laptop's LAN IP for now
const char* DEVICE_ID     = "field-node-01";
const char* ZONE_ID       = "zone-a";
const bool  WIFI_ENABLED  = false; // flip to true once WIFI_SSID/PASSWORD are set

// ── Pins ─────────────────────────────────────────────────────────────────
const int STATUS_LED_PIN    = 2; // onboard LED on most ESP32 DevKit boards; harmless if unused
const int SOIL_MOISTURE_PIN = 34;
const int WATER_LEVEL_TRIG  = 32;
const int WATER_LEVEL_ECHO  = 33; // through the 1k/2k divider, never direct
const int DHT_PIN           = 4;
const int RELAY_PIN         = 26;

#define DHT_TYPE DHT11
DHT dht(DHT_PIN, DHT_TYPE);

// ── Calibration (adjust after you run Step 13 in the integration guide) ───
const int SOIL_DRY_VALUE  = 3200;
const int SOIL_WET_VALUE  = 1400;
const float TANK_EMPTY_CM = 100.0;
const float TANK_FULL_CM  = 10.0;

const unsigned long READ_INTERVAL_MS = 10000;
unsigned long lastReadTime = 0;

float readSoilMoisturePct() {
  int raw = analogRead(SOIL_MOISTURE_PIN);
  float pct = (float)(SOIL_DRY_VALUE - raw) / (SOIL_DRY_VALUE - SOIL_WET_VALUE) * 100.0;
  return constrain(pct, 0.0, 100.0);
}

float readWaterLevelPct() {
  digitalWrite(WATER_LEVEL_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(WATER_LEVEL_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(WATER_LEVEL_TRIG, LOW);

  long duration = pulseIn(WATER_LEVEL_ECHO, HIGH, 30000);
  if (duration == 0) return -1;

  float distanceCm = duration * 0.0343 / 2.0;
  float pct = (TANK_EMPTY_CM - distanceCm) / (TANK_EMPTY_CM - TANK_FULL_CM) * 100.0;
  return constrain(pct, 0.0, 100.0);
}

void setup() {
  Serial.begin(115200);

  pinMode(STATUS_LED_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(WATER_LEVEL_TRIG, OUTPUT);
  pinMode(WATER_LEVEL_ECHO, INPUT);

  digitalWrite(RELAY_PIN, LOW); // pump off by default — safety first

  dht.begin();

  Serial.println("Citadel field node initialized (DHT11, HC-SR04, relay wired; soil + rain pending).");
}

void loop() {
  if (millis() - lastReadTime < READ_INTERVAL_MS) return;
  lastReadTime = millis();

  float soilMoisturePct = readSoilMoisturePct();
  float temperatureC    = dht.readTemperature();
  float humidityPct     = dht.readHumidity();
  float rainfallMm      = 0.0; // rain gauge not wired yet
  float waterLevelPct   = readWaterLevelPct();

  bool dhtFailed = isnan(temperatureC) || isnan(humidityPct);
  if (dhtFailed) {
    Serial.println("WARNING: DHT11 read failed. Using safe defaults.");
    temperatureC = 25.0;
    humidityPct  = 50.0;
  }

  bool waterFailed = (waterLevelPct < 0);
  if (waterFailed) {
    Serial.println("WARNING: HC-SR04 read failed. Defaulting to 0.");
    waterLevelPct = 0.0;
  }

  char jsonPayload[512];
  snprintf(jsonPayload, sizeof(jsonPayload),
    "{\"deviceId\":\"%s\",\"zoneId\":\"%s\","
    "\"soilMoisturePct\":%.1f,\"temperatureC\":%.1f,"
    "\"humidityPct\":%.1f,\"rainfallMm\":%.1f,"
    "\"waterLevelPct\":%.1f,"
    "\"sensorStatus\":{\"dht\":\"%s\",\"ultrasonic\":\"%s\"}}",
    DEVICE_ID, ZONE_ID,
    soilMoisturePct, temperatureC,
    humidityPct, rainfallMm,
    waterLevelPct,
    dhtFailed ? "error" : "ok",
    waterFailed ? "error" : "ok"
  );

  Serial.println(jsonPayload);

  digitalWrite(STATUS_LED_PIN, !digitalRead(STATUS_LED_PIN));
}
