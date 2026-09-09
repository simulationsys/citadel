import 'dart:io';

import '../models/crop_health_result.dart';
import '../models/farm_state.dart';
import '../models/irrigation_request.dart';
import '../models/farm_analytics_report.dart';
import '../models/farm_assistant_response.dart';
import 'farm_state_repository.dart';
import 'http_farm_state_repository.dart';

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
/// Demo data is still available, but only by explicitly selecting demo mode,
/// which labels itself on screen. See `main.dart`.
class HybridFarmStateRepository implements FarmStateRepository {
  final HttpFarmStateRepository live;

  HybridFarmStateRepository({required this.live});

  @override
  Future<FarmState> getFarmState() => live.getFarmState();

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
  Future<FarmAnalyticsReport> analyzeFarm({int hours = 168}) =>
      live.analyzeFarm(hours: hours);

  @override
  Future<FarmAssistantResponse> askAssistant(String question, String language) =>
      live.askAssistant(question, language);
}
