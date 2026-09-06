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

  /// Future eMudhra hook: verifies a DSC-backed signature document.
  /// Throws [UnimplementedError] in the prototype.
  Future<bool> verifyDigitalSignature(String signatureId);
}

class MockSignatureService implements SignatureService {
  @override
  Future<SignatureResult> saveDrawnSignature({
    required String pngFilePath,
    required String signerName,
  }) async {
    // Simulate a short persistence latency.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return SignatureResult(
      id: 'sig-${DateTime.now().millisecondsSinceEpoch}',
      imagePath: pngFilePath,
      signedAt: DateTime.now(),
      signerName: signerName,
      isElectronicDrawing: true,
    );
  }

  @override
  Future<bool> verifyDigitalSignature(String signatureId) async {
    throw UnimplementedError(
      'eMudhra DSC verification arrives with Member 6 integration.',
    );
  }
}
