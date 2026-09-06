import 'dart:io';

/// Payment models — mirrors backend payment capability. Member 6 owns
/// Razorpay integration and webhook verification; Flutter NEVER marks a
/// payment successful on its own.
enum PaymentStatus {
  initiated,
  pendingVerification,
  success,
  failed,
  refunded;

  String get label => switch (this) {
        PaymentStatus.initiated => 'Initiated',
        PaymentStatus.pendingVerification => 'Pending Verification',
        PaymentStatus.success => 'Payment Successful',
        PaymentStatus.failed => 'Payment Failed',
        PaymentStatus.refunded => 'Refunded',
      };
}

/// Initiation response. In the real integration this carries the Razorpay
/// order details needed to open the checkout sheet (Member 6 contract).
class PaymentInitiation {
  const PaymentInitiation({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.currency,
    this.checkoutNote,
  });

  final String paymentId;
  final String orderId;
  final double amount;
  final String currency;
  final String? checkoutNote;
}

/// Payment record for a compounding order / penalty.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.caseId,
    required this.description,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.receiptUrl,
  });

  final String id;
  final String caseId;
  final String description;
  final double amount;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? receiptUrl;

  bool get isPending =>
      status == PaymentStatus.initiated ||
      status == PaymentStatus.pendingVerification ||
      status == PaymentStatus.failed;

  PaymentRecord copyWith({
    String? id,
    String? caseId,
    String? description,
    double? amount,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? receiptUrl,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}

/// Dispute/consent models — backend-defined statuses are authoritative.
enum ResponseStatus { submitted, underReview, accepted, rejected }

extension ResponseStatusX on ResponseStatus {
  String get label => switch (this) {
        ResponseStatus.submitted => 'Submitted',
        ResponseStatus.underReview => 'Under Review',
        ResponseStatus.accepted => 'Accepted',
        ResponseStatus.rejected => 'Rejected',
      };
}

class DisputeRequest {
  const DisputeRequest({
    required this.noticeId,
    required this.reason,
    this.comments,
    this.evidenceImagePaths = const [],
  });

  final String noticeId;
  final String reason;
  final String? comments;
  final List<String> evidenceImagePaths;
}

class CorrectionSubmission {
  const CorrectionSubmission({
    required this.noticeId,
    required this.comments,
    this.evidenceImagePaths = const [],
  });

  final String noticeId;
  final String comments;
  final List<String> evidenceImagePaths;
}

class ConsentRequest {
  const ConsentRequest({
    required this.noticeId,
    required this.confirmedBy,
    this.remarks,
  });

  final String noticeId;
  final String confirmedBy;
  final String? remarks;
}

/// Image attachment helper for dispute/correction submissions.
class AttachmentRef {
  const AttachmentRef({required this.localPath, this.remoteUrl});

  final String localPath;
  final String? remoteUrl;

  File get file => File(localPath);
}
