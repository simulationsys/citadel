/// Crop health diagnosis result from the AI vision pipeline.
/// Mirrors Workstream 02 output format + edge `POST /v1/crop-health` response.
class CropHealthResult {
  /// Always "crop_health".
  final String kind;

  /// The crop being analysed, e.g. "tomato".
  final String crop;

  /// Classification label, e.g. "healthy", "possible_early_blight".
  final String label;

  /// Model confidence (0.0–1.0).
  final double confidence;

  /// Image quality assessment: "acceptable" or "poor".
  final String imageQuality;

  final String? id;
  final DateTime? timestamp;
  final List<String> recommendations;

  const CropHealthResult({
    this.kind = 'crop_health',
    this.crop = 'unknown',
    required this.label,
    required this.confidence,
    this.imageQuality = 'acceptable',
    this.id,
    this.timestamp,
    this.recommendations = const [],
  });

  factory CropHealthResult.fromJson(Map<String, dynamic> json) {
    // Edge wraps result as { result: {...}, state? } — unwrap if needed.
    final Map<String, dynamic> data =
        json['result'] is Map<String, dynamic> ? json['result'] as Map<String, dynamic> : json;
    return CropHealthResult(
      kind: data['kind'] as String? ?? 'crop_health',
      crop: data['crop'] as String? ?? 'unknown',
      label: data['label'] as String? ?? 'inconclusive',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      imageQuality: data['imageQuality'] as String? ?? data['image_quality'] as String? ?? 'acceptable',
      id: data['id'] as String?,
      timestamp: data['timestamp'] != null ? DateTime.tryParse(data['timestamp'] as String) : null,
      recommendations: (data['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  /// Human-readable label text.
  String get displayLabel => label.replaceAll('_', ' ');

  /// Alias used by scan UI.
  String get diagnosis => displayLabel;

  /// Whether the result is broadly positive.
  bool get isHealthy => label == 'healthy';
}
