import 'dart:io';

import 'package:flutter/material.dart';

import '../models/farm_state.dart';
import '../models/crop_health_result.dart';

/// Abstract repository — the seam between mock and real backend.
/// Swap `MockFarmStateRepository` for `HttpFarmStateRepository` when the
/// edge API (Workstream 05) is live.
abstract class FarmStateRepository {
  /// Fetch the current farm state (reading + advisories).
  Future<FarmState> getFarmState();

  /// Submit a leaf/crop image for AI analysis.
  Future<CropHealthResult> submitImage(File image);

  /// Approve or decline an irrigation recommendation.
  Future<void> approveIrrigation(String action, {required bool approved});
}

/// Provider that wraps the repository and exposes state to the widget tree.
class FarmStateProvider extends ChangeNotifier {
  final FarmStateRepository _repository;

  FarmState? _farmState;
  CropHealthResult? _lastScanResult;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;

  FarmStateProvider(this._repository);

  // ── Getters ──────────────────────────────────────────────────────────

  FarmState? get farmState => _farmState;
  CropHealthResult? get lastScanResult => _lastScanResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetchTime => _lastFetchTime;

  /// Data freshness status.
  DataFreshness get freshness {
    if (_lastFetchTime == null) return DataFreshness.offline;
    final age = DateTime.now().difference(_lastFetchTime!);
    if (age.inMinutes < 2) return DataFreshness.live;
    if (age.inMinutes < 15) return DataFreshness.stale;
    return DataFreshness.offline;
  }

  // ── Actions ──────────────────────────────────────────────────────────

  /// Fetch latest farm state from the repository.
  Future<void> refreshFarmState() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _farmState = await _repository.getFarmState();
      _lastFetchTime = DateTime.now();
    } catch (e) {
      _error = e.toString();
      // Keep showing stale data — never blank the screen.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit an image for crop health scanning.
  Future<void> scanImage(File image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lastScanResult = await _repository.submitImage(image);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle irrigation approval/decline.
  Future<void> handleIrrigation(String action, {required bool approved}) async {
    try {
      await _repository.approveIrrigation(action, approved: approved);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

/// Represents how fresh the current data is.
enum DataFreshness { live, stale, offline }
