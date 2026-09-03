import 'reading.dart';
import 'advisory.dart';

/// Combined farm state returned by `GET /v1/farm-state`.
class FarmState {
  final Reading reading;
  final List<Advisory> advisories;

  const FarmState({
    required this.reading,
    required this.advisories,
  });

  factory FarmState.fromJson(Map<String, dynamic> json) {
    return FarmState(
      reading: Reading.fromJson(json['reading'] as Map<String, dynamic>),
      advisories: (json['advisories'] as List<dynamic>)
          .map((e) => Advisory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Advisories sorted by severity (critical first).
  List<Advisory> get sortedAdvisories =>
      List.of(advisories)..sort((a, b) => a.severityOrder.compareTo(b.severityOrder));
}
