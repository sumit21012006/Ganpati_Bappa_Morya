import 'dart:io';

/// Signature capture result.
///
/// IMPORTANT (Member 6 integration point): a drawn signature in this
/// prototype is a UI demonstration ONLY — it is NOT a legally valid
/// eMudhra digital signature. The final integration will replace the
/// drawn-PNG artifact with an eMudhra DSC token via the backend.
class SignatureResult {
  const SignatureResult({
    required this.id,
    required this.imagePath,
    required this.signedAt,
    required this.signerName,
    required this.isElectronicDrawing,
  });

  final String id;
  final String imagePath;
  final DateTime signedAt;
  final String signerName;

  /// Always true for the prototype; false once eMudhra DSC is integrated.
  final bool isElectronicDrawing;

  File get file => File(imagePath);
}

/// Request to sign and issue a notice.
class SignNoticeRequest {
  const SignNoticeRequest({
    required this.noticeId,
    required this.signerName,
    required this.signatureImagePath,
  });

  final String noticeId;
  final String signerName;
  final String signatureImagePath;
}
