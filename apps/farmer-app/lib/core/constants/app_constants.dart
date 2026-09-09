/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// Default edge API base URL (local network).
  /// Points at the consolidated Python edge API on port 3001
  /// (services/edge-api) — the target architecture from
  /// docs/backend-integration.md, now the only backend in the repo.
  static const String defaultEdgeApiUrl = 'http://192.168.1.31:3001';

  /// Polling interval for farm state refresh.
  static const Duration pollInterval = Duration(seconds: 30);

  /// Data freshness thresholds.
  static const Duration freshThreshold = Duration(minutes: 2);
  static const Duration staleThreshold = Duration(minutes: 15);

  /// Advisory types (mirrors packages/contracts/src/events.js).
  static const String typeIrrigation = 'irrigation';
  static const String typeDisease = 'disease';
  static const String typePest = 'pest';
  static const String typeHeat = 'heat';
  static const String typeFlood = 'flood';

  /// Severity levels.
  static const String severityCritical = 'critical';
  static const String severityWarning = 'warning';
  static const String severityInfo = 'info';
}
