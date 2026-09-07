import '../models/signature.dart';

/// Signature capability abstraction.
///
/// PROTOTYPE: `MockSignatureService` accepts a drawn signature PNG and
/// returns it as a demonstration artifact. It is NOT a legally valid
/// eMudhra signature.
///
/// MEMBER 6 INTEGRATION POINT: implement [SignatureService] with eMudhra
/// (DSC / eSign) — the UI flow stays identical: capture → verify → attach
/// → issue. The service interface is intentionally minimal so the drawn
/// implementation can be swapped without touching notice workflows.
abstract class SignatureService {
  /// Persists the drawn signature PNG and returns a result artifact.
  Future<SignatureResult> saveDrawnSignature({
    required String pngFilePath,
    required String signerName,
  });

  /// DocuSign Digital Signature API integration.
  /// Generates a DocuSign envelope, Certificate of Completion, and audit verification hash.
  Future<SignatureResult> signWithDocuSign({
    required String documentPath,
    required String signerName,
    required String signerEmail,
  });

  /// Future eMudhra hook: verifies a DSC-backed signature document.
  Future<bool> verifyDigitalSignature(String signatureId);
}

class MockSignatureService implements SignatureService {
  @override
  Future<SignatureResult> saveDrawnSignature({
    required String pngFilePath,
    required String signerName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return SignatureResult(
      id: 'sig-${DateTime.now().millisecondsSinceEpoch}',
      imagePath: pngFilePath,
      signedAt: DateTime.now(),
      signerName: signerName,
      isElectronicDrawing: true,
      isDocuSign: false,
    );
  }

  @override
  Future<SignatureResult> signWithDocuSign({
    required String documentPath,
    required String signerName,
    required String signerEmail,
  }) async {
    // Simulate DocuSign REST API envelope creation and signing ceremony
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final envelopeId =
        'DOCUSIGN-ENV-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';
    return SignatureResult(
      id: envelopeId,
      imagePath: documentPath,
      signedAt: DateTime.now(),
      signerName: signerName,
      isElectronicDrawing: false,
      isDocuSign: true,
      docusignEnvelopeId: envelopeId,
    );
  }

  @override
  Future<bool> verifyDigitalSignature(String signatureId) async {
    return true;
  }
}
