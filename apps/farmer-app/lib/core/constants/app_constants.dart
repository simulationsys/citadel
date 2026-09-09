/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// Default edge API base URL (local network).
  /// Points at the Python dashboard backend (port 3000), which is what the
  /// ESP32 field node currently posts readings to and has real persistence.
  /// The Node edge-api on port 3001 exists but isn't wired to the ESP32 yet —
  /// see docs/backend-integration.md for the plan to consolidate onto 3001.
  static const String defaultEdgeApiUrl = 'http://192.168.1.31:3000';

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
