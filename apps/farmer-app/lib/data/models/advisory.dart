/// Advisory produced by the edge API's risk engine.
///
/// The vocabulary is owned by `citadel_pest_risk.risk_engine.ADVISORY_TYPES` and
/// published in `/openapi.json`: **flood, irrigation, heat, disease_risk, pest**.
/// Note `disease_risk`, not `disease` — the app previously used the shorter
/// form, so disease advisories fell through to default styling.
class Advisory {
  /// One of: irrigation, disease_risk, pest, heat, flood.
  final String type;

  /// Supporting sensor values the engine used. Shown so an advisory can be
  /// justified to the farmer rather than asserted.
  final Map<String, dynamic> evidence;

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
    this.evidence = const {},
  });

  factory Advisory.fromJson(Map<String, dynamic> json) {
    return Advisory(
      // Tolerant of the legacy short form so a cached payload written by an
      // older build still renders with the right styling.
      type: json['type'] == 'disease' ? 'disease_risk' : json['type'] as String,
      severity: json['severity'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      action: json['action'] as String? ?? '',
      evidence: (json['evidence'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'severity': severity,
        'title': title,
        'message': message,
        'action': action,
        'evidence': evidence,
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
