/// Sensor reading from a field node.
/// Mirrors `packages/contracts/src/events.js` → `createSensorReading`.
class Reading {
  final String deviceId;
  final String zoneId;
  final double soilMoisturePct;
  final double temperatureC;
  final double humidityPct;
  final double rainfallMm;
  final double waterLevelPct;
  final DateTime capturedAt;

  const Reading({
    required this.deviceId,
    required this.zoneId,
    required this.soilMoisturePct,
    required this.temperatureC,
    required this.humidityPct,
    required this.rainfallMm,
    required this.waterLevelPct,
    required this.capturedAt,
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      deviceId: json['deviceId'] as String? ?? 'unknown',
      zoneId: json['zoneId'] as String? ?? 'zone-a',
      soilMoisturePct: (json['soilMoisturePct'] as num).toDouble(),
      temperatureC: (json['temperatureC'] as num).toDouble(),
      humidityPct: (json['humidityPct'] as num).toDouble(),
      rainfallMm: (json['rainfallMm'] as num?)?.toDouble() ?? 0,
      waterLevelPct: (json['waterLevelPct'] as num?)?.toDouble() ?? 0,
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'] as String)
          : DateTime.now(),
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
        'capturedAt': capturedAt.toIso8601String(),
      };
}
