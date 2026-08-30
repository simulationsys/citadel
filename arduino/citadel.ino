// Citadel firmware starter.
// Set the LED pin to match the target Arduino board before flashing.
const int STATUS_LED_PIN = LED_BUILTIN;

void setup() {
  pinMode(STATUS_LED_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  digitalWrite(STATUS_LED_PIN, HIGH);
  delay(500);
  digitalWrite(STATUS_LED_PIN, LOW);
  delay(500);
}
