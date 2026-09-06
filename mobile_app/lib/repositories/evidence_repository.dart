import '../models/evidence.dart';

/// Evidence upload capability contract.
///
/// Upload progress is reported through [onProgress] (0.0–1.0) so the UI
/// can render a determinate bar during multi-image upload.
abstract class EvidenceRepository {
  /// Uploads one evidence image for an inspection (or self-check).
  /// Returns the stored evidence item with backend remote URL populated.
  Future<EvidenceItem> uploadEvidence({
    required String ownerId,
    required EvidenceItem evidence,
    void Function(double progress)? onProgress,
  });

  /// Retrieves evidence metadata for an inspection (URLs only).
  Future<List<EvidenceItem>> getEvidence(String ownerId);

  /// Deletes a not-yet-uploaded local capture.
  Future<void> deleteEvidence(String evidenceId);
}
