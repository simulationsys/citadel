import 'dart:math';

import '../models/advisory.dart';
import '../models/farm_analytics_report.dart';
import '../models/farm_state.dart';
import '../models/reading.dart';

/// Demo-video data: sensor values that drift like a real field node.
///
/// Used by [HybridFarmStateRepository] only when the edge node has no live
/// reading. Build with `--dart-define=DEMO_DATA=false` to turn it off.
// ponytail: global toggle; move to Settings if demos need switching at runtime.
const bool kDemoData = bool.fromEnvironment('DEMO_DATA', defaultValue: true);

class SyntheticFarmData {
  SyntheticFarmData._();

  static final _rng = Random();

  // Each metric: current value, the value it drifts back towards, step size,
  // and hard bounds. Static so the walk survives repository rebuilds.
  static final _m = <String, _Walk>{
    'soilMoisturePct': _Walk(41, 41, 0.7, 22, 68),
    'temperatureC': _Walk(31.4, 31.4, 0.25, 24, 38),
    'humidityPct': _Walk(58, 58, 0.8, 35, 85),
    'rainfallMm': _Walk(0.4, 0.3, 0.08, 0, 3),
    'waterLevelPct': _Walk(64, 64, 0.5, 30, 90),
  };

  static double _next(String key) => _m[key]!.step(_rng);

  static FarmState farmState(String zoneId) {
    final now = DateTime.now();
    final reading = Reading(
      deviceId: 'field-node-01',
      zoneId: zoneId,
      soilMoisturePct: _next('soilMoisturePct'),
      temperatureC: _next('temperatureC'),
      humidityPct: _next('humidityPct'),
      rainfallMm: _next('rainfallMm'),
      waterLevelPct: _next('waterLevelPct'),
      capturedAt: now.subtract(const Duration(seconds: 2)),
      receivedAt: now,
      relayReported: 'OFF',
    );
    return FarmState(
      zoneId: zoneId,
      reading: reading,
      freshness: DataFreshness.live,
      advisories: _advisories(reading),
    );
  }

  static List<Advisory> _advisories(Reading r) => [
        if (r.soilMoisturePct! < 38)
          const Advisory(
            type: 'irrigation',
            severity: 'warning',
            title: 'Irrigate now',
            message: 'Low soil moisture detected. Irrigate this zone for 15 minutes.',
            action: 'START_IRRIGATION',
          ),
        if (r.temperatureC! > 32)
          const Advisory(
            type: 'heat',
            severity: 'warning',
            title: 'Heat-stress risk',
            message: 'High temperature and dry soil. Irrigate during cooler hours.',
            action: 'SCHEDULE_EVENING_IRRIGATION',
          ),
      ];

  static FarmAnalyticsReport analytics(String zoneId, int hours) {
    const units = {
      'soilMoisturePct': '%',
      'temperatureC': '°C',
      'humidityPct': '%',
      'rainfallMm': 'mm',
      'waterLevelPct': '%',
    };
    double r1(double v) => (v * 10).roundToDouble() / 10;
    final readings = hours * 360; // one sample every 10 s
    final completeness = 94 + _rng.nextDouble() * 5;
    final metrics = units.map((key, unit) {
      final w = _m[key]!;
      final spread = (w.max - w.min) * 0.18;
      final avg = w.value + (w.center - w.value) * 0.5;
      final delta = w.value - w.center;
      return MapEntry(
        key,
        MetricAnalytics(
          unit: unit,
          count: (readings * completeness / 100).round(),
          latest: r1(w.value),
          average: r1(avg),
          minimum: r1(max(w.min, avg - spread)),
          maximum: r1(min(w.max, avg + spread)),
          trend: delta.abs() < w.stepSize ? 'stable' : (delta > 0 ? 'rising' : 'falling'),
        ),
      );
    });
    final scans = max(1, hours ~/ 24);
    return FarmAnalyticsReport(
      zoneId: zoneId,
      generatedAt: DateTime.now(),
      periodHours: hours,
      readingCount: readings,
      completenessPct: completeness,
      cropScanCount: scans,
      irrigationRequestCount: max(1, hours ~/ 36),
      approvedIrrigationCount: max(1, hours ~/ 48),
      metrics: metrics,
      risks: {'irrigation': max(1, hours ~/ 30), 'heat': hours ~/ 50},
      cropLabels: {'healthy': (scans * 0.7).ceil(), 'possible_early_blight': scans - (scans * 0.7).ceil()}
        ..removeWhere((_, v) => v == 0),
      recommendations: const [
        FarmRecommendation(
          priority: 'high',
          title: 'Irrigate in the evening',
          message: 'Soil moisture dips in the afternoon heat. Water after 5 PM to cut evaporation losses.',
        ),
        FarmRecommendation(
          priority: 'medium',
          title: 'Watch for leaf blight',
          message: 'Warm, humid mornings favour early blight. Scan lower leaves every 2–3 days.',
        ),
        FarmRecommendation(
          priority: 'low',
          title: 'Water storage is healthy',
          message: 'Tank level is steady. No action needed this week.',
        ),
      ],
    );
  }
}

/// Mean-reverting random walk: small steps, gently pulled back to [center].
class _Walk {
  double value;
  final double center, stepSize, min, max;
  _Walk(this.value, this.center, this.stepSize, this.min, this.max);

  double step(Random rng) {
    final noise = (rng.nextDouble() * 2 - 1) * stepSize;
    final pull = (center - value) * 0.08;
    value = (value + noise + pull).clamp(min, max).toDouble();
    return value;
  }
}
