/// Real repository implementations backed by NestJS (Member 1).
///
/// ⚠️ ALL ROUTES BELOW ARE PROVISIONAL. The final endpoint names/paths are
/// decided by Member 1. Only THIS file needs updating when the contract
/// lands — no UI, provider, or mock file changes.
///
/// JSON mapping helpers are written against the documented shared-entity
/// schemas and are intentionally defensive until the real casing is known.
library;

import 'package:dio/dio.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/network/api_client.dart';
import '../../models/business.dart';
import '../../models/evidence.dart';
import '../../models/inspection.dart';
import '../../models/notice.dart';
import '../../models/ocr_result.dart';
import '../../models/user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/business_repository.dart';
import '../../repositories/business_side_repository.dart';
import '../../repositories/evidence_repository.dart';
import '../../repositories/inspection_repository.dart';
import '../../repositories/notice_repository.dart';
import '../../repositories/offence_repository.dart';
import '../../repositories/ocr_repository.dart';
import '../../repositories/seizure_repository.dart';
import '../../repositories/violation_repository.dart';
import '../../models/offence_history.dart';
import '../../models/payment.dart';
import '../../models/self_check.dart';
import '../../models/supply_chain.dart';
import '../../models/violation.dart';

Map<String, dynamic> _map(Object? data) =>
    data is Map<String, dynamic> ? data : <String, dynamic>{};

List<Map<String, dynamic>> _list(Object? data) => data is List<dynamic>
    ? data.whereType<Map<String, dynamic>>().toList()
    : <Map<String, dynamic>>[];

// ---------------------------------------------------------------------------
// Auth (Keycloak via NestJS)
// ---------------------------------------------------------------------------

