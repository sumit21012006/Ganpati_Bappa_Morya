import 'dart:math';

import '../models/business.dart';
import '../models/inspection.dart';
import '../models/notice.dart';
import '../models/offence_history.dart';
import '../models/ocr_result.dart';
import '../models/payment.dart';
import '../models/self_check.dart';
import '../models/user.dart';
import '../models/violation.dart';
import '../core/errors/app_exception.dart';
import '../repositories/notice_repository.dart' show SignIssueRequest;
import 'mock_data.dart';

/// In-memory simulated backend for DEMO mode.
///
/// Simulates the NestJS (Member 1) + FastAPI (Member 4) behaviour with
/// realistic latency and stateful mutations so the complete enforcement and
/// self-check flows can be demonstrated without any live services.
///
/// All async delays are kept short (200–900 ms) to keep the demo snappy.
class MockBackend {
  MockBackend._() {
    _seed();
  }

  static final MockBackend instance = MockBackend._();

  final Random _random = Random();
  final Map<String, User> _users = {};
  final Map<String, String> _passwords = {};
  final Map<String, String> _usernames = {};
  final Map<String, String> _refreshTokens = {};
  final List<Business> _businesses = [];
  final List<Inspection> _inspections = [];
  final List<Notice> _notices = [];
  final List<Violation> _violations = [];
  final Map<String, List<Violation>> _violationsByInspection = {};
  final List<SelfCheckReport> _selfChecks = [];
  final List<PaymentRecord> _payments = [];

  // Session state (mock stand-in for secure token storage).
  User? _currentUser;

  User? get currentUser => _currentUser;

  // ---------------------------------------------------------------------
  // Seeding
  // ---------------------------------------------------------------------

  void _seed() {
    _businesses.addAll(mockBusinesses);
    _inspections.addAll(mockInspections);
    _notices.addAll(mockNotices);
    _selfChecks.addAll(mockSelfCheckHistory);
    _payments.addAll(mockPayments);

    _users[demoInspector.id] = demoInspector;
    _users[demoBusinessUser.id] = demoBusinessUser;
    _passwords[demoInspector.id] = 'inspector123';
    _passwords[demoBusinessUser.id] = 'business123';
    _usernames['rajesh.deshmukh'] = demoInspector.id;
    _usernames['anita@abctraders.in'] = demoBusinessUser.id;

    // A few extra registered business accounts.
    for (final biz in _businesses.skip(1)) {
      final id = 'usr-${biz.id}';
      _users[id] = User(
        id: id,
        name: biz.ownerName ?? 'Owner',
        role: UserRole.business,
        email: '${biz.id}@demo.example.in',
        businessId: biz.id,
      );
      _passwords[id] = 'business123';
    }
  }

  /// DEMO MODE credentials — surfaced on the login screen.
  static const demoCredentials = {
    'inspector': ('rajesh.deshmukh', 'inspector123'),
    'business': ('anita@abctraders.in', 'business123'),
  };

  // ---------------------------------------------------------------------
  // Latency + error simulation
  // ---------------------------------------------------------------------

  Future<void> _delay([int minMs = 200, int maxMs = 700]) async {
    await Future<void>.delayed(
      Duration(milliseconds: minMs + _random.nextInt(maxMs - minMs)),
    );
  }

  /// Public latency simulation for mock repositories.
  Future<void> delay([int minMs = 200, int maxMs = 700]) => _delay(minMs, maxMs);

  /// Live violation store keyed by inspection id (mock repositories mutate
  /// this to implement the human-in-the-loop verification flow).
  Map<String, List<Violation>> get violationStore => _violationsByInspection;

  /// Occasionally simulates transient OCR failures so the Retry flow can
  /// be demonstrated. Kept low (~12%) so the demo remains smooth.
  bool get _simulateOcrFailure => _random.nextInt(100) < 12;

  void requireSession() {
    if (_currentUser == null) {
      throw const UnauthorizedException();
    }
  }

