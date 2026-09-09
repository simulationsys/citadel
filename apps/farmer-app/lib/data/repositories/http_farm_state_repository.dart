import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/advisory.dart';
import '../models/crop_health_result.dart';
import '../models/farm_state.dart';
import '../models/reading.dart';
import 'farm_state_repository.dart';

/// HTTP implementation that talks to the edge API over the LAN so a physical
/// phone can stay "connected with phone".
///
/// Endpoints used (see `apps/dashboard/backend/main.py` — the Python
/// dashboard backend, which is what the ESP32 field node actually posts
/// sensor readings to; the older Node `services/edge-api` is not wired to
/// the ESP32 and isn't used by the app either — see docs/backend-integration.md):
/// - `GET /health`
/// - `GET /v1/farm-state?zoneId=<zone>`
/// - `POST /v1/readings` (not used by UI yet)
/// - `POST /v1/crop-health?zoneId=<zone>` (raw JPEG bytes, runs the real crop-health AI model)
/// - `POST /v1/actuator-command` (direct relay command — no separate approve step on this backend)
///
/// Offline-first: the last good `FarmState` JSON is cached in
/// SharedPreferences. On fetch failure the cached state is returned instead
/// of throwing, so the UI never goes blank.
class HttpFarmStateRepository implements FarmStateRepository {
  static const _kCacheKey = 'cached_farm_state_json';

  final String baseUrl;
  final String zoneId;
  final Duration timeout;

  HttpFarmStateRepository({
    required this.baseUrl,
    this.zoneId = 'zone-a',
    this.timeout = const Duration(seconds: 6),
  });

  String get _root => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  @override
  Future<FarmState> getFarmState() async {
    try {
      final uri = Uri.parse('$_root/v1/farm-state?zoneId=$zoneId');
      final res = await http.get(uri).timeout(timeout);
      if (res.statusCode != 200) throw HttpException('farm-state ${res.statusCode}');
      final Map<String, dynamic> body = jsonDecode(res.body) as Map<String, dynamic>;
      final state = _farmStateFromEdge(body);
      await _saveCache(res.body);
      return state;
    } catch (_) {
      final cached = await _loadCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Parse edge `farm-state` shape:
  /// `{ zoneId, reading: {...}, advisories: [...], ... }`
  FarmState _farmStateFromEdge(Map<String, dynamic> body) {
    final readingJson = body['reading'] as Map<String, dynamic>? ?? body;
    final advisoriesJson = (body['advisories'] as List<dynamic>?) ?? const [];
    // Edge `capturedAt` may be missing on reading — tolerate it.
    if (readingJson['capturedAt'] == null) {
      readingJson['capturedAt'] = DateTime.now().toIso8601String();
    }
    return FarmState(
      reading: Reading.fromJson(readingJson),
      advisories: advisoriesJson
          .map((e) => Advisory.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<void> _saveCache(String rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCacheKey, rawJson);
    } catch (_) {
      // Cache is best-effort.
    }
  }

  Future<FarmState?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCacheKey);
      if (raw == null) return null;
      final body = jsonDecode(raw) as Map<String, dynamic>;
      // Cached payload may be the full edge body or just reading+advisories.
      if (body['reading'] != null) return _farmStateFromEdge(body);
      return FarmState.fromJson(body);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CropHealthResult> submitImage(File image) async {
    final bytes = await image.readAsBytes();
    final uri = Uri.parse('$_root/v1/crop-health?zoneId=$zoneId');
    try {
      final res = await http
          .post(uri, headers: {'Content-Type': 'image/jpeg'}, body: bytes)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return CropHealthResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw HttpException('crop-health ${res.statusCode}: ${res.body}');
    } catch (_) {
      // Offline fallback: simulate a result after a short delay so the
      // scan flow still works in the field.
      await Future.delayed(const Duration(seconds: 1));
      return const CropHealthResult(
        crop: 'unknown',
        label: 'inconclusive',
        confidence: 0.0,
        imageQuality: 'poor',
      );
    }
  }

  @override
  Future<void> approveIrrigation(String action, {required bool approved}) async {
    // Talks to the Python backend's single actuator-command endpoint
    // (apps/dashboard/backend/main.py `POST /v1/actuator-command`) — there's
    // no separate create-then-approve request flow on this backend, just a
    // direct relay command. Approved -> start the pump; declined -> make
    // sure it's off. Failures are swallowed (queued offline, MVP behaviour).
    try {
      final uri = Uri.parse('$_root/v1/actuator-command');
      await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'actuatorId': 'pump-relay-01',
                'action': approved ? 'START_IRRIGATION' : 'STOP_IRRIGATION',
                'requestedBy': 'farmer-app:$action',
              }))
          .timeout(timeout);
    } catch (_) {
      // Offline — action stays queued locally (no-op for MVP).
    }
  }

  /// Lightweight connectivity probe used by Settings → Test Connection.
  Future<String> testConnection() async {
    final uri = Uri.parse('$_root/health');
    final res = await http.get(uri).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return 'Connected — ${body['service']} (${body['mode']})';
    }
    return 'Responded with status ${res.statusCode}';
  }
}
