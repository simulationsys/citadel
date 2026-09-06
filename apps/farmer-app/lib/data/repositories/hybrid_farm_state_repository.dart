import 'dart:io';

import '../models/crop_health_result.dart';
import '../models/farm_state.dart';
import 'farm_state_repository.dart';
import 'http_farm_state_repository.dart';
import 'mock_farm_state_repository.dart';

/// Tries the live edge API first (phone → laptop over Wi-Fi); falls back to
/// mock screenshot data when offline so the UI never goes blank.
///
/// The delegate Http repo already serves its SharedPreferences cache before
/// throwing, so this only hits mock on first-run-offline.
class HybridFarmStateRepository implements FarmStateRepository {
  final HttpFarmStateRepository live;
  final MockFarmStateRepository mock = MockFarmStateRepository();

  HybridFarmStateRepository({required this.live});

  @override
  Future<FarmState> getFarmState() async {
    try {
      return await live.getFarmState();
    } catch (_) {
      return mock.getFarmState();
    }
  }

  @override
  Future<CropHealthResult> submitImage(File image) async {
    CropHealthResult r;
    try {
      r = await live.submitImage(image);
    } catch (_) {
      return mock.submitImage(image);
    }
    // Live returns inconclusive-with-0-confidence when offline; let mock
    // give a demo diagnosis instead in that case.
    if (r.confidence == 0.0) return mock.submitImage(image);
    return r;
  }

  @override
  Future<void> approveIrrigation(String action, {required bool approved}) async {
    try {
      await live.approveIrrigation(action, approved: approved);
    } catch (_) {
      await mock.approveIrrigation(action, approved: approved);
    }
  }
}
