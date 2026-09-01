// Citadel ESP32 field node. Wire sensors before replacing the placeholder reads.
// The serial JSON output is the contract consumed by the edge gateway.
const int STATUS_LED_PIN = LED_BUILTIN;
const int SOIL_MOISTURE_PIN = 34;
const int WATER_LEVEL_PIN = 35;
const int RELAY_PIN = 26;

float asPercent(int value) { return constrain(map(value, 4095, 0, 0, 100), 0, 100); }

void setup() {
  pinMode(STATUS_LED_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // pump off by default
  Serial.begin(115200);
}

void loop() {
  const float soilMoisturePct = asPercent(analogRead(SOIL_MOISTURE_PIN));
  const float waterLevelPct = asPercent(analogRead(WATER_LEVEL_PIN));
  Serial.printf("{\"deviceId\":\"field-node-01\",\"soilMoisturePct\":%.1f,\"waterLevelPct\":%.1f}\n", soilMoisturePct, waterLevelPct);
  digitalWrite(STATUS_LED_PIN, !digitalRead(STATUS_LED_PIN));
  delay(10000);
}