  User requireRole(UserRole role) {
    requireSession();
    final user = _currentUser!;
    if (user.role != role) {
      throw const ForbiddenException();
    }
    return user;
  }

  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------

  ({User user, String accessToken, String refreshToken}) login(
    String username,
    String password,
  ) {
    final normalized = username.trim().toLowerCase();
    final userId = _usernames[normalized];
    final entry = _users.entries.firstWhere(
      (e) =>
          e.key == userId ||
          (e.value.email ?? '').toLowerCase() == normalized ||
          e.value.id.toLowerCase() == normalized ||
          normalized == (e.value.role == UserRole.inspector ? 'inspector' : 'business'),
      orElse: () => throw const UnauthorizedException(
        'Invalid username or password. Please try again.',
      ),
    );
    if (_passwords[entry.key] != password) {
      throw const UnauthorizedException(
        'Invalid username or password. Please try again.',
      );
    }
    _currentUser = entry.value;
    return (
      user: entry.value,
      accessToken: 'mock-access-${entry.key}',
      refreshToken: 'mock-refresh-${entry.key}',
    );
  }

  void logout() {
    _currentUser = null;
    _refreshTokens.clear();
  }

  User? sessionUser() => _currentUser;

  User registerBusinessAccount({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
  }) {
    final exists = _users.values.any(
      (u) => (u.email ?? '').toLowerCase() == email.trim().toLowerCase(),
    );
    if (exists) {
      throw const ValidationException(
        'An account with this e-mail already exists. Try signing in instead.',
      );
    }
    final id = 'usr-${_random.nextInt(900000) + 100000}';
    final user = User(
      id: id,
      name: fullName,
      role: UserRole.business, // ALWAYS business — inspectors are provisioned.
      email: email,
      phone: phone,
    );
    _users[id] = user;
    _passwords[id] = password;
    _currentUser = user;
    return user;
  }

  // ---------------------------------------------------------------------
  // Business
  // ---------------------------------------------------------------------

