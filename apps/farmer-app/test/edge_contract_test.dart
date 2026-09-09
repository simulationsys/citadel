// Contract tests against the exact JSON shapes services/edge-api produces.
//
// Every fixture below is copied from the FastAPI response models in
// services/edge-api/app/schemas.py and app/main.py. If the backend changes
// shape, these fail — which is the point: the bugs these cover were all
// "backend fine, app fine, contract mismatched", and each failed silently.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citadel_farmer_app/data/models/crop_health_result.dart';
import 'package:citadel_farmer_app/data/models/farm_state.dart';
import 'package:citadel_farmer_app/data/models/irrigation_request.dart';
import 'package:citadel_farmer_app/data/models/reading.dart';
import 'package:citadel_farmer_app/data/repositories/http_farm_state_repository.dart';

const _base = 'http://192.168.1.31:3001';

/// A complete reading, as the ESP32 sends it.
Map<String, dynamic> completeReading() => {
      'id': 12,
      'eventId': 'field-node-01-000012',
      'deviceId': 'field-node-01',
      'zoneId': 'zone-a',
      'soilMoisturePct': 24.0,
      'temperatureC': 34.0,
      'humidityPct': 55.0,
      'rainfallMm': 0.0,
      'waterLevelPct': 12.0,
      'relayReported': 'OFF',
      'capturedAt': '2026-09-10T08:00:00+00:00',
      'receivedAt': '2026-09-10T08:00:01+00:00',
    };

/// The documented flood demo payload (docs/demo.md) — most sensors absent.
Map<String, dynamic> partialFloodReading() => {
      'id': 13,
      'deviceId': 'field-node-01',
      'zoneId': 'zone-a',
      'soilMoisturePct': null,
      'temperatureC': null,
      'humidityPct': null,
      'rainfallMm': 32.0,
      'waterLevelPct': 82.0,
      'capturedAt': '2026-09-10T08:05:00+00:00',
      'receivedAt': '2026-09-10T08:05:01+00:00',
    };

Map<String, dynamic> farmState({Map<String, dynamic>? reading, String freshness = 'live'}) => {
      'status': 'ok',
      'mode': 'offline-first-edge',
      'zoneId': 'zone-a',
      'reading': reading,
      'freshness': freshness,
      'observations': const [],
      'advisories': [
        {
          'type': 'flood',
          'severity': 'critical',
          'title': 'Flood risk',
          'message': 'Water level is high.',
          'action': 'CHECK_DRAINAGE',
          'evidence': {'waterLevelPct': 82.0},
        }
      ],
      'actuator': {
        'actuatorId': 'pump-relay-01',
        'zoneId': 'zone-a',
        'desiredState': 'OFF',
        'reportedState': null,
        'desiredAt': '2026-09-10T08:00:00+00:00',
        'reportedAt': null,
        'maxRuntimeSec': null,
        'inSync': true,
      },
      'pendingIrrigationRequests': const [],
      'relayState': 'OFF',
      'latestVision': null,
    };

