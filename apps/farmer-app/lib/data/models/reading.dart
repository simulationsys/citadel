/// Sensor reading from a field node.
///
/// Mirrors `ReadingResponse` in `services/edge-api/app/schemas.py`. **Every
/// sensor is nullable**, because the backend deliberately accepts partial
/// payloads — an ESP32 with no thermometer must not 422, and the documented
/// flood demo (`docs/demo.md`) posts only `waterLevelPct` and `rainfallMm`.
///
/// Missing is not zero. A null here means "this sensor did not report", and it
/// must reach the UI as `--`, never as a plausible-looking 0 that could read as
/// bone-dry soil or freezing air.
class Reading {
  final String deviceId;
  final String zoneId;
  final double? soilMoisturePct;
  final double? temperatureC;
  final double? humidityPct;
  final double? rainfallMm;
  final double? waterLevelPct;

  /// When the node sampled. Nullable: never substitute `DateTime.now()`, which
  /// would make an hours-old reading look current.
  final DateTime? capturedAt;

  /// When the edge API received it — the basis for server-side freshness.
  final DateTime? receivedAt;

  /// The node's acknowledgement of its own relay ("ON"/"OFF"), if it echoes one.
  final String? relayReported;

  const Reading({
    required this.deviceId,
    required this.zoneId,
    this.soilMoisturePct,
    this.temperatureC,
    this.humidityPct,
    this.rainfallMm,
    this.waterLevelPct,
    this.capturedAt,
    this.receivedAt,
    this.relayReported,
  });

  static double? _num(dynamic value) => (value as num?)?.toDouble();

  static DateTime? _time(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      deviceId: json['deviceId'] as String? ?? 'unknown',
      zoneId: json['zoneId'] as String? ?? 'zone-a',
      soilMoisturePct: _num(json['soilMoisturePct']),
      temperatureC: _num(json['temperatureC']),
      humidityPct: _num(json['humidityPct']),
      rainfallMm: _num(json['rainfallMm']),
      waterLevelPct: _num(json['waterLevelPct']),
      capturedAt: _time(json['capturedAt']),
      receivedAt: _time(json['receivedAt']),
      relayReported: json['relayReported'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'zoneId': zoneId,
        'soilMoisturePct': soilMoisturePct,
        'temperatureC': temperatureC,
        'humidityPct': humidityPct,
        'rainfallMm': rainfallMm,
        'waterLevelPct': waterLevelPct,
        'capturedAt': capturedAt?.toIso8601String(),
        'receivedAt': receivedAt?.toIso8601String(),
        'relayReported': relayReported,
      };

  /// True when the node reported nothing at all for this sensor.
  bool get hasSoilMoisture => soilMoisturePct != null;
  bool get hasTemperature => temperatureC != null;
  bool get hasHumidity => humidityPct != null;

  /// Display helper: `--` for an absent sensor, never a stand-in number.
  static String display(double? value, {int decimals = 0}) =>
      value == null ? '--' : value.toStringAsFixed(decimals);
}
