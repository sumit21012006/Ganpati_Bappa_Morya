import 'user.dart';
import 'violation.dart';

enum NoticeType { improvement, seizure, compounding, panchanama, other }

extension NoticeTypeX on NoticeType {
  String get label => switch (this) {
        NoticeType.improvement => 'Improvement Notice',
        NoticeType.seizure => 'Seizure Notice',
        NoticeType.compounding => 'Compounding Order',
        NoticeType.panchanama => 'Panchanama Document',
        NoticeType.other => 'Official Notice',
      };
}

enum NoticeStatus {
  draft,
  pendingSignature,
  issued,
  delivered,
  responseSubmitted,
  underDispute,
  consentGiven,
  complianceSubmitted,
  closed,
}

extension NoticeStatusX on NoticeStatus {
  String get label => switch (this) {
        NoticeStatus.draft => 'Draft',
        NoticeStatus.pendingSignature => 'Pending Signature',
        NoticeStatus.issued => 'Issued',
        NoticeStatus.delivered => 'Delivered',
        NoticeStatus.responseSubmitted => 'Response Submitted',
        NoticeStatus.underDispute => 'Under Dispute',
        NoticeStatus.consentGiven => 'Consent Given',
        NoticeStatus.complianceSubmitted => 'Correction Submitted',
        NoticeStatus.closed => 'Closed',
      };

  bool get isEditableByInspector =>
      this == NoticeStatus.draft || this == NoticeStatus.pendingSignature;

  bool get canBusinessRespond =>
      this == NoticeStatus.issued || this == NoticeStatus.delivered;
}

/// A section of law cited in a notice. Sourced from the Legal Knowledge
/// Base (Member 5); inspector may add/correct sections before issue.
class NoticeSection {
  const NoticeSection({
    required this.id,
    required this.citation,
    required this.title,
    this.description,
    this.isAddedByInspector = false,
  });

  final String id;
  final String citation;
  final String title;
  final String? description;
  final bool isAddedByInspector;

  NoticeSection copyWith({bool? isAddedByInspector}) => NoticeSection(
        id: id,
        citation: citation,
        title: title,
        description: description,
        isAddedByInspector: isAddedByInspector ?? this.isAddedByInspector,
      );
}

class Notice {
  const Notice({
    required this.id,
    required this.caseId,
    required this.type,
    required this.status,
    required this.productName,
    required this.issuedDate,
    required this.sections,
    required this.violations,
    required this.isAiDraft,
    required this.inspectionId,
    required this.businessId,
    required this.businessName,
    this.deadline,
    this.penaltyAmount,
    this.bodyText,
    this.inspectorRemark,
  });

  final String id;
  final String caseId;
  final NoticeType type;
  final NoticeStatus status;
  final String productName;
  final DateTime issuedDate;
  final List<NoticeSection> sections;
  final List<Violation> violations;

  /// True while the notice is an AI/NLP-generated draft awaiting
  /// inspector verification. Never silently finalised by AI.
  final bool isAiDraft;

  final String inspectionId;
  final String businessId;
  final String businessName;

  final DateTime? deadline;
  final double? penaltyAmount;

  /// NLP-generated body text; editable by the inspector.
  final String? bodyText;
  final String? inspectorRemark;

  bool get requiresAction =>
      status == NoticeStatus.issued || status == NoticeStatus.delivered;

  Notice copyWith({
    String? id,
    String? caseId,
    NoticeType? type,
    NoticeStatus? status,
    String? productName,
    DateTime? issuedDate,
    List<NoticeSection>? sections,
    List<Violation>? violations,
    bool? isAiDraft,
    String? inspectionId,
    String? businessId,
    String? businessName,
    DateTime? deadline,
    double? penaltyAmount,
    String? bodyText,
    String? inspectorRemark,
  }) {
    return Notice(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      type: type ?? this.type,
      status: status ?? this.status,
      productName: productName ?? this.productName,
      issuedDate: issuedDate ?? this.issuedDate,
      sections: sections ?? this.sections,
      violations: violations ?? this.violations,
      isAiDraft: isAiDraft ?? this.isAiDraft,
      inspectionId: inspectionId ?? this.inspectionId,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      deadline: deadline ?? this.deadline,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      bodyText: bodyText ?? this.bodyText,
      inspectorRemark: inspectorRemark ?? this.inspectorRemark,
    );
  }
}

