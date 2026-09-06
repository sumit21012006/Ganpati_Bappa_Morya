/// Typed application errors with human-readable messages.
///
/// UI layers must NEVER show stack traces — always surface
/// [AppException.friendlyMessage] (optionally with a Retry action).
sealed class AppException implements Exception {
  const AppException(this.friendlyMessage, {this.code});

  /// Human-readable, judge-presentable message. No stack traces.
  final String friendlyMessage;

  /// Optional machine-readable code for logging/telemetry.
  final String? code;

  @override
  String toString() => friendlyMessage;
}

/// Network unreachable / device offline.
class NetworkException extends AppException {
  const NetworkException([
    super.friendlyMessage =
        'No internet connection. Please check your network settings and try again.',
  ]);
}

/// Server unreachable, timeout, or 5xx.
class ServerException extends AppException {
  const ServerException(super.friendlyMessage, {super.code});
}

/// 401 — session expired or invalid token.
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.friendlyMessage = 'Your session has expired. Please sign in again.',
  ]);
}

/// 403 — role not permitted for this capability.
class ForbiddenException extends AppException {
  const ForbiddenException([
    super.friendlyMessage =
        'You do not have permission to perform this action. '
        'If you believe this is a mistake, contact the controlling authority.',
  ]);
}

/// 404 — resource not found.
class NotFoundException extends AppException {
  const NotFoundException([
    super.friendlyMessage = 'The requested record could not be found.',
  ]);
}

/// 422/validation failure or business rule rejection.
class ValidationException extends AppException {
  const ValidationException(super.friendlyMessage, {super.code});
}

/// Image capture/upload failed.
class EvidenceUploadException extends AppException {
  const EvidenceUploadException(super.friendlyMessage);
}

/// OCR/AI pipeline failure (upload, processing, or extraction).
class OcrException extends AppException {
  const OcrException(super.friendlyMessage);
}

/// Notice generation/NLP failure.
class NoticeGenerationException extends AppException {
  const NoticeGenerationException(super.friendlyMessage);
}

/// Payment initiation/status failure. Backend webhook remains the
/// source of truth for success — the app never marks payment success itself.
class PaymentException extends AppException {
  const PaymentException(super.friendlyMessage);
}

/// Signature flow failure.
class SignatureException extends AppException {
  const SignatureException(super.friendlyMessage);
}

/// Camera permission denied / permanently denied / unavailable.
class CameraPermissionException extends AppException {
  const CameraPermissionException(super.friendlyMessage);
}

/// Anything unexpected. Message stays human-readable.
class UnknownException extends AppException {
  const UnknownException([
    super.friendlyMessage =
        'Something went wrong. Please try again. If the problem persists, '
        'contact technical support.',
  ]);
}
