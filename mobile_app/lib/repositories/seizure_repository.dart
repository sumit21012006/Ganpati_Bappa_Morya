import '../models/notice.dart';

/// Seizure, sample and panchanama capability contract.
abstract class SeizureRepository {
  /// Registers seized samples for an inspection. Sample IDs ultimately
  /// come from the backend; mock mode generates temporary realistic IDs.
  Future<List<SeizureSample>> createSamples(
    String inspectionId,
    List<SeizureSample> samples,
    {required String reason}
  );

  Future<List<SeizureSample>> getSamples(String inspectionId);

  Future<Panchanama> createPanchanama(Panchanama panchanama);

  Future<Panchanama?> getPanchanama(String inspectionId);
}

/// Case timeline capability contract (shared inspector/business view).
abstract class CaseRepository {
  /// Cases relevant to the current user's role.
  Future<List<LegalCase>> listCases({bool onlyActive = false});

  Future<LegalCase> getCase(String id);

  /// Full timeline for a case; only backend-returned states are shown.
  Future<List<CaseTimelineEntry>> getCaseTimeline(String caseId);
}