/// Request body for notice generation through NestJS (which delegates to
/// Member 4's NLP service). Flutter does not compose legal text itself.
class GenerateNoticeRequest {
  const GenerateNoticeRequest({
    required this.inspectionId,
    required this.noticeType,
    required this.confirmedViolations,
    this.remarks,
  });

  final String inspectionId;
  final NoticeType noticeType;
  final List<Violation> confirmedViolations;
  final String? remarks;
}

// ---------------------------------------------------------------------------
// Seizure / sample
// ---------------------------------------------------------------------------

class SeizureSample {
  const SeizureSample({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reason,
    required this.capturedAt,
    this.samplePhotoPath,
    this.witness1Name,
    this.witness1Phone,
    this.witness2Name,
    this.witness2Phone,
    this.remarks,
  });

  /// Backend-issued sample ID (mock mode generates a temporary one).
  final String id;
  final String productId;
  final String productName;
  final String quantity;
  final String reason;
  final DateTime capturedAt;
  final String? samplePhotoPath;
  final String? witness1Name;
  final String? witness1Phone;
  final String? witness2Name;
  final String? witness2Phone;
  final String? remarks;

  SeizureSample copyWith({
    String? id,
    String? productId,
    String? productName,
    String? quantity,
    String? reason,
    DateTime? capturedAt,
    String? samplePhotoPath,
    String? witness1Name,
    String? witness1Phone,
    String? witness2Name,
    String? witness2Phone,
    String? remarks,
  }) {
    return SeizureSample(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      capturedAt: capturedAt ?? this.capturedAt,
      samplePhotoPath: samplePhotoPath ?? this.samplePhotoPath,
      witness1Name: witness1Name ?? this.witness1Name,
      witness1Phone: witness1Phone ?? this.witness1Phone,
      witness2Name: witness2Name ?? this.witness2Name,
      witness2Phone: witness2Phone ?? this.witness2Phone,
      remarks: remarks ?? this.remarks,
    );
  }
}

class CreateSeizureRequest {
  const CreateSeizureRequest({
    required this.inspectionId,
    required this.samples,
    required this.reason,
    this.remarks,
  });

  final String inspectionId;
  final List<SeizureSample> samples;
  final String reason;
  final String? remarks;
}

// ---------------------------------------------------------------------------
// Panchanama
// ---------------------------------------------------------------------------

class Panchanama {
  const Panchanama({
    required this.id,
    required this.caseId,
    required this.inspectionId,
    required this.observations,
    required this.conductedAt,
    this.witness1Name,
    this.witness1Phone,
    this.witness2Name,
    this.witness2Phone,
    this.actSection,
    this.violationSummary,
    this.seizureDetails,
    this.noticePeriodDays,
    this.evidenceImagePaths = const [],
  });

  final String id;
  final String caseId;
  final String inspectionId;
  final String observations;
  final DateTime conductedAt;
  final String? witness1Name;
  final String? witness1Phone;
  final String? witness2Name;
  final String? witness2Phone;
  final String? actSection;
  final String? violationSummary;
  final String? seizureDetails;
  final int? noticePeriodDays;
  final List<String> evidenceImagePaths;

  Panchanama copyWith({
    String? id,
    String? caseId,
    String? inspectionId,
    String? observations,
    DateTime? conductedAt,
    String? witness1Name,
    String? witness1Phone,
    String? witness2Name,
    String? witness2Phone,
    String? actSection,
    String? violationSummary,
    String? seizureDetails,
    int? noticePeriodDays,
    List<String>? evidenceImagePaths,
  }) {
    return Panchanama(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      inspectionId: inspectionId ?? this.inspectionId,
      observations: observations ?? this.observations,
      conductedAt: conductedAt ?? this.conductedAt,
      witness1Name: witness1Name ?? this.witness1Name,
      witness1Phone: witness1Phone ?? this.witness1Phone,
      witness2Name: witness2Name ?? this.witness2Name,
      witness2Phone: witness2Phone ?? this.witness2Phone,
      actSection: actSection ?? this.actSection,
      violationSummary: violationSummary ?? this.violationSummary,
      seizureDetails: seizureDetails ?? this.seizureDetails,
      noticePeriodDays: noticePeriodDays ?? this.noticePeriodDays,
      evidenceImagePaths: evidenceImagePaths ?? this.evidenceImagePaths,
    );
  }
}

