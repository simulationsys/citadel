import 'advisory.dart';
import 'reading.dart';

/// Freshness of the sensor data, as judged by the **edge API**, not the phone.
///
/// The server computes this from `receivedAt` (`app/main.py:_freshness`,
/// live <= 120 s / stale <= 900 s). Trusting the server matters: a response that
/// arrives promptly can still carry hours-old sensor data, and only the node's
/// own timestamps reveal that.
enum DataFreshness { live, stale, offline }

DataFreshness freshnessFromString(String? value) {
  switch (value) {
    case 'live':
      return DataFreshness.live;
    case 'stale':
      return DataFreshness.stale;
    default:
      return DataFreshness.offline;
  }
}

/// Combined farm state returned by `GET /v1/farm-state`.
///
/// `reading` is nullable: on a cold start the edge API returns 200 with
/// `reading: null` ("no data yet" is a state, not a missing resource), and the
/// UI must show that honestly rather than inventing numbers.
class FarmState {
  final String zoneId;
  final Reading? reading;
  final List<Advisory> advisories;
  final DataFreshness freshness;

  /// True when this came from the on-device cache rather than the live node.
  /// Cached state must be visibly marked, never presented as current.
  final bool fromCache;

  const FarmState({
    this.zoneId = 'zone-a',
    this.reading,
    this.advisories = const [],
    this.freshness = DataFreshness.offline,
    this.fromCache = false,
  });

  factory FarmState.fromJson(Map<String, dynamic> json, {bool fromCache = false}) {
    final readingJson = json['reading'];
    return FarmState(
      zoneId: json['zoneId'] as String? ?? 'zone-a',
      reading: readingJson is Map<String, dynamic>
          ? Reading.fromJson(readingJson)
          : null,
      advisories: ((json['advisories'] as List<dynamic>?) ?? const [])
          .map((e) => Advisory.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      // A cached payload is never "live" no matter what the server said when
      // it was captured.
      freshness: fromCache
          ? DataFreshness.stale
          : freshnessFromString(json['freshness'] as String?),
      fromCache: fromCache,
    );
  }

  FarmState copyWith({bool? fromCache, DataFreshness? freshness}) => FarmState(
        zoneId: zoneId,
        reading: reading,
        advisories: advisories,
        freshness: freshness ?? this.freshness,
        fromCache: fromCache ?? this.fromCache,
      );

  bool get hasReading => reading != null;

  /// Advisories sorted by severity (critical first).
  List<Advisory> get sortedAdvisories =>
      List.of(advisories)..sort((a, b) => a.severityOrder.compareTo(b.severityOrder));
}
