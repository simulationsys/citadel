import 'dart:io';

import '../models/advisory.dart';
import '../models/crop_health_result.dart';
import '../models/farm_state.dart';
import '../models/irrigation_request.dart';
import '../models/reading.dart';
import 'farm_state_repository.dart';

/// Hardcoded demo data. **Only ever reachable when demo mode is explicitly
/// selected** — never as a silent fallback for an unreachable edge node. See
/// [HybridFarmStateRepository] for why that fallback was removed.
class MockFarmStateRepository implements FarmStateRepository {
  @override
  Future<FarmState> getFarmState() async {
    // Simulate network latency.
    await Future.delayed(const Duration(milliseconds: 800));

    return FarmState(
      freshness: DataFreshness.live,
      reading: Reading(
        deviceId: 'field-node-01',
        zoneId: 'zone-a',
        soilMoisturePct: 24,
        temperatureC: 34,
        humidityPct: 55,
        rainfallMm: 0,
        waterLevelPct: 12,
        capturedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      advisories: const [
        Advisory(
          type: 'irrigation',
          severity: 'warning',
          title: 'Irrigate now',
          message:
              'Low soil moisture detected. Irrigate this zone for 15 minutes.',
          action: 'START_IRRIGATION',
        ),
        Advisory(
          type: 'heat',
          severity: 'warning',
          title: 'Heat-stress risk',
          message:
              'High temperature and dry soil. Irrigate during cooler hours.',
          action: 'SCHEDULE_EVENING_IRRIGATION',
        ),
      ],
    );
  }

  @override
  Future<CropHealthResult> submitImage(File image) async {
    // Simulate AI processing time.
    await Future.delayed(const Duration(seconds: 2));

    return const CropHealthResult(
      kind: 'crop_health',
      crop: 'tomato',
      label: 'possible_early_blight',
      confidence: 0.82,
      imageQuality: 'acceptable',
    );
  }

  @override
  Future<IrrigationOutcome> decideIrrigation({
    required bool approved,
    String requestedBy = 'farmer-app',
    int? maxRuntimeSec,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Demo only. No relay command is produced, because no backend recorded an
    // approval — a mock must not imply the pump was commanded.
    final request = IrrigationRequest(
      id: 'demo-request',
      status: approved ? 'approved' : 'declined',
      approvedBy: 'farmer',
      maxRuntimeSec: maxRuntimeSec,
    );
    return IrrigationOutcome(
      stage: approved ? IrrigationStage.approved : IrrigationStage.declined,
      request: request,
    );
  }
}
