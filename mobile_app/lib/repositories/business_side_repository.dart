import '../models/notice.dart';
import '../models/payment.dart';
import '../models/self_check.dart';
import '../models/supply_chain.dart';

/// Business self-check capability contract.
///
/// PRIVACY: results never surface to inspectors. The backend must expose
/// self-check only under business-scoped endpoints.
abstract class SelfCheckRepository {
  /// Runs OCR + compliance on the given package images. Returns a
  /// private report — never creates a case or offence.
  Future<SelfCheckReport> performSelfCheck(PerformSelfCheckRequest request);

  /// Previous private self-check runs for the signed-in business.
  Future<List<SelfCheckReport>> getSelfCheckHistory();
}

/// Business case capability contract (notice inbox, responses, disputes).
abstract class BusinessCaseRepository {
  /// Notices received by the signed-in business.
  Future<List<Notice>> listNotices();

  Future<Notice> getNotice(String id);

  /// Submits corrected-package evidence for an improvement notice.
  Future<Notice> submitCorrection(CorrectionSubmission submission);

  /// Raises a dispute where permitted. Backend-defined statuses apply.
  Future<Notice> submitDispute(DisputeRequest request);

  /// Records explicit business consent (e.g. compounding consent).
  Future<Notice> submitConsent(ConsentRequest request);

  /// Business case tracking view.
  Future<List<LegalCase>> listCases();
}

/// Payment capability contract. Member 6 owns Razorpay + webhook; the
/// Flutter app only initiates and polls — never marks success itself.
abstract class PaymentRepository {
  /// Creates a payment order via NestJS → Razorpay.
  Future<PaymentInitiation> initiatePayment({
    required String caseId,
    required double amount,
    String? description,
  });

  /// Polls backend-verified status (webhook is source of truth).
  Future<PaymentRecord> getPaymentStatus(String paymentId);

  Future<List<PaymentRecord>> listPayments();
}

/// Supply-chain declaration capability contract.
abstract class SupplyChainRepository {
  /// Submits supplier/source information; the backend creates
  /// supply-chain relationships and any resulting inspection assignments.
  Future<void> submitSupplierDeclaration(SupplierDeclarationRequest request);

  /// Uploads purchase invoice evidence.
  Future<void> uploadPurchaseEvidence({
    required String inspectionId,
    required String invoiceImagePath,
  });
}
