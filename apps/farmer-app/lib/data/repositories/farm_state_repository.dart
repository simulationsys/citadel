import 'dart:io';

import 'package:flutter/material.dart';

import '../models/crop_health_result.dart';
import '../models/farm_state.dart';
import '../models/irrigation_request.dart';
import '../models/farm_analytics_report.dart';
import '../models/farm_assistant_response.dart';

// DataFreshness moved to models/farm_state.dart (it describes the payload, not
// the repository). Re-exported so existing `import ...farm_state_repository.dart`
// call sites keep resolving it.
export '../models/farm_state.dart' show DataFreshness, freshnessFromString;

/// The seam between the live edge API and the demo mock.
abstract class FarmStateRepository {
  /// Fetch the current farm state (reading + advisories).
  Future<FarmState> getFarmState();

  /// Submit a leaf image for AI analysis.
  ///
  /// Throws [CropScanException] when no inference could run. Implementations
  /// must not fabricate a result.
  Future<CropHealthResult> submitImage(File image);

  /// Create an irrigation request and immediately approve or decline it.
  ///
  /// Throws [IrrigationException] on any failure. Implementations must never
  /// report success the backend did not confirm.
  Future<IrrigationOutcome> decideIrrigation({
    required bool approved,
    String requestedBy,
    int? maxRuntimeSec,
  });

  /// Analyze locally stored sensor and crop history on the edge node.
  Future<FarmAnalyticsReport> analyzeFarm({int hours = 168});

  /// Ask the optional online assistant. This must never affect local features.
  Future<FarmAssistantResponse> askAssistant(String question, String language);
}

/// Exposes repository state to the widget tree.
class FarmStateProvider extends ChangeNotifier {
  FarmStateRepository _repository;

  FarmState? _farmState;
  CropHealthResult? _lastScanResult;
  CropScanException? _lastScanError;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  DateTime? _lastFetchTime;

  IrrigationStage _irrigationStage = IrrigationStage.recommended;
  IrrigationOutcome? _lastIrrigationOutcome;
  String? _irrigationError;
  FarmAnalyticsReport? _analyticsReport;
  bool _isAnalyzingFarm = false;
  String? _analyticsError;

  /// True when this provider is knowingly serving demo data.
  final bool isDemoMode;

  FarmStateProvider(this._repository, {this.isDemoMode = false});

  void updateRepository(FarmStateRepository repository) {
    _repository = repository;
  }

  // ── Getters ──────────────────────────────────────────────────────────

  FarmState? get farmState => _farmState;
  CropHealthResult? get lastScanResult => _lastScanResult;
  CropScanException? get lastScanError => _lastScanError;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get error => _error;
  DateTime? get lastFetchTime => _lastFetchTime;

  IrrigationStage get irrigationStage => _irrigationStage;
  IrrigationOutcome? get lastIrrigationOutcome => _lastIrrigationOutcome;
  String? get irrigationError => _irrigationError;
  FarmAnalyticsReport? get analyticsReport => _analyticsReport;
  bool get isAnalyzingFarm => _isAnalyzingFarm;
  String? get analyticsError => _analyticsError;

  /// A decision is in flight — the UI disables repeat taps on this.
  bool get isIrrigationBusy => _irrigationStage == IrrigationStage.creating;

  /// Freshness as judged by the **edge API**, falling back to elapsed time
  /// since the last successful fetch only when no state has ever arrived.
  ///
  /// Server-side is authoritative: a fast response can still carry hours-old
  /// sensor data, which a client-side timer cannot see.
  DataFreshness get freshness {
    final state = _farmState;
    if (state == null) return DataFreshness.offline;
    if (state.fromCache) return DataFreshness.stale;
    return state.freshness;
  }

  /// True when the visible reading came from the on-device cache.
  bool get isShowingCachedData => _farmState?.fromCache ?? false;

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> refreshFarmState() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _farmState = await _repository.getFarmState();
      _lastFetchTime = DateTime.now();
    } catch (e) {
      _error = e.toString();
      // Keep showing the previous state — but it stays marked stale/cached.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Run a crop scan. On failure [lastScanError] is set and [lastScanResult]
  /// is cleared — the UI must show the error, not a stale or invented result.
  Future<void> scanImage(File image) async {
    _isScanning = true;
    _isLoading = true;
    _lastScanError = null;
    _error = null;
    notifyListeners();

    try {
      _lastScanResult = await _repository.submitImage(image);
    } on CropScanException catch (e) {
      _lastScanError = e;
      _lastScanResult = null;
      _error = e.farmerMessage;
    } catch (e) {
      _lastScanError = CropScanException(CropScanFailure.serverError, '$e');
      _lastScanResult = null;
      _error = _lastScanError!.farmerMessage;
    } finally {
      _isScanning = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create and decide an irrigation request.
  ///
  /// Returns true only when the backend confirmed the decision. Repeat taps
  /// while a decision is in flight are ignored.
  Future<bool> handleIrrigation({required bool approved, int? maxRuntimeSec}) async {
    if (_irrigationStage == IrrigationStage.creating) return false;

    _irrigationStage = IrrigationStage.creating;
    _irrigationError = null;
    notifyListeners();

    try {
      final outcome = await _repository.decideIrrigation(
          approved: approved, maxRuntimeSec: maxRuntimeSec);
      _lastIrrigationOutcome = outcome;
      _irrigationStage = outcome.stage;
      notifyListeners();
      // The advisory set and actuator state both change on approval.
      await refreshFarmState();
      return outcome.stage == IrrigationStage.approved ||
          outcome.stage == IrrigationStage.declined;
    } on IrrigationException catch (e) {
      _irrigationStage = IrrigationStage.failed;
      _irrigationError = e.farmerMessage;
      _lastIrrigationOutcome =
          IrrigationOutcome(stage: IrrigationStage.failed, error: e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _irrigationStage = IrrigationStage.failed;
      _irrigationError = 'Irrigation was NOT approved: $e';
      notifyListeners();
      return false;
    }
  }

  void resetIrrigation() {
    _irrigationStage = IrrigationStage.recommended;
    _irrigationError = null;
    notifyListeners();
  }

  Future<bool> analyzeFarm({int hours = 168}) async {
    if (_isAnalyzingFarm) return false;
    _isAnalyzingFarm = true;
    _analyticsError = null;
    notifyListeners();
    try {
      _analyticsReport = await _repository.analyzeFarm(hours: hours);
      return true;
    } catch (error) {
      _analyticsError = 'Could not generate the farm report: $error';
      return false;
    } finally {
      _isAnalyzingFarm = false;
      notifyListeners();
    }
  }

  Future<FarmAssistantResponse> askAssistant(String question, String language) =>
      _repository.askAssistant(question, language);
}