  List<Business> searchBusinesses(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_businesses);
    return _businesses
        .where((b) =>
            b.name.toLowerCase().contains(q) ||
            (b.gstin ?? '').toLowerCase().contains(q) ||
            b.location.city.toLowerCase().contains(q) ||
            b.ownerName!.toLowerCase().contains(q))
        .toList();
  }

  Business getBusiness(String id) =>
      _businesses.firstWhere((b) => b.id == id, orElse: () => throw const NotFoundException());

  Business registerBusiness(BusinessRegistrationRequest request) {
    if (_businesses.any((b) => b.gstin == request.gstin && request.gstin != null)) {
      throw const ValidationException(
        'A business with this GSTIN is already registered.',
      );
    }
    final business = Business(
      id: 'biz-${_random.nextInt(900000) + 100000}',
      name: request.name,
      type: request.type,
      status: BusinessStatus.pending, // backend GSTIN verification pending
      location: request.location,
      gstin: request.gstin,
      ownerName: request.ownerName,
      contactPhone: request.contactPhone,
      contactEmail: request.contactEmail,
      pan: request.pan,
      annualTurnover: request.annualTurnover,
    );
    _businesses.add(business);

    // Link the (just-registered) session user to the business.
    final user = _currentUser;
    if (user != null && user.isBusiness) {
      _users[user.id] = user.copyWith(businessId: business.id);
      _currentUser = _users[user.id];
    }
    return business;
  }

  Business updateBusiness(Business business) {
    final idx = _businesses.indexWhere((b) => b.id == business.id);
    if (idx == -1) throw const NotFoundException();
    _businesses[idx] = business;
    return business;
  }

  // ---------------------------------------------------------------------
  // Inspection
  // ---------------------------------------------------------------------

  List<Inspection> listInspections({InspectionStatus? status}) {
    requireRole(UserRole.inspector);
    final list = status == null
        ? List.of(_inspections)
        : _inspections.where((i) => i.status == status).toList();
    list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return list;
  }

  Inspection getInspection(String id) =>
      _inspections.firstWhere((i) => i.id == id, orElse: () => throw const NotFoundException());

  Inspection createInspection(CreateInspectionRequest request) {
    final inspector = requireRole(UserRole.inspector);
    final business = getBusiness(request.businessId);
    final inspection = Inspection(
      id: 'INSP-2026-${_random.nextInt(90000) + 10000}',
      business: business,
      type: request.type,
      status: InspectionStatus.inProgress,
      scheduledAt: DateTime.now(),
      createdAt: DateTime.now(),
      inspectorId: inspector.id,
      inspectorName: inspector.name,
      complaintId: request.complaintId,
      notes: request.notes,
    );
    _inspections.insert(0, inspection);
    return inspection;
  }

  Inspection startInspection(String id) => _mutateInspection(id, (i) {
        if (i.status == InspectionStatus.assigned) {
          return i.copyWith(status: InspectionStatus.inProgress);
        }
        return i;
      });

  Inspection updateObservations(String id, InspectionObservation o) =>
      _mutateInspection(id, (i) => i.copyWith(notes: o.remarks ?? i.notes));

  Inspection completeInspection(String id, {String? remarks}) =>
      _mutateInspection(id, (i) => i.copyWith(
            status: InspectionStatus.completed,
            completedAt: DateTime.now(),
            notes: remarks ?? i.notes,
          ));

  Inspection _mutateInspection(String id, Inspection Function(Inspection) fn) {
    final idx = _inspections.indexWhere((i) => i.id == id);
    if (idx == -1) throw const NotFoundException();
    final updated = fn(_inspections[idx]);
    _inspections[idx] = updated;
    return updated;
  }

  // ---------------------------------------------------------------------
  // OCR pipeline (simulates FastAPI async job)
  // ---------------------------------------------------------------------

  Future<OcrResult> runOcrPipeline({
    required List<String> imageLabels,
    void Function(OcrPipelineStep step)? onStep,
  }) async {
    for (final step in OcrPipelineStep.values) {
      onStep?.call(step);
      // Upload step is fast; analysis steps take a bit longer.
      await _delay(
        step == OcrPipelineStep.uploadingEvidence ? 250 : 500,
        step == OcrPipelineStep.uploadingEvidence ? 450 : 900,
      );
    }

    if (_simulateOcrFailure) {
      throw const OcrException(
        'Image analysis failed. One or more photos may be unclear. '
        'Retake unclear photos or retry the analysis.',
      );
    }

    return OcrResult(
      jobId: 'ocrjob-${_random.nextInt(900000) + 100000}',
      status: OcrStatus.completed,
      fields: _extractedFields(),
      analyzedAt: DateTime.now(),
      rawTextPreview: 'Mfd: 06/2026  |  MRP ₹ 115.00 (incl. of all taxes)  |  '
          'Net Qty 1 KG  |  Consumer Care: 1800-xxx-xxx',
    );
  }

  List<ExtractedField> _extractedFields() => [
        const ExtractedField(
          key: OcrFieldKeys.productName,
          label: 'Product Name',
          value: 'Surf Excel Easy Wash Detergent Powder',
          confidence: 0.96,
        ),
        const ExtractedField(
          key: OcrFieldKeys.genericName,
          label: 'Generic Name',
          value: 'Detergent Powder',
          confidence: 0.88,
        ),
        const ExtractedField(
          key: OcrFieldKeys.manufacturer,
          label: 'Manufacturer',
          value: 'Hindustan Unilever Ltd, Andheri (E), Mumbai 400096',
          confidence: 0.93,
        ),
        const ExtractedField(
          key: OcrFieldKeys.netQuantity,
          label: 'Net Quantity',
          value: '1 KG',
          confidence: 0.72,
          unit: 'kg',
        ),
        const ExtractedField(
          key: OcrFieldKeys.mrp,
          label: 'MRP',
          value: '₹ 115.00 (Inclusive of all taxes)',
          confidence: 0.91,
        ),
        const ExtractedField(
          key: OcrFieldKeys.manufacturingDate,
          label: 'Manufacturing Date',
          value: '06/2026',
          confidence: 0.83,
        ),
        const ExtractedField(
          key: OcrFieldKeys.expiryOrUseBy,
          label: 'Expiry / Use By',
          value: '—',
          confidence: 0.0,
          isMissing: true,
        ),
        const ExtractedField(
          key: OcrFieldKeys.countryOfOrigin,
          label: 'Country of Origin',
          value: 'India',
          confidence: 0.94,
        ),
        const ExtractedField(
          key: OcrFieldKeys.consumerCare,
          label: 'Consumer Care',
          value: '1800-223-525 (toll free)',
          confidence: 0.77,
        ),
        const ExtractedField(
          key: OcrFieldKeys.batchOrLot,
          label: 'Batch / Lot No.',
          value: 'PF6114A21',
          confidence: 0.89,
        ),
      ];

  // ---------------------------------------------------------------------
  // Violations (AI findings attached to a simulated analysis)
  // ---------------------------------------------------------------------

  List<Violation> aiFindingsForAnalysis() => [
        mockAiViolation1(),
        mockAiViolation2(),
        mockAiViolation3(),
      ];

  /// Lazily seeds AI findings for an inspection's completed OCR run and
  /// returns the live list the violation repository mutates.
  List<Violation> violationsFor(String inspectionId) {
    return _violationsByInspection.putIfAbsent(inspectionId, aiFindingsForAnalysis);
  }

  void storeViolations(String inspectionId, List<Violation> violations) {
    _violationsByInspection[inspectionId] = violations;
  }

  // ---------------------------------------------------------------------
  // Offence history
  // ---------------------------------------------------------------------

  OffenceHistory offenceHistoryFor(String productName, String businessName) {
    // Demo narrative: Surf Excel at ABC Traders = repeat offence.
    if (productName.toLowerCase().contains('surf') &&
        businessName.toLowerCase().contains('abc')) {
      return offenceHistoryRepeat();
    }
    return OffenceHistory(
      productId: 'prd-matched-${_random.nextInt(1000)}',
      matchedProductName: productName,
      tier: OffenceTier.none,
      checkedAt: DateTime.now(),
      records: const [],
    );
  }

  // ---------------------------------------------------------------------
  // Notices
  // ---------------------------------------------------------------------

  Notice generateNotice(GenerateNoticeRequest request) {
    final inspection = getInspection(request.inspectionId);
    final draft = Notice(
      id: 'NOT-${_random.nextInt(900000) + 100000}',
      caseId: 'LM/2026/${_random.nextInt(9000) + 1000}',
      type: request.noticeType,
      status: NoticeStatus.draft,
      productName: inspection.products.isNotEmpty
          ? inspection.products.first.name
          : 'Assorted packaged commodities',
      issuedDate: DateTime.now(),
      inspectionId: inspection.id,
      businessId: inspection.business.id,
      businessName: inspection.business.name,
      deadline: DateTime.now().add(const Duration(days: 15)),
      sections: _sectionsForViolations(request.confirmedViolations),
      violations: List.of(request.confirmedViolations),
      isAiDraft: true, // AI-generated draft until inspector finalises
      bodyText: _nlpBodyText(inspection.business.name, request.noticeType),
      inspectorRemark: request.remarks,
    );
    _notices.insert(0, draft);
    return draft;
  }

  List<NoticeSection> _sectionsForViolations(List<Violation> violations) {
    final citations = <String, NoticeSection>{};
    for (final v in violations) {
      final match = noticeSectionLibrary.where(
        (s) => v.ruleSection != null && v.ruleSection!.contains(s.citation.split(',')[0]),
      );
      for (final s in match) {
        citations[s.id] = s;
      }
    }
    if (citations.isEmpty) {
      return [noticeSectionLibrary[1], noticeSectionLibrary[3]];
    }
    return citations.values.toList();
  }

  String _nlpBodyText(String businessName, NoticeType type) {
    final today = DateTime.now();
    final formatted =
        '${today.day.toString().padLeft(2, '0')}/'
        '${today.month.toString().padLeft(2, '0')}/'
        '${today.year}';
    return switch (type) {
      NoticeType.improvement =>
        'Whereas an inspection was carried out at the premises of '
        '$businessName on $formatted and contraventions of the Legal '
        'Metrology Act, 2009 and the Legal Metrology (Packaged Commodities) '
        'Rules, 2011 were observed in respect of pre-packaged commodities '
        'offered for retail sale, you are hereby directed to rectify the '
        'said contraventions and submit a compliance report with '
        'photographic evidence within fifteen (15) days.',
      NoticeType.seizure =>
        'The commodities detailed in the annexed panchanama have been '
        'seized under Section 22 of the Legal Metrology Act, 2009 from the '
        'premises of $businessName on $formatted. Show cause within fifteen '
        '(15) days why the seized goods shall not be confiscated.',
      _ =>
        'Notice under the Legal Metrology Act, 2009 issued to $businessName '
        'on $formatted. Refer to the annexed details and applicable '
        'sections.',
    };
  }

  Notice getNotice(String id) =>
      _notices.firstWhere((n) => n.id == id, orElse: () => throw const NotFoundException());

  List<Notice> listNoticesForBusiness(String businessId) =>
      _notices.where((n) => n.businessId == businessId || businessId.isEmpty).toList();

  List<Notice> listNoticesForInspector(String inspectorId) =>
      _notices.where((n) => n.inspectionId.isNotEmpty).toList();

  Notice updateNotice(Notice notice) {
    final idx = _notices.indexWhere((n) => n.id == notice.id);
    if (idx == -1) throw const NotFoundException();
    _notices[idx] = notice;
    return notice;
  }

  Notice addSection(String noticeId, NoticeSection section) {
    final notice = getNotice(noticeId);
    final updated = notice.copyWith(
      sections: [...notice.sections, section.copyWith(isAddedByInspector: true)],
    );
    return updateNotice(updated);
  }

  Notice signAndIssue(SignIssueRequest request) {
    final notice = getNotice(request.noticeId);
    final issued = notice.copyWith(
      status: NoticeStatus.issued,
      isAiDraft: false,
      inspectorRemark: request.remarks ?? notice.inspectorRemark,
    );
    return updateNotice(issued);
  }

  // ---------------------------------------------------------------------
  // Seizure / panchanama
  // ---------------------------------------------------------------------

  List<SeizureSample> saveSamples(String inspectionId, List<SeizureSample> samples) {
    requireRole(UserRole.inspector);
    // Re-issue backend IDs for the samples.
    return samples
        .map((s) => s.copyWith(id: 'SMP-${_random.nextInt(90000) + 10000}'))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Business side: notices / responses / disputes / consent
  // ---------------------------------------------------------------------

  List<Notice> businessNotices() {
    final user = requireRole(UserRole.business);
    return listNoticesForBusiness(user.businessId ?? '');
  }

  Notice submitCorrection(CorrectionSubmission submission) {
    final notice = getNotice(submission.noticeId);
    return updateNotice(
      notice.copyWith(status: NoticeStatus.complianceSubmitted),
    );
  }

  Notice submitDispute(DisputeRequest request) {
    final notice = getNotice(request.noticeId);
    return updateNotice(notice.copyWith(status: NoticeStatus.underDispute));
  }

  Notice submitConsent(ConsentRequest request) {
    final notice = getNotice(request.noticeId);
    return updateNotice(notice.copyWith(status: NoticeStatus.consentGiven));
  }

  // ---------------------------------------------------------------------
  // Self-check (PRIVATE)
  // ---------------------------------------------------------------------

  Future<SelfCheckReport> runSelfCheck(PerformSelfCheckRequest request) async {
    requireRole(UserRole.business);
    for (final step in OcrPipelineStep.values) {
      onSelfCheckStep?.call(step);
      await _delay(250, 700);
    }
    final hasIssue = _random.nextInt(100) < 70; // 70% chance issues found
    final report = SelfCheckReport(
      id: 'SC-${_random.nextInt(900000) + 100000}',
      productName: request.productNameHint,
      performedAt: DateTime.now(),
      isCompliant: !hasIssue,
      issues: hasIssue
          ? [
              const SelfCheckIssue(
                field: 'Consumer care details',
                issue: 'Consumer-care declaration may require correction.',
                requirement:
                    'Rule 6(3), LM (Packaged Commodities) Rules, 2011 requires '
                    'a consumer-care declaration with phone and e-mail.',
                severity: ViolationSeverity.medium,
                recommendedCorrection:
                    'Add the required consumer-care declaration in the '
                    'prescribed format.',
              ),
              if (_random.nextBool())
                const SelfCheckIssue(
                  field: 'Net quantity',
                  issue: 'Net quantity uses a non-standard unit symbol.',
                  requirement:
                      'Rule 7 requires prescribed SI units ("kg", "g", "ml", "L").',
                  severity: ViolationSeverity.low,
                  recommendedCorrection:
                      'Print the quantity in standard units with the prescribed '
                      'numeral height.',
                ),
            ]
          : const [],
      imagePaths: List.of(request.imagePaths),
    );
    _selfChecks.insert(0, report);
    return report;
  }

  /// Optional progress hook wired by the self-check controller.
  void Function(OcrPipelineStep step)? onSelfCheckStep;

  List<SelfCheckReport> selfCheckHistory() {
    requireRole(UserRole.business);
    return List.unmodifiable(_selfChecks);
  }

  // ---------------------------------------------------------------------
  // Payments
  // ---------------------------------------------------------------------

  PaymentInitiation initiatePayment(String caseId, double amount, String? note) {
    requireRole(UserRole.business);
    return PaymentInitiation(
      paymentId: 'PAY-${_random.nextInt(90000000) + 10000000}',
      orderId: 'order_mock_${_random.nextInt(900000) + 100000}',
      amount: amount,
      currency: 'INR',
      checkoutNote: note ?? 'Legal Metrology penalty — Case $caseId',
    );
  }

  /// Simulates the Razorpay → webhook → backend verification cycle: the
  /// first status poll still shows pending verification, the second
  /// confirms success (backend-verified). Flutter never marks success.
  PaymentRecord pollPayment(String paymentId) {
    final idx = _payments.indexWhere((p) => p.id == paymentId);
    if (idx != -1) {
      final record = _payments[idx];
      if (record.status == PaymentStatus.initiated) {
        _payments[idx] = record.copyWith(status: PaymentStatus.pendingVerification);
        return _payments[idx];
      }
      if (record.status == PaymentStatus.pendingVerification) {
        _payments[idx] = record.copyWith(
          status: PaymentStatus.success,
          completedAt: DateTime.now(),
        );
        return _payments[idx];
      }
      return record;
    }
    // Newly initiated payment.
    var record = PaymentRecord(
      id: paymentId,
      caseId: 'LM/2026/0155',
      description: 'Compounding penalty',
      amount: 5000,
      status: PaymentStatus.pendingVerification,
      createdAt: DateTime.now(),
    );
    _payments.insert(0, record);
    return record;
  }

  List<PaymentRecord> listPayments() => List.unmodifiable(_payments);

  // ---------------------------------------------------------------------
  // Cases
  // ---------------------------------------------------------------------

  List<LegalCase> listCases(UserRole role) {
    if (role == UserRole.business) {
      return mockCases.where((c) => c.role == UserRole.business).toList();
    }
    return mockCases;
  }
}
