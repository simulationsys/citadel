/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// Default edge API base URL (local network).
  /// Points at the consolidated Python edge API on port 3001
  /// (services/edge-api) — the target architecture from
  /// docs/backend-integration.md, now the only backend in the repo.
  static const String defaultEdgeApiUrl = 'http://192.168.1.11:3001';

  /// Polling interval for farm state refresh.
  /// Match the ESP32's 10-second reporting interval so a physical sensor
  /// change appears in the app on the next sample during field use and demos.
  static const Duration pollInterval = Duration(seconds: 10);

  /// Data freshness thresholds. Mirrors FRESH_SEC/STALE_SEC in
  /// services/edge-api/app/main.py. The server's `freshness` field is
  /// authoritative; these are only a client-side fallback.
  static const Duration freshThreshold = Duration(minutes: 2);
  static const Duration staleThreshold = Duration(minutes: 15);

  /// Advisory types. Owned by `citadel_pest_risk.risk_engine.ADVISORY_TYPES`
  /// and published in `/openapi.json`. Note `disease_risk`, not `disease`.
  static const String typeIrrigation = 'irrigation';
  static const String typeDisease = 'disease_risk';
  static const String typePest = 'pest';
  static const String typeHeat = 'heat';
  static const String typeFlood = 'flood';

  /// Severity levels.
  static const String severityCritical = 'critical';
  static const String severityWarning = 'warning';
  static const String severityInfo = 'info';
}
