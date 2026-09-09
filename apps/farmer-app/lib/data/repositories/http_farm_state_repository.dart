import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/crop_health_result.dart';
import '../models/farm_state.dart';
import '../models/irrigation_request.dart';
import 'farm_state_repository.dart';

/// Talks to the consolidated Python edge API (`services/edge-api`, port 3001)
/// over the LAN.
///
/// Endpoints used:
/// - `GET  /health`
/// - `GET  /v1/farm-state?zoneId=<zone>`
/// - `POST /v1/crop-health?zoneId=<zone>` — multipart, field name `image`
/// - `POST /v1/irrigation/requests` → flat request object
/// - `POST /v1/irrigation/requests/{id}/approve` | `/decline`
///
/// **Offline policy.** Farm state falls back to the last cached payload, marked
/// `fromCache` so the UI can label it stale. Crop scans and irrigation
/// decisions do **not** fall back — they throw. There is no honest offline
/// answer to "what disease is this?" or "did the pump turn on?", and inventing
/// one is worse than an error message.
class HttpFarmStateRepository implements FarmStateRepository {
  static const _kCacheKey = 'cached_farm_state_json';

  final String baseUrl;
  final String zoneId;
  final Duration timeout;
  final http.Client _client;

  HttpFarmStateRepository({
    required this.baseUrl,
    this.zoneId = 'zone-a',
    this.timeout = const Duration(seconds: 6),
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get _root => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  // ── Farm state ───────────────────────────────────────────────────────

  @override
  Future<FarmState> getFarmState() async {
    try {
      final uri = Uri.parse('$_root/v1/farm-state?zoneId=$zoneId');
      final res = await _client.get(uri).timeout(timeout);
      if (res.statusCode != 200) {
        throw HttpException('farm-state ${res.statusCode}');
      }
      final body = jsonDecode(res.body);
      if (body is! Map) throw const FormatException('farm-state body is not an object');
      // Parse before caching: never cache a payload we could not read.
      final state = FarmState.fromJson(body.cast<String, dynamic>());
      await _saveCache(res.body);
      return state;
    } catch (_) {
      final cached = await _loadCache();
      if (cached != null) return cached;
      rethrow;
    }
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
      final body = jsonDecode(raw);
      if (body is! Map) return null;
      // fromCache forces freshness to stale regardless of what the server said
      // when this was captured.
      return FarmState.fromJson(body.cast<String, dynamic>(), fromCache: true);
    } catch (_) {
      return null;
    }
  }

  // ── Crop health ──────────────────────────────────────────────────────

  @override
  Future<CropHealthResult> submitImage(File image) async {
    final uri = Uri.parse('$_root/v1/crop-health?zoneId=$zoneId');
    http.Response res;
    try {
      // FastAPI declares `image: UploadFile = File(...)`, so this must be a
      // multipart form with the field named `image` — not raw JPEG bytes.
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', image.path));
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 40));
      res = await http.Response.fromStream(streamed);
    } on TimeoutException catch (e) {
      throw CropScanException(CropScanFailure.timeout, '$e');
    } on SocketException catch (e) {
      throw CropScanException(CropScanFailure.networkUnavailable, '$e');
    } on http.ClientException catch (e) {
      throw CropScanException(CropScanFailure.networkUnavailable, '$e');
    }

    switch (res.statusCode) {
      case 200:
        break;
      case 503:
        throw CropScanException(CropScanFailure.modelUnavailable,
            _detail(res.body), statusCode: 503);
      case 502:
        throw CropScanException(CropScanFailure.badModelOutput,
            _detail(res.body), statusCode: 502);
      case 504:
        throw CropScanException(CropScanFailure.timeout,
            _detail(res.body), statusCode: 504);
      default:
        throw CropScanException(CropScanFailure.serverError,
            'HTTP ${res.statusCode}: ${_detail(res.body)}',
            statusCode: res.statusCode);
    }

