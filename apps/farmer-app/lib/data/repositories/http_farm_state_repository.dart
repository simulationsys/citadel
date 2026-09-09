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
/// Endpoints used (see `services/edge-api/app/main.py` — the consolidated
/// Python edge API on port 3001, per docs/backend-integration.md's target
/// architecture; `apps/dashboard/backend` was deleted once this landed):
/// - `GET /health`
/// - `GET /v1/farm-state?zoneId=<zone>`
/// - `POST /v1/readings` (not used by UI yet)
/// - `POST /v1/crop-health?zoneId=<zone>` (multipart `image` field, runs the real crop-health AI model)
/// - `POST /v1/irrigation/requests` + `POST /v1/irrigation/requests/:id/approve` + `.../decline`
///   (records intent, then a human approval is the only thing that turns the pump on)
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
    // Edge API expects multipart/form-data with an `image` file field
    // (FastAPI `UploadFile = File(...)`), not a raw-bytes body.
    final uri = Uri.parse('$_root/v1/crop-health?zoneId=$zoneId');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', image.path));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
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
    // Records an irrigation request, then approves or declines it — the pump
    // only ever turns on because a human approved a specific request
    // (services/edge-api/app/main.py `/v1/irrigation/requests[...]`).
    // Failures are swallowed (queued offline, MVP behaviour).
    try {
      final createUri = Uri.parse('$_root/v1/irrigation/requests');
      final created = await http
          .post(createUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'zoneId': zoneId, 'requestedBy': 'farmer-app:$action'}))
          .timeout(timeout);
      if (created.statusCode != 201) return;
      final id = (jsonDecode(created.body) as Map)['request']?['id'] as String?;
      if (id == null) return;

      final decisionUri = Uri.parse(
          '$_root/v1/irrigation/requests/$id/${approved ? 'approve' : 'decline'}');
      await http
          .post(decisionUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'approvedBy': 'farmer'}))
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
