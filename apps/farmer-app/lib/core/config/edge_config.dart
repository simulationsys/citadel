import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Holds the edge-API connection settings so a physical phone on the same
/// Wi-Fi as the laptop/edge node can talk to it.
///
/// Persisted in SharedPreferences under `edge_base_url` / `edge_zone_id`.
/// Defaults to [AppConstants.defaultEdgeApiUrl] (`http://localhost:3001`,
/// which works on emulators; on a real phone set e.g.
/// `http://192.168.1.10:3001` via Settings).
class EdgeConfig extends ChangeNotifier {
  static const _kBaseUrl = 'edge_base_url';
  static const _kZoneId = 'edge_zone_id';

  String _baseUrl = AppConstants.defaultEdgeApiUrl;
  String _zoneId = 'zone-a';
  bool _loaded = false;

  String get baseUrl => _baseUrl;
  String get zoneId => _zoneId;
  bool get loaded => _loaded;

  /// Normalised base URL without trailing slash.
  String get normalizedBaseUrl =>
      _baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_kBaseUrl) ?? AppConstants.defaultEdgeApiUrl;
    _zoneId = prefs.getString(_kZoneId) ?? 'zone-a';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, _baseUrl);
    notifyListeners();
  }

  Future<void> setZoneId(String zoneId) async {
    _zoneId = zoneId.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kZoneId, _zoneId);
    notifyListeners();
  }
}
