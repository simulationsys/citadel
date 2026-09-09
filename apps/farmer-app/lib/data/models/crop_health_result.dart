/// Crop health diagnosis returned by `POST /v1/crop-health`.
///
/// The edge API wraps it as `{ "result": {...}, "observation": ..., "state": ... }`.
///
/// A `CropHealthResult` only ever describes an inference that **actually ran**.
/// When the model, its runtime, or the network is unavailable, the repository
/// throws [CropScanException] instead of manufacturing one of these — a fake
/// "inconclusive" is indistinguishable to the farmer from a real low-confidence
/// answer, and would let a broken AI pipeline look like a working one.
class CropHealthResult {
  /// Always "crop_health".
  final String kind;

  /// The crop analysed, e.g. "tomato".
  final String crop;

  /// One of the model's five classes, or "inconclusive" (confidence < 0.50),
  /// or "invalid_image" (rejected by the quality gate before inference).
  final String label;

  /// Model confidence (0.0–1.0).
  final double confidence;

  /// "acceptable" | "poor" | "invalid".
  final String imageQuality;

  /// Why the result is qualified — low confidence, blur, no leaf detected.
  final String? limitation;

  final String? id;
  final DateTime? timestamp;
  final List<String> recommendations;

  const CropHealthResult({
    this.kind = 'crop_health',
    this.crop = 'unknown',
    required this.label,
    required this.confidence,
    this.imageQuality = 'acceptable',
    this.limitation,
    this.id,
    this.timestamp,
    this.recommendations = const [],
  });

  factory CropHealthResult.fromJson(Map<String, dynamic> json) {
    // Unwrap the edge envelope; tolerate a bare result for cached payloads.
    final Map<String, dynamic> data =
        json['result'] is Map ? (json['result'] as Map).cast<String, dynamic>() : json;
    return CropHealthResult(
      kind: data['kind'] as String? ?? 'crop_health',
      crop: data['crop'] as String? ?? 'unknown',
      label: data['label'] as String? ?? 'inconclusive',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      imageQuality: data['imageQuality'] as String? ??
          data['image_quality'] as String? ??
          'acceptable',
      limitation: data['limitation'] as String?,
      id: data['id']?.toString(),
      timestamp: data['timestamp'] is String
          ? DateTime.tryParse(data['timestamp'] as String)
          : null,
      recommendations: (data['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Human-readable label text.
  String get displayLabel => label.replaceAll('_', ' ');

  /// Alias used by scan UI.
  String get diagnosis => displayLabel;

  bool get isHealthy => label == 'healthy';

  /// The model ran but was not confident enough to name a condition.
  bool get isInconclusive => label == 'inconclusive';

  /// The photo was rejected before inference — the farmer should recapture.
  bool get isRejectedImage => label == 'invalid_image';
}

/// Why a crop scan could not produce a diagnosis.
enum CropScanFailure {
  /// 503 — no TFLite runtime, missing model, or tensor mismatch on the node.
  modelUnavailable,

  /// 502 — the inference process ran but returned nothing parsable.
  badModelOutput,

  /// 504 or client-side timeout.
  timeout,

  /// The edge node could not be reached at all.
  networkUnavailable,

  /// A 2xx body the app could not parse.
  malformedResponse,

  /// Any other non-2xx status.
  serverError,
}

/// Thrown when the scan pipeline failed. Distinct from a low-confidence result:
/// this means no inference outcome exists to report.
class CropScanException implements Exception {
  final CropScanFailure failure;
  final String message;
  final int? statusCode;

  const CropScanException(this.failure, this.message, {this.statusCode});

  /// Farmer-facing copy. Says the node is unavailable — never implies a
  /// diagnosis was attempted and came back uncertain.
  String get farmerMessage {
    switch (failure) {
      case CropScanFailure.modelUnavailable:
        return 'The crop-health AI is not available on your field node. '
            'The scan was not run.';
      case CropScanFailure.badModelOutput:
        return 'The field node could not complete the analysis. Please try again.';
      case CropScanFailure.timeout:
        return 'The field node took too long to respond. The scan was not completed.';
      case CropScanFailure.networkUnavailable:
        return 'Cannot reach your field node. Check that you are on the farm '
            'Wi-Fi, then try again.';
      case CropScanFailure.malformedResponse:
        return 'The field node sent an unreadable response. Please try again.';
      case CropScanFailure.serverError:
        return 'The field node reported an error. The scan was not completed.';
    }
  }

  @override
  String toString() => 'CropScanException(${failure.name}, $message)';
}
