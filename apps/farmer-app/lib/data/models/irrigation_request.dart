/// Irrigation request lifecycle.
///
/// Canonical contract (`services/edge-api/app/main.py`, `/openapi.json`):
///
/// * `POST /v1/irrigation/requests` → **flat** `IrrigationRequestResponse`:
///   `{ "id": "irrigation-...", "zoneId": ..., "status": "pending", ... }`
/// * `POST /v1/irrigation/requests/{id}/approve` → **wrapped**:
///   `{ "request": {...}, "actuator": {...}, "command": {...} }`
/// * `POST /v1/irrigation/requests/{id}/decline` → `{ "request": {...}, "note": ... }`
///
/// The app previously read `body['request']['id']` from the *create* response,
/// which is flat — so the id was always null and approval was never sent, in
/// silence. [IrrigationRequest.fromAny] accepts either shape so neither side of
/// that asymmetry can break the flow again.
class IrrigationRequest {
  final String id;
  final String zoneId;
  final String requestedBy;
  final String status; // pending | approved | declined
  final String? approvedBy;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final int? maxRuntimeSec;

  const IrrigationRequest({
    required this.id,
    this.zoneId = 'zone-a',
    this.requestedBy = 'farmer',
    this.status = 'pending',
    this.approvedBy,
    this.createdAt,
    this.approvedAt,
    this.maxRuntimeSec,
  });

  /// Accepts the flat create response or the wrapped approve/decline response.
  static IrrigationRequest? fromAny(dynamic body) {
    if (body is! Map) return null;
    final map = body.cast<String, dynamic>();
    final source = map['request'] is Map
        ? (map['request'] as Map).cast<String, dynamic>()
        : map;
    final id = source['id'];
    if (id is! String || id.isEmpty) return null;
    return IrrigationRequest(
      id: id,
      zoneId: source['zoneId'] as String? ?? 'zone-a',
      requestedBy: source['requestedBy'] as String? ?? 'farmer',
      status: source['status'] as String? ?? 'pending',
      approvedBy: source['approvedBy'] as String?,
      createdAt: DateTime.tryParse(source['createdAt'] as String? ?? ''),
      approvedAt: DateTime.tryParse(source['approvedAt'] as String? ?? ''),
      maxRuntimeSec: (source['maxRuntimeSec'] as num?)?.toInt(),
    );
  }

  bool get isApproved => status == 'approved';
  bool get isDeclined => status == 'declined';
  bool get isPending => status == 'pending';
}

/// The relay downlink the backend will hand the ESP32 on its next reading.
class RelayCommand {
  final String actuatorId;
  final String relayState; // ON | OFF
  final int maxRuntimeSec;

  const RelayCommand({
    required this.actuatorId,
    required this.relayState,
    required this.maxRuntimeSec,
  });

  static RelayCommand? fromJson(dynamic body) {
    if (body is! Map) return null;
    final map = body.cast<String, dynamic>();
    final state = map['relayState'];
    if (state is! String) return null;
    return RelayCommand(
      actuatorId: map['actuatorId'] as String? ?? 'unknown',
      relayState: state,
      maxRuntimeSec: (map['maxRuntimeSec'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isOn => relayState == 'ON';
}

/// Where an irrigation decision got to. These are deliberately separate states:
/// "the farmer tapped approve" and "the backend recorded an approval" are not
/// the same fact, and the farmer must only ever be told the second one.
enum IrrigationStage {
  /// An advisory suggests irrigation; nothing has been requested.
  recommended,

  /// Create call in flight — the UI disables repeat taps here.
  creating,

  /// Request exists, awaiting the farmer's decision.
  pending,

  /// Backend confirmed the approval and set desired state ON.
  approved,

  /// Backend confirmed the decline; desired state stays OFF.
  declined,

  /// Something failed. `error` explains what.
  failed,
}

/// Result of a full create-then-decide cycle.
class IrrigationOutcome {
  final IrrigationStage stage;
  final IrrigationRequest? request;
  final RelayCommand? command;
  final String? error;

  const IrrigationOutcome({
    required this.stage,
    this.request,
    this.command,
    this.error,
  });

  /// True only when the backend confirmed an approval **and** returned a
  /// standing ON command. The pump has not physically run at this point — the
  /// node still has to collect the command and acknowledge it.
  bool get commandAvailable => stage == IrrigationStage.approved && (command?.isOn ?? false);

  bool get isFailure => stage == IrrigationStage.failed;
}

/// Raised when the irrigation lifecycle could not complete. Never swallowed:
/// telling a farmer irrigation was approved when it was not is the worst
/// failure this app can have.
class IrrigationException implements Exception {
  final String message;
  final int? statusCode;

  const IrrigationException(this.message, {this.statusCode});

  String get farmerMessage {
    switch (statusCode) {
      case 404:
        return 'That irrigation request no longer exists. Please try again.';
      case 409:
        return 'That request was already decided.';
      default:
        return 'Could not reach your field node. Irrigation was NOT approved.';
    }
  }

  @override
  String toString() => 'IrrigationException($message, status=$statusCode)';
}
