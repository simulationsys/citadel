class MetricAnalytics {
  final String unit;
  final int count;
  final double? latest;
  final double? average;
  final double? minimum;
  final double? maximum;
  final String trend;

  const MetricAnalytics({required this.unit, required this.count, this.latest,
    this.average, this.minimum, this.maximum, required this.trend});

  factory MetricAnalytics.fromJson(Map<String, dynamic> json) => MetricAnalytics(
    unit: json['unit'] as String? ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
    latest: (json['latest'] as num?)?.toDouble(),
    average: (json['average'] as num?)?.toDouble(),
    minimum: (json['minimum'] as num?)?.toDouble(),
    maximum: (json['maximum'] as num?)?.toDouble(),
    trend: json['trend'] as String? ?? 'unavailable',
  );
}

class FarmRecommendation {
  final String priority;
  final String title;
  final String message;

  const FarmRecommendation({required this.priority, required this.title,
    required this.message});

  factory FarmRecommendation.fromJson(Map<String, dynamic> json) => FarmRecommendation(
    priority: json['priority'] as String? ?? 'low',
    title: json['title'] as String? ?? '',
    message: json['message'] as String? ?? '',
  );
}

class FarmAnalyticsReport {
  final String zoneId;
  final DateTime generatedAt;
  final int periodHours;
  final int readingCount;
  final double completenessPct;
  final int cropScanCount;
  final int irrigationRequestCount;
  final int approvedIrrigationCount;
  final Map<String, MetricAnalytics> metrics;
  final Map<String, int> risks;
  final Map<String, int> cropLabels;
  final List<FarmRecommendation> recommendations;

  const FarmAnalyticsReport({required this.zoneId, required this.generatedAt,
    required this.periodHours, required this.readingCount,
    required this.completenessPct, required this.cropScanCount,
    required this.irrigationRequestCount, required this.approvedIrrigationCount,
    required this.metrics, required this.risks, required this.cropLabels,
    required this.recommendations});

  factory FarmAnalyticsReport.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final period = (json['period'] as Map?)?.cast<String, dynamic>() ?? const {};
    final crop = (json['cropHealth'] as Map?)?.cast<String, dynamic>() ?? const {};
    final metricJson = (json['metrics'] as Map?)?.cast<String, dynamic>() ?? const {};
    return FarmAnalyticsReport(
      zoneId: json['zoneId'] as String? ?? 'zone-a',
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
      periodHours: (period['hours'] as num?)?.toInt() ?? 168,
      readingCount: (summary['readingCount'] as num?)?.toInt() ?? 0,
      completenessPct: (summary['dataCompletenessPct'] as num?)?.toDouble() ?? 0,
      cropScanCount: (summary['cropScanCount'] as num?)?.toInt() ?? 0,
      irrigationRequestCount: (summary['irrigationRequestCount'] as num?)?.toInt() ?? 0,
      approvedIrrigationCount: (summary['approvedIrrigationCount'] as num?)?.toInt() ?? 0,
      metrics: metricJson.map((key, value) => MapEntry(key,
        MetricAnalytics.fromJson((value as Map).cast<String, dynamic>()))),
      risks: ((json['risks'] as Map?) ?? const {}).map((key, value) =>
        MapEntry(key.toString(), (value as num).toInt())),
      cropLabels: ((crop['labelCounts'] as Map?) ?? const {}).map((key, value) =>
        MapEntry(key.toString(), (value as num).toInt())),
      recommendations: ((json['recommendations'] as List?) ?? const [])
        .map((value) => FarmRecommendation.fromJson((value as Map).cast<String, dynamic>()))
        .toList(),
    );
  }
}