HttpFarmStateRepository repo(MockClient client) =>
    HttpFarmStateRepository(baseUrl: _base, client: client);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Phase 4: partial payloads ──────────────────────────────────────

  group('reading parsing', () {
    test('parses a complete reading', () {
      final r = Reading.fromJson(completeReading());
      expect(r.soilMoisturePct, 24.0);
      expect(r.temperatureC, 34.0);
      expect(r.humidityPct, 55.0);
      expect(r.rainfallMm, 0.0);
      expect(r.waterLevelPct, 12.0);
      expect(r.relayReported, 'OFF');
      expect(r.reportedMetricCount, 5);
      expect(r.capturedAt, isNotNull);
      expect(r.receivedAt, isNotNull);
    });

    test('parses the partial flood payload without throwing', () {
      // The old model force-cast `(json['soilMoisturePct'] as num)`, so this
      // payload threw and the app silently fell back to mock data.
      final r = Reading.fromJson(partialFloodReading());
      expect(r.waterLevelPct, 82.0);
      expect(r.rainfallMm, 32.0);
      expect(r.soilMoisturePct, isNull);
      expect(r.temperatureC, isNull);
      expect(r.reportedMetricCount, 2);
    });

    test('missing sensors are null, never zero', () {
      final r = Reading.fromJson(partialFloodReading());
      expect(r.temperatureC, isNot(0.0));
      expect(r.hasTemperature, isFalse);
      expect(r.hasSoilMoisture, isFalse);
      expect(r.hasRainfall, isTrue);
      expect(r.hasWaterLevel, isTrue);
    });

    test('absent sensors render as -- not a stand-in number', () {
      expect(Reading.display(null), '--');
      expect(Reading.display(24.4), '24');
    });

    test('capturedAt stays null rather than being back-filled with now()', () {
      final r = Reading.fromJson({'deviceId': 'd', 'zoneId': 'zone-a'});
      expect(r.capturedAt, isNull);
    });
  });

  group('farm state parsing', () {
    test('null reading on cold start is a state, not a parse failure', () {
      final state = FarmState.fromJson(farmState(reading: null, freshness: 'offline'));
      expect(state.hasReading, isFalse);
      expect(state.reading, isNull);
      expect(state.freshness, DataFreshness.offline);
    });

    test('uses the server-provided freshness field', () {
      expect(FarmState.fromJson(farmState(reading: completeReading())).freshness,
          DataFreshness.live);
      expect(
          FarmState.fromJson(farmState(reading: completeReading(), freshness: 'stale'))
              .freshness,
          DataFreshness.stale);
    });

    test('cached payloads are never reported as live', () {
      final state = FarmState.fromJson(
          farmState(reading: completeReading(), freshness: 'live'),
          fromCache: true);
      expect(state.fromCache, isTrue);
      expect(state.freshness, DataFreshness.stale);
    });

    test('advisory keeps its evidence and the disease_risk vocabulary', () {
      final state = FarmState.fromJson(farmState(reading: completeReading()));
      expect(state.advisories.single.evidence['waterLevelPct'], 82.0);
    });
  });

  group('farm state fetching', () {
    test('network failure with a cache returns cached state marked stale', () async {
      final good = repo(MockClient((_) async =>
          http.Response(jsonEncode(farmState(reading: completeReading())), 200)));
      final first = await good.getFarmState();
      expect(first.fromCache, isFalse);

      final offline = repo(MockClient((_) async => throw const SocketException('down')));
      final cached = await offline.getFarmState();
      expect(cached.fromCache, isTrue);
      expect(cached.freshness, DataFreshness.stale);
      expect(cached.reading!.soilMoisturePct, 24.0);
    });

    test('network failure with no cache throws — it does not invent data', () async {
      final offline = repo(MockClient((_) async => throw const SocketException('down')));
      await expectLater(offline.getFarmState(), throwsA(isA<Exception>()));
    });

    test('malformed live response does not poison the cache', () async {
      final good = repo(MockClient((_) async =>
          http.Response(jsonEncode(farmState(reading: completeReading())), 200)));
      await good.getFarmState();

      final broken = repo(MockClient((_) async => http.Response('not json', 200)));
      final state = await broken.getFarmState();
      expect(state.fromCache, isTrue, reason: 'falls back to the last good payload');
      expect(state.reading!.soilMoisturePct, 24.0);
    });
  });

  // ── Phase 3: crop health ───────────────────────────────────────────

  group('crop scan', () {
    late File image;

    setUp(() async {
      image = File('${Directory.systemTemp.path}/leaf_test.jpg');
      await image.writeAsBytes(List<int>.filled(64, 7));
    });

    test('sends multipart with the field name the API declares', () async {
      String? contentType;
      String? body;
      final client = MockClient((request) async {
        contentType = request.headers['content-type'];
        body = request.body;
        return http.Response(
            jsonEncode({
              'result': {
                'kind': 'crop_health',
                'crop': 'tomato',
                'label': 'early_blight',
                'confidence': 0.93,
                'imageQuality': 'acceptable',
                'limitation': null,
              },
              'observation': {'id': 3},
              'state': farmState(reading: completeReading()),
            }),
            200);
      });
      await repo(client).submitImage(image);
      expect(contentType, contains('multipart/form-data'));
      // FastAPI declares `image: UploadFile = File(...)`.
      expect(body, contains('name="image"'));
    });

    test('parses the nested result envelope', () async {
      final client = MockClient((_) async => http.Response(
          jsonEncode({
            'result': {
              'kind': 'crop_health',
              'crop': 'tomato',
              'label': 'late_blight',
              'confidence': 0.88,
              'imageQuality': 'acceptable',
              '_latency_ms': 142.5,
              '_model_load_ms': 310.0,
              '_runtime': 'tflite_runtime',
            },
            'state': farmState(reading: completeReading()),
          }),
          200));
      final result = await repo(client).submitImage(image);
      expect(result.label, 'late_blight');
      expect(result.confidence, 0.88);
      expect(result.latencyMs, 142.5);
      expect(result.modelLoadMs, 310.0);
      expect(result.runtime, 'tflite_runtime');
    });

    test('low confidence is a legitimate inconclusive result', () async {
      final client = MockClient((_) async => http.Response(
          jsonEncode({
            'result': {
              'label': 'inconclusive',
              'confidence': 0.31,
              'imageQuality': 'acceptable',
              'limitation': 'Model confidence is too low.',
            }
          }),
          200));
      final result = await repo(client).submitImage(image);
      expect(result.isInconclusive, isTrue);
      expect(result.limitation, isNotNull);
    });

    test('a rejected photo asks for a recapture', () async {
      final client = MockClient((_) async => http.Response(
          jsonEncode({
            'result': {
              'label': 'invalid_image',
              'confidence': 0.0,
              'imageQuality': 'poor',
              'limitation': 'Image appears blurry.',
            }
          }),
          200));
      final result = await repo(client).submitImage(image);
      expect(result.isRejectedImage, isTrue);
      expect(result.limitation, contains('blurry'));
    });

    test('503 model unavailable throws — it is NOT an inconclusive result', () async {
      final client = MockClient((_) async => http.Response(
          jsonEncode({
            'detail': {'code': 'vision_unavailable', 'message': 'no tflite runtime'}
          }),
          503));
      await expectLater(
        repo(client).submitImage(image),
        throwsA(isA<CropScanException>().having(
            (e) => e.failure, 'failure', CropScanFailure.modelUnavailable)),
      );
    });

    test('502 bad model output throws', () async {
      final client = MockClient((_) async => http.Response('{"detail":"garbage"}', 502));
      await expectLater(
        repo(client).submitImage(image),
        throwsA(isA<CropScanException>().having(
            (e) => e.failure, 'failure', CropScanFailure.badModelOutput)),
      );
    });

    test('unreachable node throws networkUnavailable, never a fake diagnosis', () async {
      final client = MockClient((_) async => throw const SocketException('no route'));
      await expectLater(
        repo(client).submitImage(image),
        throwsA(isA<CropScanException>().having(
            (e) => e.failure, 'failure', CropScanFailure.networkUnavailable)),
      );
    });

    test('malformed 200 body throws rather than defaulting to inconclusive', () async {
      final client = MockClient((_) async => http.Response('<html>oops</html>', 200));
      await expectLater(
        repo(client).submitImage(image),
        throwsA(isA<CropScanException>().having(
            (e) => e.failure, 'failure', CropScanFailure.malformedResponse)),
      );
    });

    test('farmer-facing copy for an unavailable model never implies a diagnosis', () {
      const e = CropScanException(CropScanFailure.modelUnavailable, 'x');
      expect(e.farmerMessage, contains('not available'));
      expect(e.farmerMessage.toLowerCase(), isNot(contains('inconclusive')));
    });
  });

  // ── Phase 5: irrigation ────────────────────────────────────────────

  group('irrigation lifecycle', () {
    // The create response is FLAT — this is the shape the app used to look for
    // `['request']['id']` in, get null, and silently give up.
    Map<String, dynamic> createdFlat() => {
          'id': 'irrigation-abc123',
          'zoneId': 'zone-a',
          'requestedBy': 'farmer-app',
          'status': 'pending',
          'approvedBy': null,
          'createdAt': '2026-09-10T08:10:00+00:00',
          'approvedAt': null,
          'maxRuntimeSec': null,
        };

    Map<String, dynamic> approvedWrapped() => {
          'request': {
            ...createdFlat(),
            'status': 'approved',
            'approvedBy': 'farmer',
            'approvedAt': '2026-09-10T08:10:05+00:00',
            'maxRuntimeSec': 900,
          },
          'actuator': {'desiredState': 'ON'},
          'command': {
            'actuatorId': 'pump-relay-01',
            'relayState': 'ON',
            'maxRuntimeSec': 900,
          },
          'note': 'Approval is recorded.',
        };

    test('parses the flat creation response', () {
      final request = IrrigationRequest.fromAny(createdFlat());
      expect(request, isNotNull);
      expect(request!.id, 'irrigation-abc123');
      expect(request.isPending, isTrue);
    });

    test('also parses the wrapped approve response', () {
      final request = IrrigationRequest.fromAny(approvedWrapped());
      expect(request!.id, 'irrigation-abc123');
      expect(request.isApproved, isTrue);
    });

    test('approval calls approve with the id from the flat create body', () async {
      final calls = <String>[];
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/approve')) {
          return http.Response(jsonEncode(approvedWrapped()), 200);
        }
        return http.Response(jsonEncode(createdFlat()), 201);
      });

      final outcome = await repo(client).decideIrrigation(approved: true);
      expect(calls, [
        'POST /v1/irrigation/requests',
        'POST /v1/irrigation/requests/irrigation-abc123/approve',
      ]);
      expect(outcome.stage, IrrigationStage.approved);
      expect(outcome.commandAvailable, isTrue);
      expect(outcome.command!.maxRuntimeSec, 900);
    });

    test('decline calls decline and yields no relay command', () async {
      final calls = <String>[];
      final client = MockClient((request) async {
        calls.add(request.url.path);
        if (request.url.path.endsWith('/decline')) {
          return http.Response(
              jsonEncode({
                'request': {...createdFlat(), 'status': 'declined'},
                'note': 'Declined. The pump was not commanded.',
              }),
              200);
        }
        return http.Response(jsonEncode(createdFlat()), 201);
      });

      final outcome = await repo(client).decideIrrigation(approved: false);
      expect(calls.last, endsWith('/decline'));
      expect(outcome.stage, IrrigationStage.declined);
      expect(outcome.command, isNull);
      expect(outcome.commandAvailable, isFalse);
    });

    test('404 on approve surfaces, never reports success', () async {
      final client = MockClient((request) async =>
          request.url.path.endsWith('/approve')
              ? http.Response('{"detail":"Irrigation request not found."}', 404)
              : http.Response(jsonEncode(createdFlat()), 201));
      await expectLater(
        repo(client).decideIrrigation(approved: true),
        throwsA(isA<IrrigationException>()
            .having((e) => e.statusCode, 'status', 404)),
      );
    });

    test('409 already-decided surfaces', () async {
      final client = MockClient((request) async =>
          request.url.path.endsWith('/approve')
              ? http.Response('{"detail":"Request is already approved."}', 409)
              : http.Response(jsonEncode(createdFlat()), 201));
      await expectLater(
        repo(client).decideIrrigation(approved: true),
        throwsA(isA<IrrigationException>()
            .having((e) => e.farmerMessage, 'copy', contains('already'))),
      );
    });

    test('backend unavailable surfaces and says NOT approved', () async {
      final client = MockClient((_) async => throw const SocketException('down'));
      await expectLater(
        repo(client).decideIrrigation(approved: true),
        throwsA(isA<IrrigationException>()
            .having((e) => e.farmerMessage, 'copy', contains('NOT approved'))),
      );
    });

    test('a 200 that does not confirm approval is treated as failure', () async {
      // Defends the promise that matters most: never tell a farmer the pump
      // was approved unless the backend said `status: approved`.
      final client = MockClient((request) async =>
          request.url.path.endsWith('/approve')
              ? http.Response(jsonEncode({'request': createdFlat()}), 200)
              : http.Response(jsonEncode(createdFlat()), 201));
      await expectLater(repo(client).decideIrrigation(approved: true),
          throwsA(isA<IrrigationException>()));
    });

    test('malformed create response fails loudly', () async {
      final client = MockClient((_) async => http.Response('{}', 201));
      await expectLater(repo(client).decideIrrigation(approved: true),
          throwsA(isA<IrrigationException>()));
    });

    test('timeout surfaces', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response(jsonEncode(createdFlat()), 201);
      });
      final slow = HttpFarmStateRepository(
          baseUrl: _base,
          client: client,
          timeout: const Duration(milliseconds: 20));
      await expectLater(slow.decideIrrigation(approved: true),
          throwsA(isA<IrrigationException>()));
    });
  });
}
