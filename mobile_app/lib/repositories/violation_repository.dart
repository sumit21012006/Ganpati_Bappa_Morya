import '../models/violation.dart';

/// Violation capability contract — implements the human-in-the-loop
/// principle. AI findings arrive as POTENTIAL and only become confirmed
/// through explicit inspector actions recorded on the backend.
abstract class ViolationRepository {
  Future<List<Violation>> getViolations(String inspectionId);

  /// Persists an inspector edit (corrected description/section/severity).
  Future<Violation> editViolation(Violation violation, {String? remark});

  /// Confirms an AI potential finding — recorded as inspector-verified.
  Future<Violation> confirmViolation(String violationId, {String? remark});

  /// Rejects an AI potential finding with an optional reason.
  Future<Violation> rejectViolation(String violationId, {String? remark});

  /// Adds a manually-created violation (never AI-flagged).
  Future<Violation> addViolation(String inspectionId, AddViolationRequest request);
}