    try {
      final body = jsonDecode(res.body);
      if (body is! Map) throw const FormatException('not an object');
      return CropHealthResult.fromJson(body.cast<String, dynamic>());
    } catch (e) {
      throw CropScanException(CropScanFailure.malformedResponse, '$e', statusCode: 200);
    }
  }

  /// FastAPI puts our structured errors under `detail`.
  static String _detail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        if (detail is Map && detail['message'] != null) return '${detail['message']}';
        return '$detail';
      }
    } catch (_) {
      // fall through to the raw body
    }
    return body.length > 300 ? body.substring(0, 300) : body;
  }

  // ── Irrigation ───────────────────────────────────────────────────────

  @override
  Future<IrrigationOutcome> decideIrrigation({required bool approved,
      String requestedBy = 'farmer-app', int? maxRuntimeSec}) async {
    final request = await createIrrigationRequest(
        requestedBy: requestedBy, maxRuntimeSec: maxRuntimeSec);
    return approved
        ? approveIrrigationRequest(request.id, maxRuntimeSec: maxRuntimeSec)
        : declineIrrigationRequest(request.id);
  }

  Future<IrrigationRequest> createIrrigationRequest(
      {String requestedBy = 'farmer-app', int? maxRuntimeSec}) async {
    final res = await _postJson('$_root/v1/irrigation/requests', {
      'zoneId': zoneId,
      'requestedBy': requestedBy,
      if (maxRuntimeSec != null) 'maxRuntimeSec': maxRuntimeSec,
    });
    if (res.statusCode != 201) {
      throw IrrigationException('create returned ${res.statusCode}: ${_detail(res.body)}',
          statusCode: res.statusCode);
    }
    // The create response is FLAT. fromAny also accepts the wrapped shape so
    // this cannot silently break again if the contract is ever normalised.
    final request = IrrigationRequest.fromAny(_decode(res.body));
    if (request == null) {
      throw const IrrigationException('create response contained no request id');
    }
    return request;
  }

  Future<IrrigationOutcome> approveIrrigationRequest(String id,
      {int? maxRuntimeSec}) async {
    final res = await _postJson('$_root/v1/irrigation/requests/$id/approve', {
      'approvedBy': 'farmer',
      if (maxRuntimeSec != null) 'maxRuntimeSec': maxRuntimeSec,
    });
    if (res.statusCode != 200) {
      throw IrrigationException('approve returned ${res.statusCode}: ${_detail(res.body)}',
          statusCode: res.statusCode);
    }
    final body = _decode(res.body);
    final request = IrrigationRequest.fromAny(body);
    // Only report approval if the backend actually says approved.
    if (request == null || !request.isApproved) {
      throw const IrrigationException(
          'approve succeeded but the request is not in the approved state');
    }
    return IrrigationOutcome(
      stage: IrrigationStage.approved,
      request: request,
      command: RelayCommand.fromJson(
          body is Map ? body.cast<String, dynamic>()['command'] : null),
    );
  }

  Future<IrrigationOutcome> declineIrrigationRequest(String id) async {
    final res = await _postJson('$_root/v1/irrigation/requests/$id/decline', {
      'approvedBy': 'farmer',
    });
    if (res.statusCode != 200) {
      throw IrrigationException('decline returned ${res.statusCode}: ${_detail(res.body)}',
          statusCode: res.statusCode);
    }
    final request = IrrigationRequest.fromAny(_decode(res.body));
    if (request == null || !request.isDeclined) {
      throw const IrrigationException(
          'decline succeeded but the request is not in the declined state');
    }
    return IrrigationOutcome(stage: IrrigationStage.declined, request: request);
  }

  Future<http.Response> _postJson(String url, Map<String, dynamic> body) async {
    try {
      return await _client
          .post(Uri.parse(url),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(timeout);
    } on TimeoutException catch (e) {
      throw IrrigationException('timeout contacting edge node: $e');
    } on SocketException catch (e) {
      throw IrrigationException('edge node unreachable: $e');
    } on http.ClientException catch (e) {
      throw IrrigationException('edge node unreachable: $e');
    }
  }

  static dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException catch (e) {
      throw IrrigationException('unreadable response: $e');
    }
  }

  // ── Diagnostics ──────────────────────────────────────────────────────

  /// Settings → Test Connection.
  Future<String> testConnection() async {
    final res = await _client.get(Uri.parse('$_root/health'))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final model = body['modelStatus']?['cropHealth']?['available'] == true
          ? 'crop AI ready'
          : 'crop AI unavailable';
      return 'Connected — ${body['service']} (${body['mode']}, $model)';
    }
    return 'Responded with status ${res.statusCode}';
  }
}