// ---------------------------------------------------------------------------
// Cases (shared case-management view for inspector & business)
// ---------------------------------------------------------------------------

enum CaseStatus {
  inspectionDue,
  inspectionInProgress,
  underReview,
  noticeIssued,
  awaitingBusinessResponse,
  correctionSubmitted,
  reinspectionDue,
  compounding,
  awaitingPayment,
  closed,
  disputed,
}

extension CaseStatusX on CaseStatus {
  String get label => switch (this) {
        CaseStatus.inspectionDue => 'Inspection Due',
        CaseStatus.inspectionInProgress => 'Inspection In Progress',
        CaseStatus.underReview => 'Under Review',
        CaseStatus.noticeIssued => 'Notice Issued',
        CaseStatus.awaitingBusinessResponse => 'Awaiting Business Response',
        CaseStatus.correctionSubmitted => 'Correction Submitted',
        CaseStatus.reinspectionDue => 'Re-inspection Due',
        CaseStatus.compounding => 'Compounding',
        CaseStatus.awaitingPayment => 'Awaiting Payment',
        CaseStatus.closed => 'Closed',
        CaseStatus.disputed => 'Disputed',
      };
}

/// Unified case record spanning inspection → notice → response → resolution.
class LegalCase {
  const LegalCase({
    required this.id,
    required this.productName,
    required this.status,
    required this.openedAt,
    required this.timeline,
    required this.violationSummary,
    required this.role,
    required this.counterpartyName,
    this.currentStage,
    this.deadline,
    this.requiredAction,
    this.noticeType,
    this.penaltyAmount,
  });

  final String id;
  final String productName;
  final CaseStatus status;
  final DateTime openedAt;
  final List<CaseTimelineEntry> timeline;

  /// Human-readable summary of the confirmed violation(s).
  final String violationSummary;

  /// Which side is viewing. Derived from the auth role at query time.
  final UserRole role;

  final String counterpartyName;

  /// What the viewer must do next, e.g. "Sign and issue notice".
  final String? currentStage;
  final DateTime? deadline;
  final String? requiredAction;
  final NoticeType? noticeType;
  final double? penaltyAmount;

  factory LegalCase.fromJson(Map<String, dynamic> json) => LegalCase(
        id: json['id'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        status: CaseStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String?),
          orElse: () => CaseStatus.underReview,
        ),
        openedAt: DateTime.tryParse(json['openedAt'] as String? ?? '') ?? DateTime.now(),
        timeline: (json['timeline'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map((t) => CaseTimelineEntry(
                      title: t['title'] as String? ?? '',
                      dateTime: DateTime.tryParse(t['dateTime'] as String? ?? '') ?? DateTime.now(),
                      isDone: t['isDone'] as bool? ?? false,
                      isCurrent: t['isCurrent'] as bool? ?? false,
                      details: t['details'] as String?,
                      actor: t['actor'] as String?,
                    ))
                .toList() ??
            const [],
        violationSummary: json['violationSummary'] as String? ?? '',
        role: json['role'] == 'INSPECTOR' ? UserRole.inspector : UserRole.business,
        counterpartyName: json['counterpartyName'] as String? ?? '',
        currentStage: json['currentStage'] as String?,
        deadline: DateTime.tryParse(json['deadline'] as String? ?? ''),
        requiredAction: json['requiredAction'] as String?,
        penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble(),
      );
}

/// One timeline step rendered in the visual case timeline.
class CaseTimelineEntry {
  const CaseTimelineEntry({
    required this.title,
    required this.dateTime,
    required this.isDone,
    required this.isCurrent,
    this.details,
    this.actor,
  });

  final String title;
  final DateTime dateTime;
  final bool isDone;
  final bool isCurrent;
  final String? details;
  final String? actor;
}
