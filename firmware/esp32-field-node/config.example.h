// Copy this file to field_node/config.h — next to field_node.ino, which is what
// the Arduino IDE compiles — and fill in your own values.
//
// field_node/config.h is gitignored and must stay uncommitted. Wi-Fi
// credentials do not belong in the repository.

#define WIFI_SSID     "your-network"
#define WIFI_PASSWORD "your-password"

// The Raspberry Pi's LAN address and the consolidated edge API's port.
// Never "localhost" or 127.0.0.1 — on the ESP32 those resolve to the ESP32.
#define EDGE_API_URL "http://192.168.1.31:3001/v1/readings"

#define DEVICE_ID "field-node-01"
#define ZONE_ID   "zone-a"

// Must match actuator_id_for(zone) in services/edge-api/app/db.py.
// zone-a keeps the historical id; other zones are "pump-<zoneId>".
#define EXPECTED_ACTUATOR_ID "pump-relay-01"
