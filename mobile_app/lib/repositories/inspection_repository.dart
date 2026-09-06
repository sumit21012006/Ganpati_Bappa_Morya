import '../models/inspection.dart';

/// Inspection capability contract (inspector side).
abstract class InspectionRepository {
  /// Inspections assigned to the current inspector.
  Future<List<Inspection>> listInspections({InspectionStatus? status});

  Future<Inspection> getInspection(String id);

  /// Creates an inspection. Backend generates the canonical ID and
  /// associates inspector ID, business ID, and timestamp.
  Future<Inspection> createInspection(CreateInspectionRequest request);

  /// Marks the inspection in progress (inspector on site).
  Future<Inspection> startInspection(String id);

  /// Persists structured observations before finalisation.
  Future<Inspection> updateObservations(
    String id,
    InspectionObservation observation,
  );

  /// Finalises the inspection after notice/seizure workflows complete.
  Future<Inspection> completeInspection(String id, {String? remarks});
}
