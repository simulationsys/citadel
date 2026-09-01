/// Advisory produced by the edge API's risk/advisory engine.
/// Mirrors output of `services/edge-api/src/advisory.js` → `buildAdvisories`.
class Advisory {
  /// One of: irrigation, disease, pest, heat, flood.
  final String type;

  /// One of: critical, warning, info.
  final String severity;

  /// Farmer-readable title, e.g. "Irrigate now".
  final String title;

  /// Explanation of what was detected and why.
  final String message;

  /// Machine-readable action tag, e.g. START_IRRIGATION, CHECK_DRAINAGE.
  final String action;

  const Advisory({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.action,
  });

  factory Advisory.fromJson(Map<String, dynamic> json) {
    return Advisory(
      type: json['type'] as String,
      severity: json['severity'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      action: json['action'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'severity': severity,
        'title': title,
        'message': message,
        'action': action,
      };

  /// Severity sort order: critical > warning > info.
  int get severityOrder {
    switch (severity) {
      case 'critical':
        return 0;
      case 'warning':
        return 1;
      default:
        return 2;
    }
  }
}
