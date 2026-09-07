import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_controller.dart';
import '../core/network/api_client.dart';
import '../data/mock_backend.dart';
import '../data/mock/mock_repositories.dart';
import '../data/real/real_repositories.dart';
import '../repositories/auth_repository.dart';
import '../repositories/business_repository.dart';
import '../repositories/business_side_repository.dart';
import '../repositories/evidence_repository.dart';
import '../repositories/inspection_repository.dart';
import '../repositories/notice_repository.dart';
import '../repositories/offence_repository.dart';
import '../repositories/ocr_repository.dart';
import '../repositories/seizure_repository.dart';
import '../repositories/violation_repository.dart';
import '../services/signature_service.dart';

/// ============================================================================
/// IMPLEMENTATION SWITCH
/// ============================================================================
///
/// DEMO MODE (default): every repository is served by [MockBackend] — the
/// full enforcement + self-check flow runs on-device with no services.
///
/// BACKEND INTEGRATION: flip [useMockData] to `false` (or bind it to a
/// --dart-define) once NestJS is live. NO other file changes are required:
/// UI → controllers → repository interfaces stay identical.
///
/// A per-repository escape hatch is provided so individual capabilities can
/// migrate to the live backend one at a time during integration.
/// ============================================================================

const bool useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);

/// Per-repository overrides during backend integration.
const bool useRealAuth = bool.fromEnvironment('REAL_AUTH', defaultValue: true);
const bool useRealOcr = bool.fromEnvironment('REAL_OCR', defaultValue: true);

// ---------------------------------------------------------------------------
// Core
// ---------------------------------------------------------------------------

final mockBackendProvider = Provider<MockBackend>((ref) => MockBackend.instance);

// ---------------------------------------------------------------------------
// Repositories — swap point Mock ⇄ Real
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMockData && !useRealAuth) {
    return MockAuthRepository(ref.watch(mockBackendProvider));
  }
  return RealAuthRepository(ref.watch(apiClientProvider));
});

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  if (useMockData) return MockBusinessRepository(ref.watch(mockBackendProvider));
  return RealBusinessRepository(ref.watch(apiClientProvider));
});

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  if (useMockData) return MockInspectionRepository(ref.watch(mockBackendProvider));
  return RealInspectionRepository(ref.watch(apiClientProvider));
});

final evidenceRepositoryProvider = Provider<EvidenceRepository>((ref) {
  if (useMockData) return MockEvidenceRepository(ref.watch(mockBackendProvider));
  return RealEvidenceRepository(ref.watch(apiClientProvider));
});

final ocrRepositoryProvider = Provider<OcrRepository>((ref) {
  if (useMockData && !useRealOcr) {
    return MockOcrRepository(ref.watch(mockBackendProvider));
  }
  return RealOcrRepository(ref.watch(apiClientProvider));
});

final violationRepositoryProvider = Provider<ViolationRepository>((ref) {
  if (useMockData) return MockViolationRepository(ref.watch(mockBackendProvider));
  return RealViolationRepository(ref.watch(apiClientProvider));
});

final offenceRepositoryProvider = Provider<OffenceRepository>((ref) {
  if (useMockData) return MockOffenceRepository(ref.watch(mockBackendProvider));
  return RealOffenceRepository(ref.watch(apiClientProvider));
});

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  if (useMockData) return MockNoticeRepository(ref.watch(mockBackendProvider));
  return RealNoticeRepository(ref.watch(apiClientProvider));
});

final seizureRepositoryProvider = Provider<SeizureRepository>((ref) {
  if (useMockData) return MockSeizureRepository(ref.watch(mockBackendProvider));
  return RealSeizureRepository(ref.watch(apiClientProvider));
});

final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  if (useMockData) {
    return MockCaseRepository(
      ref.watch(mockBackendProvider),
      ref.watch(authControllerProvider).user?.role,
    );
  }
  return RealCaseRepository(ref.watch(apiClientProvider));
});

final selfCheckRepositoryProvider = Provider<SelfCheckRepository>((ref) {
  if (useMockData) return MockSelfCheckRepository(ref.watch(mockBackendProvider));
  return RealSelfCheckRepository(ref.watch(apiClientProvider));
});

final businessCaseRepositoryProvider = Provider<BusinessCaseRepository>((ref) {
  if (useMockData) return MockBusinessCaseRepository(ref.watch(mockBackendProvider));
  return RealBusinessCaseRepository(ref.watch(apiClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  if (useMockData) return MockPaymentRepository(ref.watch(mockBackendProvider));
  return RealPaymentRepository(ref.watch(apiClientProvider));
});

final supplyChainRepositoryProvider = Provider<SupplyChainRepository>((ref) {
  if (useMockData) return MockSupplyChainRepository(ref.watch(mockBackendProvider));
  return RealSupplyChainRepository(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

final signatureServiceProvider = Provider<SignatureService>(
  (ref) => MockSignatureService(),
);
