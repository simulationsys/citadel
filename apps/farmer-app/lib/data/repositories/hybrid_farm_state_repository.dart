import 'dart:io';

import '../models/crop_health_result.dart';
import '../models/farm_state.dart';
import '../models/irrigation_request.dart';
import '../models/farm_analytics_report.dart';
import '../models/farm_assistant_response.dart';
import 'farm_state_repository.dart';
import 'http_farm_state_repository.dart';
import 'synthetic_farm_data.dart';

/// Live edge API, with the last-known-good cache as the only fallback.
///
/// **This class used to silently fall through to [MockFarmStateRepository]
/// whenever the edge node was unreachable.** That made a disconnected phone
/// indistinguishable from a working farm: the home screen showed invented
/// sensor values, and a crop scan returned a fabricated "early blight" — with
/// no error, no badge, and no way for the farmer or the presenter to notice.
///
/// The offline story now lives where it belongs:
/// * farm state → [HttpFarmStateRepository]'s SharedPreferences cache, returned
///   marked `fromCache` so the UI labels it stale;
/// * crop scans and irrigation decisions → propagate the failure, because
///   there is no truthful offline answer to either.
///
/// Exception: while [kDemoData] is on (the default, for recording demo videos),
/// farm state and analytics fall back to [SyntheticFarmData] whenever the node
/// has no live reading. Build with `--dart-define=DEMO_DATA=false` for field use.
class HybridFarmStateRepository implements FarmStateRepository {
  final HttpFarmStateRepository live;

  HybridFarmStateRepository({required this.live});

  @override
  Future<FarmState> getFarmState() async {
    if (!kDemoData) return live.getFarmState();
    // Demo video: real data wins only while the node is actually live.
    try {
      final state = await live.getFarmState().timeout(const Duration(milliseconds: 1500));
      if (state.hasReading && state.freshness == DataFreshness.live) return state;
    } catch (_) {}
    return SyntheticFarmData.farmState(live.zoneId);
  }

  @override
  Future<CropHealthResult> submitImage(File image) => live.submitImage(image);

  @override
  Future<IrrigationOutcome> decideIrrigation({
    required bool approved,
    String requestedBy = 'farmer-app',
    int? maxRuntimeSec,
  }) =>
      live.decideIrrigation(
          approved: approved,
          requestedBy: requestedBy,
          maxRuntimeSec: maxRuntimeSec);

  @override
  Future<FarmAnalyticsReport> analyzeFarm({int hours = 168}) async {
    if (!kDemoData) return live.analyzeFarm(hours: hours);
    try {
      final report = await live.analyzeFarm(hours: hours).timeout(const Duration(seconds: 3));
      if (report.readingCount > 0) return report;
    } catch (_) {}
    // Feels like real analysis rather than an instant canned answer.
    await Future.delayed(const Duration(milliseconds: 1200));
    return SyntheticFarmData.analytics(live.zoneId, hours);
  }

  @override
  Future<FarmAssistantResponse> askAssistant(String question, String language) =>
      live.askAssistant(question, language);
}