class RealAuthRepository implements AuthRepository {
  RealAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<AuthResult> login({required String username, required String password}) async {
    try {
      final res = await _client.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final data = _map(res.data);
      final tokens = _map(data['tokens']);
      return AuthResult(
        user: User.fromJson(_map(data['user'])),
        accessToken: (tokens['accessToken'] ?? data['accessToken']) as String,
        refreshToken: (tokens['refreshToken'] ?? data['refreshToken']) as String,
        expiresInSeconds: (tokens['expiresIn'] ?? data['expiresIn']) as int?,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<AuthResult> refresh({required String refreshToken}) async {
    try {
      final res = await _client.dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      final data = _map(res.data);
      return AuthResult(
        user: User.fromJson(_map(data['user'])),
        accessToken: data['accessToken'] as String,
        refreshToken: (data['refreshToken'] as String?) ?? refreshToken,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<User?> currentUser() async {
    try {
      final res = await _client.dio.get('/auth/me');
      return User.fromJson(_map(res.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } catch (_) {
      // Logout must always succeed locally even if the server call fails.
    }
  }

  @override
  Future<User> registerBusinessAccount({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    try {
      final res = await _client.dio.post('/auth/register/business', data: {
        'username': username,
        'password': password,
        'fullName': fullName,
        'email': email,
        'phone': phone,
      });
      return User.fromJson(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Business
// ---------------------------------------------------------------------------

class RealBusinessRepository implements BusinessRepository {
  RealBusinessRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Business>> searchBusinesses(String query, {int limit = 25}) async {
    try {
      final res = await _client.dio
          .get('/businesses', queryParameters: {'q': query, 'limit': limit});
      return _list(res.data).map(Business.fromJson).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Business> getBusiness(String id) async {
    try {
      final res = await _client.dio.get('/businesses/$id');
      return Business.fromJson(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Business> registerBusiness(BusinessRegistrationRequest request) async {
    try {
      final res = await _client.dio.post('/businesses', data: request.toJson());
      return Business.fromJson(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Business> updateBusiness(Business business) async {
    try {
      final res = await _client.dio.patch('/businesses/${business.id}', data: {
        'name': business.name,
        if (business.gstin != null) 'gstin': business.gstin,
        if (business.contactPhone != null) 'contactPhone': business.contactPhone,
      });
      return Business.fromJson(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Inspection
// ---------------------------------------------------------------------------

class RealInspectionRepository implements InspectionRepository {
  RealInspectionRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Inspection>> listInspections({InspectionStatus? status}) async {
    try {
      final res = await _client.dio.get('/inspections', queryParameters: {
        if (status != null) 'status': status.name,
      });
      return _list(res.data).map(_parseInspection).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Inspection> getInspection(String id) async {
    try {
      final res = await _client.dio.get('/inspections/$id');
      return _parseInspection(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Inspection> createInspection(CreateInspectionRequest request) async {
    try {
      final res = await _client.dio.post('/inspections', data: {
        'businessId': request.businessId,
        'type': request.type.name,
        if (request.complaintId != null) 'complaintId': request.complaintId,
        if (request.notes != null) 'notes': request.notes,
      });
      return _parseInspection(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Inspection> startInspection(String id) => _action(id, 'start');

  @override
  Future<Inspection> completeInspection(String id, {String? remarks}) =>
      _action(id, 'complete', data: {if (remarks != null) 'remarks': remarks});

  @override
  Future<Inspection> updateObservations(
    String id,
    InspectionObservation observation,
  ) async {
    try {
      final res = await _client.dio.patch('/inspections/$id/observations', data: {
        'product': observation.product,
        'batchOrLot': observation.batchOrLot,
        'declaredQuantity': observation.declaredQuantity,
        'observedQuantity': observation.observedQuantity,
        'declaredMrp': observation.declaredMrp,
        'observedMrp': observation.observedMrp,
        'manufacturerOrPacker': observation.manufacturerOrPacker,
        'supplierOrSource': observation.supplierOrSource,
        'remarks': observation.remarks,
      });
      return _parseInspection(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<Inspection> _action(String id, String action, {Object? data}) async {
    try {
      final res = await _client.dio.post('/inspections/$id/$action', data: data);
      return _parseInspection(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  /// TODO(backend-integration): align with the final inspection JSON schema
  /// (embedded business object vs. businessId reference).
  Inspection _parseInspection(Map<String, dynamic> json) {
    final businessJson = _map(json['business']);
    return Inspection(
      id: json['id'] as String,
      business: Business.fromJson(businessJson),
      type: InspectionTypeX.fromLabel(json['type'] as String?),
      status: InspectionStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String?),
        orElse: () => InspectionStatus.assigned,
      ),
      scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      inspectorId: json['inspectorId'] as String?,
      inspectorName: json['inspectorName'] as String?,
      complaintId: json['complaintId'] as String?,
      notes: json['notes'] as String?,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}

// ---------------------------------------------------------------------------
// Evidence
// ---------------------------------------------------------------------------

class RealEvidenceRepository implements EvidenceRepository {
  RealEvidenceRepository(this._client);

  final ApiClient _client;

  @override
  Future<EvidenceItem> uploadEvidence({
    required String ownerId,
    required EvidenceItem evidence,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          evidence.filePath,
          filename: '${evidence.id}.jpg',
        ),
        'side': evidence.side.name,
        'capturedAt': evidence.capturedAt.toIso8601String(),
      });
      final res = await _client.dio.post(
        '/inspections/$ownerId/evidence',
        data: form,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      return EvidenceItem.fromJson(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<EvidenceItem>> getEvidence(String ownerId) async {
    try {
      final res = await _client.dio.get('/inspections/$ownerId/evidence');
      return _list(res.data).map(EvidenceItem.fromJson).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> deleteEvidence(String evidenceId) async {
    try {
      await _client.dio.delete('/evidence/$evidenceId');
    } catch (e) {
      throw mapException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// OCR
// ---------------------------------------------------------------------------

class RealOcrRepository implements OcrRepository {
  RealOcrRepository(this._client);

  final ApiClient _client;

  @override
  Future<String> submitPackageImages({
    required String ownerId,
    required List<EvidenceItem> images,
  }) async {
    try {
      final form = FormData();
      for (final image in images) {
        form.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(image.filePath),
        ));
      }
      final res = await _client.dio.post('/ocr/analyze', data: form);
      return _map(res.data)['jobId'] as String;
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<OcrResult> analyzePackage({
    required String ownerId,
    required List<EvidenceItem> images,
    void Function(OcrPipelineStep step)? onStep,
  }) async {
    final jobId = await submitPackageImages(ownerId: ownerId, images: images);
    // Poll until the backend-driven pipeline completes.
    while (true) {
      final result = await getAnalysisStatus(jobId);
      final step = result.currentStep;
      if (step != null) onStep?.call(step);
      if (result.isCompleted || result.isFailed) return result;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Future<OcrResult> getAnalysisStatus(String jobId) async {
    try {
      final res = await _client.dio.get('/ocr/jobs/$jobId');
      return _parseOcr(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<OcrResult> getOcrResult(String jobId) => getAnalysisStatus(jobId);

  /// TODO(backend-integration): align field keys/casing with the final
  /// FastAPI→NestJS passthrough schema.
  OcrResult _parseOcr(Map<String, dynamic> json) => OcrResult(
        jobId: json['jobId'] as String,
        status: OcrStatus.values.firstWhere(
          (s) => s.name.toLowerCase() == (json['status'] as String? ?? '').toLowerCase(),
          orElse: () => OcrStatus.processing,
        ),
        fields: _list(json['fields']).map(_parseField).toList(),
        analyzedAt:
            DateTime.tryParse(json['analyzedAt'] as String? ?? '') ?? DateTime.now(),
        currentStep: OcrPipelineStep.values.firstWhere(
          (s) => s.name == (json['progressStep'] as String?),
          orElse: () => OcrPipelineStep.extractingText,
        ),
        failureReason: json['failureReason'] as String?,
        rawTextPreview: json['rawTextPreview'] as String?,
      );

  ExtractedField _parseField(Map<String, dynamic> json) => ExtractedField.fromJson(json);
}

// ---------------------------------------------------------------------------
// Violations
// ---------------------------------------------------------------------------

class RealViolationRepository implements ViolationRepository {
  RealViolationRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Violation>> getViolations(String inspectionId) async {
    try {
      final res = await _client.dio.get('/inspections/$inspectionId/violations');
      return _list(res.data).map(Violation.fromJson).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Violation> editViolation(Violation violation, {String? remark}) =>
      _patch(violation.id, {
        'description': violation.description,
        'severity': violation.severity.name,
        'ruleSection': violation.ruleSection,
        if (remark != null) 'remark': remark,
      });

  @override
  Future<Violation> confirmViolation(String violationId, {String? remark}) =>
      _action(violationId, 'confirm', remark);

  @override
  Future<Violation> rejectViolation(String violationId, {String? remark}) =>
      _action(violationId, 'reject', remark);

  @override
  Future<Violation> addViolation(String inspectionId, AddViolationRequest request) async {
    try {
      final res = await _client.dio.post(
        '/inspections/$inspectionId/violations',
        data: {
          'type': request.type.name,
          'description': request.description,
          'severity': request.severity.name,
          if (request.ruleSection != null) 'ruleSection': request.ruleSection,
          if (request.recommendation != null) 'recommendation': request.recommendation,
        },
      );
      return Violation.fromJson(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<Violation> _patch(String id, Object data) async {
    try {
      final res = await _client.dio.patch('/violations/$id', data: data);
      return Violation.fromJson(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<Violation> _action(String id, String action, String? remark) async {
    try {
      final res = await _client.dio.post('/violations/$id/$action',
          data: {if (remark != null) 'remark': remark});
      return Violation.fromJson(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Offence history
// ---------------------------------------------------------------------------

class RealOffenceRepository implements OffenceRepository {
  RealOffenceRepository(this._client);

  final ApiClient _client;

  @override
  Future<OffenceHistory> getProductOffenceHistory(String productId) =>
      _fetch(productId, null);

  @override
  Future<OffenceHistory> getProductOffenceHistoryForBusiness(
    String productId,
    String businessId,
  ) =>
      _fetch(productId, businessId);

  Future<OffenceHistory> _fetch(String productId, String? businessId) async {
    try {
      final res = await _client.dio.get('/products/$productId/offences',
          queryParameters: {if (businessId != null) 'businessId': businessId});
      final data = _map(res.data);
      return OffenceHistory(
        productId: productId,
        matchedProductName: data['matchedProductName'] as String? ?? '',
        tier: OffenceTier.values.firstWhere(
          (t) => t.name == (data['tier'] as String?),
          orElse: () => OffenceTier.none,
        ),
        checkedAt: DateTime.tryParse(data['checkedAt'] as String? ?? '') ?? DateTime.now(),
        matchConfidence: (data['matchConfidence'] as num?)?.toDouble(),
        records: _list(data['records'])
            .map((r) => OffenceRecord(
                  caseId: r['caseId'] as String,
                  businessName: r['businessName'] as String? ?? '',
                  location: r['location'] as String? ?? '',
                  date: DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now(),
                  violationSummary: r['violationSummary'] as String? ?? '',
                  caseStatus: r['caseStatus'] as String? ?? '',
                ))
            .toList(),
      );
    } catch (e) {
      throw mapException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Notice
// ---------------------------------------------------------------------------

class RealNoticeRepository implements NoticeRepository {
  RealNoticeRepository(this._client);

  final ApiClient _client;

  @override
  Future<Notice> generateNotice(GenerateNoticeRequest request) async {
    try {
      final res = await _client.dio.post('/notices/generate', data: {
        'inspectionId': request.inspectionId,
        'type': request.noticeType.name,
        'violations': request.confirmedViolations.map((v) => v.id).toList(),
        if (request.remarks != null) 'remarks': request.remarks,
      });
      return _parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Notice> getNotice(String id) async {
    try {
      final res = await _client.dio.get('/notices/$id');
      return _parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<Notice>> listNoticesForBusiness(String businessId) =>
      _list1('/businesses/$businessId/notices');

  @override
  Future<List<Notice>> listNoticesForInspector(String inspectorId) =>
      _list1('/inspector/notices');

  Future<List<Notice>> _list1(String path) async {
    try {
      final res = await _client.dio.get(path);
      return _list(res.data).map(_parse).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Notice> editNotice(Notice notice) async {
    try {
      final res = await _client.dio.patch('/notices/${notice.id}', data: {
        'bodyText': notice.bodyText,
        'inspectorRemark': notice.inspectorRemark,
        'deadline': notice.deadline?.toIso8601String(),
      });
      return _parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Notice> addSection(String noticeId, NoticeSection section) async {
    try {
      final res = await _client.dio.post('/notices/$noticeId/sections', data: {
        'citation': section.citation,
        'title': section.title,
      });
      return _parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Notice> confirmDraft(String noticeId, {String? inspectorRemark}) async {
    try {
      final res = await _client.dio.post('/notices/$noticeId/confirm',
          data: {if (inspectorRemark != null) 'remark': inspectorRemark});
      return _parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Notice> signAndIssue(SignIssueRequest request) async {
    try {
      final form = FormData.fromMap({
        'signature': await MultipartFile.fromFile(request.signatureImagePath),
        'signerName': request.signerName,
        if (request.remarks != null) 'remarks': request.remarks,
      });
      final res = await _client.dio.post(
        '/notices/${request.noticeId}/issue',
        data: form,
      );
      return _parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  /// TODO(backend-integration): align with the final notice JSON schema.
  Notice _parse(Map<String, dynamic> json) => Notice(
        id: json['id'] as String,
        caseId: json['caseId'] as String,
        type: NoticeType.values.firstWhere(
          (t) => t.name == (json['type'] as String?),
          orElse: () => NoticeType.improvement,
        ),
        status: NoticeStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String?),
          orElse: () => NoticeStatus.draft,
        ),
        productName: json['productName'] as String? ?? '',
        issuedDate:
            DateTime.tryParse(json['issuedDate'] as String? ?? '') ?? DateTime.now(),
        sections: _list(json['sections'])
            .map((s) => NoticeSection(
                  id: s['id'] as String,
                  citation: s['citation'] as String,
                  title: s['title'] as String,
                  description: s['description'] as String?,
                ))
            .toList(),
        violations: _list(json['violations']).map(Violation.fromJson).toList(),
        isAiDraft: json['isAiDraft'] as bool? ?? false,
        inspectionId: json['inspectionId'] as String? ?? '',
        businessId: json['businessId'] as String? ?? '',
        businessName: json['businessName'] as String? ?? '',
        deadline: DateTime.tryParse(json['deadline'] as String? ?? ''),
        penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble(),
        bodyText: json['bodyText'] as String?,
        inspectorRemark: json['inspectorRemark'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Seizure / panchanama
// ---------------------------------------------------------------------------

class RealSeizureRepository implements SeizureRepository {
  RealSeizureRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<SeizureSample>> createSamples(
    String inspectionId,
    List<SeizureSample> samples, {
    required String reason,
  }) async {
    try {
      final res = await _client.dio.post('/inspections/$inspectionId/seizures', data: {
        'reason': reason,
        'samples': samples
            .map((s) => {
                  'productId': s.productId,
                  'productName': s.productName,
                  'quantity': s.quantity,
                  'witness1Name': s.witness1Name,
                  'witness2Name': s.witness2Name,
                  'remarks': s.remarks,
                })
            .toList(),
      });
      return _list(_map(res.data)['samples'])
          .map((s) => SeizureSample(
                id: s['id'] as String,
                productId: s['productId'] as String? ?? '',
                productName: s['productName'] as String? ?? '',
                quantity: s['quantity'] as String? ?? '',
                reason: reason,
                capturedAt: DateTime.now(),
              ))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<SeizureSample>> getSamples(String inspectionId) async {
    try {
      final res = await _client.dio.get('/inspections/$inspectionId/seizures');
      return _list(_map(res.data)['samples'])
          .map((s) => SeizureSample(
                id: s['id'] as String? ?? '',
                productId: s['productId'] as String? ?? '',
                productName: s['productName'] as String? ?? '',
                quantity: s['quantity'] as String? ?? '',
                reason: s['reason'] as String? ?? '',
                capturedAt: DateTime.tryParse(s['capturedAt'] as String? ?? '') ?? DateTime.now(),
              ))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Panchanama> createPanchanama(Panchanama p) async {
    try {
      final res = await _client.dio.post('/panchanamas', data: {
        'inspectionId': p.inspectionId,
        'caseId': p.caseId,
        'observations': p.observations,
        'witness1Name': p.witness1Name,
        'witness2Name': p.witness2Name,
        'actSection': p.actSection,
        'seizureDetails': p.seizureDetails,
        'noticePeriodDays': p.noticePeriodDays,
      });
      return p.copyWith(id: _map(res.data)['id'] as String? ?? p.id);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Panchanama?> getPanchanama(String inspectionId) async {
    try {
      final res = await _client.dio.get('/inspections/$inspectionId/panchanama');
      if (res.data == null) return null;
      return null; // TODO(backend-integration): parse final schema.
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Business-side: self-check, cases/responses, payment, supply chain
// ---------------------------------------------------------------------------

class RealSelfCheckRepository implements SelfCheckRepository {
  RealSelfCheckRepository(this._client);

  final ApiClient _client;

  @override
  Future<SelfCheckReport> performSelfCheck(PerformSelfCheckRequest request) async {
    try {
      final form = FormData();
      for (final path in request.imagePaths) {
        form.files.add(MapEntry('images', await MultipartFile.fromFile(path)));
      }
      form.fields.add(MapEntry('productNameHint', request.productNameHint));
      final res = await _client.dio.post('/self-check/analyze', data: form);
      return _parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<SelfCheckReport>> getSelfCheckHistory() async {
    try {
      final res = await _client.dio.get('/self-check/history');
      return _list(res.data).map(_parse).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  SelfCheckReport _parse(Map<String, dynamic> json) => SelfCheckReport(
        id: json['id'] as String,
        productName: json['productName'] as String? ?? '',
        performedAt:
            DateTime.tryParse(json['performedAt'] as String? ?? '') ?? DateTime.now(),
        isCompliant: json['isCompliant'] as bool? ?? false,
        issues: _list(json['issues'])
            .map((i) => SelfCheckIssue(
                  field: i['field'] as String? ?? '',
                  issue: i['issue'] as String? ?? '',
                  requirement: i['requirement'] as String? ?? '',
                  severity: ViolationSeverity.values.firstWhere(
                    (s) => s.name == (i['severity'] as String?),
                    orElse: () => ViolationSeverity.low,
                  ),
                  recommendedCorrection: i['recommendedCorrection'] as String? ?? '',
                ))
            .toList(),
      );
}

class RealBusinessCaseRepository implements BusinessCaseRepository {
  RealBusinessCaseRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Notice>> listNotices() async {
    try {
      final res = await _client.dio.get('/business/notices');
      return _list(res.data).map(RealNoticeRepository(_client)._parse).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Notice> getNotice(String id) async {
    try {
      final res = await _client.dio.get('/notices/$id');
      return RealNoticeRepository(_client)._parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Notice> submitCorrection(CorrectionSubmission submission) async {
    try {
      final form = FormData.fromMap({'comments': submission.comments});
      for (final path in submission.evidenceImagePaths) {
        form.files.add(MapEntry('evidence', await MultipartFile.fromFile(path)));
      }
      final res = await _client.dio
          .post('/notices/${submission.noticeId}/correction', data: form);
      return RealNoticeRepository(_client)._parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Notice> submitDispute(DisputeRequest request) async {
    try {
      final res = await _client.dio.post('/notices/${request.noticeId}/dispute', data: {
        'reason': request.reason,
        'comments': request.comments,
      });
      return RealNoticeRepository(_client)._parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Notice> submitConsent(ConsentRequest request) async {
    try {
      final res = await _client.dio.post('/notices/${request.noticeId}/consent', data: {
        'confirmedBy': request.confirmedBy,
        'remarks': request.remarks,
      });
      return RealNoticeRepository(_client)._parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<LegalCase>> listCases() async {
    try {
      final res = await _client.dio.get('/business/cases');
      return _list(res.data).map((c) => LegalCase.fromJson(_map(c))).toList();
    } catch (e) {
      throw mapException(e);
    }
  }
}

class RealPaymentRepository implements PaymentRepository {
  RealPaymentRepository(this._client);

  final ApiClient _client;

  @override
  Future<PaymentInitiation> initiatePayment({
    required String caseId,
    required double amount,
    String? description,
  }) async {
    try {
      final res = await _client.dio.post('/payments/initiate', data: {
        'caseId': caseId,
        'amount': amount,
        'currency': 'INR',
        if (description != null) 'note': description,
      });
      final data = _map(res.data);
      return PaymentInitiation(
        paymentId: data['paymentId'] as String,
        orderId: data['orderId'] as String,
        amount: (data['amount'] as num).toDouble(),
        currency: data['currency'] as String? ?? 'INR',
        checkoutNote: data['note'] as String?,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<PaymentRecord> getPaymentStatus(String paymentId) async {
    try {
      final res = await _client.dio.get('/payments/$paymentId');
      final data = _map(res.data);
      return PaymentRecord(
        id: data['id'] as String,
        caseId: data['caseId'] as String? ?? '',
        description: data['description'] as String? ?? '',
        amount: (data['amount'] as num?)?.toDouble() ?? 0,
        status: PaymentStatus.values.firstWhere(
          (s) => s.name == (data['status'] as String?),
          orElse: () => PaymentStatus.pendingVerification,
        ),
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
        completedAt: DateTime.tryParse(data['completedAt'] as String? ?? ''),
        receiptUrl: data['receiptUrl'] as String?,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<PaymentRecord>> listPayments() async {
    try {
      final res = await _client.dio.get('/payments');
      return _list(res.data)
          .map((j) => PaymentRecord(
                id: j['id'] as String,
                caseId: j['caseId'] as String? ?? '',
                description: j['description'] as String? ?? '',
                amount: (j['amount'] as num?)?.toDouble() ?? 0,
                status: PaymentStatus.values.firstWhere(
                  (s) => s.name == (j['status'] as String?),
                  orElse: () => PaymentStatus.pendingVerification,
                ),
                createdAt:
                    DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
              ))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }
}

class RealCaseRepository implements CaseRepository {
  RealCaseRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<LegalCase>> listCases({bool onlyActive = false}) async {
    try {
      final res = await _client.dio.get('/cases', queryParameters: {
        if (onlyActive) 'active': 'true',
      });
      return _list(res.data).map(_parse).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<LegalCase> getCase(String id) async {
    try {
      final res = await _client.dio.get('/cases/$id');
      return _parse(_map(res.data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<CaseTimelineEntry>> getCaseTimeline(String caseId) async {
    final c = await getCase(caseId);
    return c.timeline;
  }

  /// TODO(backend-integration): align with the final case JSON schema.
  LegalCase _parse(Map<String, dynamic> json) => LegalCase(
        id: json['id'] as String,
        productName: json['productName'] as String? ?? '',
        status: CaseStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String?),
          orElse: () => CaseStatus.underReview,
        ),
        openedAt:
            DateTime.tryParse(json['openedAt'] as String? ?? '') ?? DateTime.now(),
        timeline: _list(json['timeline'])
            .map((t) => CaseTimelineEntry(
                  title: t['title'] as String,
                  dateTime:
                      DateTime.tryParse(t['dateTime'] as String? ?? '') ??
                          DateTime.now(),
                  isDone: t['isDone'] as bool? ?? false,
                  isCurrent: t['isCurrent'] as bool? ?? false,
                  details: t['details'] as String?,
                  actor: t['actor'] as String?,
                ))
            .toList(),
        violationSummary: json['violationSummary'] as String? ?? '',
        role: UserRole.inspector,
        counterpartyName: json['counterpartyName'] as String? ?? '',
        currentStage: json['currentStage'] as String?,
        deadline: DateTime.tryParse(json['deadline'] as String? ?? ''),
        requiredAction: json['requiredAction'] as String?,
        noticeType: NoticeType.values.firstWhere(
          (t) => t.name == (json['noticeType'] as String?),
          orElse: () => NoticeType.improvement,
        ),
        penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble(),
      );
}

class RealSupplyChainRepository implements SupplyChainRepository {
  RealSupplyChainRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> submitSupplierDeclaration(SupplierDeclarationRequest request) async {
    try {
      await _client.dio.post(
        '/inspections/${request.inspectionId}/supply-chain',
        data: {
          'supplierName': request.supplierName,
          'supplierType': request.supplierType,
          'supplierGstin': request.supplierGstin,
          'supplierAddress': request.supplierAddress,
          if (request.purchaseBill != null)
            'purchaseBill': {
              'billNumber': request.purchaseBill!.billNumber,
              'billDate': request.purchaseBill!.billDate.toIso8601String(),
              'totalAmount': request.purchaseBill!.totalAmount,
              'items': request.purchaseBill!.items
                  .map((i) => {
                        'productName': i.productName,
                        'quantity': i.quantity,
                        'unitPrice': i.unitPrice,
                      })
                  .toList(),
            },
          'remarks': request.remarks,
        },
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> uploadPurchaseEvidence({
    required String inspectionId,
    required String invoiceImagePath,
  }) async {
    try {
      final form = FormData.fromMap({
        'invoice': await MultipartFile.fromFile(invoiceImagePath),
      });
      await _client.dio.post('/inspections/$inspectionId/supply-chain/evidence',
          data: form);
    } catch (e) {
      throw mapException(e);
    }
  }
}
