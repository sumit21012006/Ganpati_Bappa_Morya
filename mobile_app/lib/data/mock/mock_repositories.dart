import 'dart:io';

import '../../core/constants/mock_ids.dart';
import '../../core/errors/app_exception.dart';
import '../../models/business.dart';
import '../../models/evidence.dart';
import '../../models/inspection.dart';
import '../../models/notice.dart';
import '../../models/offence_history.dart';
import '../../models/ocr_result.dart';
import '../../models/payment.dart';
import '../../models/self_check.dart';
import '../../models/signature.dart';
import '../../models/user.dart';
import '../../models/violation.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/business_repository.dart';
import '../../repositories/business_side_repository.dart';
import '../../repositories/evidence_repository.dart';
import '../../repositories/inspection_repository.dart';
import '../../repositories/notice_repository.dart';
import '../../repositories/offence_repository.dart';
import '../../repositories/ocr_repository.dart';
import '../../models/supply_chain.dart';
import '../../repositories/seizure_repository.dart' show CaseRepository, SeizureRepository;
import '../../repositories/violation_repository.dart';
import '../mock_backend.dart';

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<AuthResult> login({required String username, required String password}) async {
    await _backend.delay();
    try {
      final result = _backend.login(username, password);
      return AuthResult(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        expiresInSeconds: 3600,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnauthorizedException(
        'Invalid username or password. Please try again.',
      );
    }
  }

  @override
  Future<AuthResult> refresh({required String refreshToken}) async {
    await _backend.delay();
    final user = _backend.sessionUser();
    if (user == null) throw const UnauthorizedException();
    return AuthResult(
      user: user,
      accessToken: 'mock-access-refreshed',
      refreshToken: refreshToken,
    );
  }

  @override
  Future<User?> currentUser() async {
    await _backend.delay(50, 120);
    return _backend.sessionUser();
  }

  @override
  Future<void> logout() async {
    await _backend.delay(100, 200);
    _backend.logout();
  }

  @override
  Future<User> registerBusinessAccount({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await _backend.delay();
    return _backend.registerBusinessAccount(
      username: username,
      password: password,
      fullName: fullName,
      email: email,
      phone: phone,
    );
  }
}

// ---------------------------------------------------------------------------
// Business
// ---------------------------------------------------------------------------

class MockBusinessRepository implements BusinessRepository {
  MockBusinessRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<List<Business>> searchBusinesses(String query, {int limit = 25}) async {
    await _backend.delay();
    final results = _backend.searchBusinesses(query);
    if (results.isEmpty && query.trim().isNotEmpty) return [];
    return results.take(limit).toList();
  }

  @override
  Future<Business> getBusiness(String id) async {
    await _backend.delay(100, 250);
    return _backend.getBusiness(id);
  }

  @override
  Future<Business> registerBusiness(BusinessRegistrationRequest request) async {
    await _backend.delay(500, 1000);
    return _backend.registerBusiness(request);
  }

  @override
  Future<Business> updateBusiness(Business business) async {
    await _backend.delay();
    return _backend.updateBusiness(business);
  }
}

// ---------------------------------------------------------------------------
// Inspection
// ---------------------------------------------------------------------------

class MockInspectionRepository implements InspectionRepository {
  MockInspectionRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<List<Inspection>> listInspections({InspectionStatus? status}) async {
    await _backend.delay();
    return _backend.listInspections(status: status);
  }

  @override
  Future<Inspection> getInspection(String id) async {
    await _backend.delay(100, 250);
    return _backend.getInspection(id);
  }

  @override
  Future<Inspection> createInspection(CreateInspectionRequest request) async {
    await _backend.delay(400, 800);
    return _backend.createInspection(request);
  }

  @override
  Future<Inspection> startInspection(String id) async {
    await _backend.delay(150, 350);
    return _backend.startInspection(id);
  }

  @override
  Future<Inspection> updateObservations(
    String id,
    InspectionObservation observation,
  ) async {
    await _backend.delay();
    return _backend.updateObservations(id, observation);
  }

  @override
  Future<Inspection> completeInspection(String id, {String? remarks}) async {
    await _backend.delay();
    return _backend.completeInspection(id, remarks: remarks);
  }
}

// ---------------------------------------------------------------------------
// Evidence
// ---------------------------------------------------------------------------

class MockEvidenceRepository implements EvidenceRepository {
  MockEvidenceRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<EvidenceItem> uploadEvidence({
    required String ownerId,
    required EvidenceItem evidence,
    void Function(double progress)? onProgress,
  }) async {
    // Simulate chunked upload progress 0.0 → 1.0.
    for (var p = 0.0; p < 1.0; p += 0.25) {
      onProgress?.call(p);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    onProgress?.call(1.0);
    return evidence.copyWith(uploaded: true, remoteUrl: 'mock://evidence/${evidence.id}');
  }

  @override
  Future<List<EvidenceItem>> getEvidence(String ownerId) async {
    await _backend.delay(100, 200);
    return const [];
  }

  @override
  Future<void> deleteEvidence(String evidenceId) async {}
}

// ---------------------------------------------------------------------------
// OCR
// ---------------------------------------------------------------------------

class MockOcrRepository implements OcrRepository {
  MockOcrRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<String> submitPackageImages({
    required String ownerId,
    required List<EvidenceItem> images,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockIds.selfCheck();
  }

  @override
  Future<OcrResult> analyzePackage({
    required String ownerId,
    required List<EvidenceItem> images,
    void Function(OcrPipelineStep step)? onStep,
  }) {
    return _backend.runOcrPipeline(
      imageLabels: images.map((e) => e.side.label).toList(),
      onStep: onStep,
    );
  }

  @override
  Future<OcrResult> getAnalysisStatus(String jobId) async {
    await _backend.delay(100, 200);
    return OcrResult(
      jobId: jobId,
      status: OcrStatus.completed,
      fields: const [],
      analyzedAt: DateTime.now(),
    );
  }

  @override
  Future<OcrResult> getOcrResult(String jobId) => getAnalysisStatus(jobId);
}

// ---------------------------------------------------------------------------
// Violations
// ---------------------------------------------------------------------------

class MockViolationRepository implements ViolationRepository {
  MockViolationRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<List<Violation>> getViolations(String inspectionId) async {
    await _backend.delay(150, 350);
    return List.of(_backend.violationStore.putIfAbsent(
      inspectionId,
      () => _backend.aiFindingsForAnalysis(),
    ));
  }

  @override
  Future<Violation> editViolation(Violation violation, {String? remark}) async {
    await _backend.delay(150, 300);
    final list = _backend.violationStore.putIfAbsent(
      _inspectionIdOf(violation),
      () => <Violation>[],
    );
    final idx = list.indexWhere((v) => v.id == violation.id);
    final updated = violation.copyWith(
      status: ViolationStatus.edited,
      inspectorRemark: remark,
    );
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    return updated;
  }

  @override
  Future<Violation> confirmViolation(String violationId, {String? remark}) async {
    await _backend.delay(150, 300);
    return _mutate(violationId, (v) => v.copyWith(
          status: ViolationStatus.accepted,
          inspectorRemark: remark,
        ));
  }

  @override
  Future<Violation> rejectViolation(String violationId, {String? remark}) async {
    await _backend.delay(150, 300);
    return _mutate(violationId, (v) => v.copyWith(
          status: ViolationStatus.rejected,
          inspectorRemark: remark,
        ));
  }

  @override
  Future<Violation> addViolation(String inspectionId, AddViolationRequest request) async {
    await _backend.delay(200, 400);
    final violation = Violation(
      id: 'vio-${DateTime.now().millisecondsSinceEpoch}',
      type: request.type,
      description: request.description,
      severity: request.severity,
      status: ViolationStatus.accepted, // inspector-authored = confirmed
      ruleSection: request.ruleSection,
      recommendation: request.recommendation,
      sourceImageId: request.sourceImageId,
      isAiGenerated: false,
      detectedAt: DateTime.now(),
    );
    _backend.violationStore[inspectionId] = [
      ..._backend.violationStore.putIfAbsent(inspectionId, () => <Violation>[]),
      violation,
    ];
    return violation;
  }

  /// The mock store keeps findings keyed by inspection; find the owning
  /// inspection by scanning the store.
  String _inspectionIdOf(Violation violation) {
    for (final entry in _backend.violationStore.entries) {
      if (entry.value.any((v) => v.id == violation.id)) return entry.key;
    }
    return '';
  }

  Violation _mutate(String violationId, Violation Function(Violation) fn) {
    for (final entry in _backend.violationStore.entries) {
      final idx = entry.value.indexWhere((v) => v.id == violationId);
      if (idx != -1) {
        final updated = fn(entry.value[idx]);
        entry.value[idx] = updated;
        return updated;
      }
    }
    throw const NotFoundException('Violation not found.');
  }
}

// ---------------------------------------------------------------------------
// Offence history
// ---------------------------------------------------------------------------

class MockOffenceRepository implements OffenceRepository {
  MockOffenceRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<OffenceHistory> getProductOffenceHistory(String productId) async {
    await _backend.delay(300, 600);
    return _backend.offenceHistoryFor(productId, '');
  }

  @override
  Future<OffenceHistory> getProductOffenceHistoryForBusiness(
    String productId,
    String businessId,
  ) async {
    await _backend.delay(300, 600);
    return _backend.offenceHistoryFor(productId, businessId);
  }
}

// ---------------------------------------------------------------------------
// Notice
// ---------------------------------------------------------------------------

class MockNoticeRepository implements NoticeRepository {
  MockNoticeRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<Notice> generateNotice(GenerateNoticeRequest request) async {
    // NLP generation takes a moment.
    await _backend.delay(800, 1400);
    return _backend.generateNotice(request);
  }

  @override
  Future<Notice> getNotice(String id) async {
    await _backend.delay(100, 250);
    return _backend.getNotice(id);
  }

  @override
  Future<List<Notice>> listNoticesForBusiness(String businessId) async {
    await _backend.delay();
    return _backend.listNoticesForBusiness(businessId);
  }

  @override
  Future<List<Notice>> listNoticesForInspector(String inspectorId) async {
    await _backend.delay();
    return _backend.listNoticesForInspector(inspectorId);
  }

  @override
  Future<Notice> editNotice(Notice notice) async {
    await _backend.delay(200, 400);
    return _backend.updateNotice(notice);
  }

  @override
  Future<Notice> addSection(String noticeId, NoticeSection section) async {
    await _backend.delay(150, 300);
    return _backend.addSection(noticeId, section);
  }

  @override
  Future<Notice> confirmDraft(String noticeId, {String? inspectorRemark}) async {
    await _backend.delay(150, 300);
    final notice = _backend.getNotice(noticeId);
    return _backend.updateNotice(
      notice.copyWith(status: NoticeStatus.pendingSignature, inspectorRemark: inspectorRemark),
    );
  }

  @override
  Future<Notice> signAndIssue(SignIssueRequest request) async {
    await _backend.delay(400, 800);
    return _backend.signAndIssue(request);
  }
}

// ---------------------------------------------------------------------------
// Seizure
// ---------------------------------------------------------------------------

class MockSeizureRepository implements SeizureRepository {
  MockSeizureRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<List<SeizureSample>> createSamples(
    String inspectionId,
    List<SeizureSample> samples, {
    required String reason,
  }) async {
    await _backend.delay(400, 800);
    return _backend.saveSamples(inspectionId, samples);
  }

  @override
  Future<List<SeizureSample>> getSamples(String inspectionId) async {
    await _backend.delay(100, 200);
    return const [];
  }

  @override
  Future<Panchanama> createPanchanama(Panchanama panchanama) async {
    await _backend.delay(500, 900);
    return panchanama.copyWith(id: 'PAN-${DateTime.now().millisecondsSinceEpoch}');
  }

  @override
  Future<Panchanama?> getPanchanama(String inspectionId) async {
    await _backend.delay(100, 200);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Business-side: self-check, cases, responses, payment, supply chain
// ---------------------------------------------------------------------------

class MockSelfCheckRepository implements SelfCheckRepository {
  MockSelfCheckRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<SelfCheckReport> performSelfCheck(PerformSelfCheckRequest request) {
    return _backend.runSelfCheck(request);
  }

  @override
  Future<List<SelfCheckReport>> getSelfCheckHistory() async {
    await _backend.delay(200, 400);
    return _backend.selfCheckHistory();
  }
}

class MockBusinessCaseRepository implements BusinessCaseRepository {
  MockBusinessCaseRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<List<Notice>> listNotices() async {
    await _backend.delay();
    return _backend.businessNotices();
  }

  @override
  Future<Notice> getNotice(String id) async {
    await _backend.delay(100, 250);
    return _backend.getNotice(id);
  }

  @override
  Future<Notice> submitCorrection(CorrectionSubmission submission) async {
    await _backend.delay(500, 900);
    return _backend.submitCorrection(submission);
  }

  @override
  Future<Notice> submitDispute(DisputeRequest request) async {
    await _backend.delay(500, 900);
    return _backend.submitDispute(request);
  }

  @override
  Future<Notice> submitConsent(ConsentRequest request) async {
    await _backend.delay(400, 700);
    return _backend.submitConsent(request);
  }

  @override
  Future<List<LegalCase>> listCases() async {
    await _backend.delay();
    return _backend.listCases(UserRole.business);
  }
}

class MockPaymentRepository implements PaymentRepository {
  MockPaymentRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<PaymentInitiation> initiatePayment({
    required String caseId,
    required double amount,
    String? description,
  }) async {
    await _backend.delay(400, 800);
    return _backend.initiatePayment(caseId, amount, description);
  }

  @override
  Future<PaymentRecord> getPaymentStatus(String paymentId) async {
    await _backend.delay(300, 500);
    return _backend.pollPayment(paymentId);
  }

  @override
  Future<List<PaymentRecord>> listPayments() async {
    await _backend.delay(150, 300);
    return _backend.listPayments();
  }
}

class MockCaseRepository implements CaseRepository {
  MockCaseRepository(this._backend, this._role);

  final MockBackend _backend;
  final UserRole? _role;

  @override
  Future<List<LegalCase>> listCases({bool onlyActive = false}) async {
    await _backend.delay(200, 450);
    final all = _backend.listCases(_role ?? UserRole.inspector);
    if (!onlyActive) return all;
    return all.where((c) => c.status != CaseStatus.closed).toList();
  }

  @override
  Future<LegalCase> getCase(String id) async {
    await _backend.delay(100, 250);
    return _backend.listCases(UserRole.inspector).firstWhere(
          (c) => c.id == id,
          orElse: () => throw const NotFoundException('Case not found.'),
        );
  }

  @override
  Future<List<CaseTimelineEntry>> getCaseTimeline(String caseId) async {
    final c = await getCase(caseId);
    return c.timeline;
  }
}

class MockSupplyChainRepository implements SupplyChainRepository {
  MockSupplyChainRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<void> submitSupplierDeclaration(SupplierDeclarationRequest request) async {
    await _backend.delay(500, 900);
    // Backend would create supply_chain_relationships here.
  }

  @override
  Future<void> uploadPurchaseEvidence({
    required String inspectionId,
    required String invoiceImagePath,
  }) async {
    await _backend.delay(400, 700);
    if (!File(invoiceImagePath).existsSync()) {
      // Mock mode tolerates missing files; real impl would upload.
    }
  }
}
