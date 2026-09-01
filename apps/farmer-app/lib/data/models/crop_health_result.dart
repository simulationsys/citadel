/// Crop health diagnosis result from the AI vision pipeline.
/// Mirrors Workstream 02 output format.
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

  const CropHealthResult({
    required this.kind,
    required this.crop,
    required this.label,
    required this.confidence,
    required this.imageQuality,
  });

  factory CropHealthResult.fromJson(Map<String, dynamic> json) {
    return CropHealthResult(
      kind: json['kind'] as String,
      crop: json['crop'] as String,
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      imageQuality: json['imageQuality'] as String,
    );
  }

  /// Human-readable label text.
  String get displayLabel => label.replaceAll('_', ' ');

  /// Whether the result is broadly positive.
  bool get isHealthy => label == 'healthy';
}
