/// Violation models — mirrors shared `violations` table.
///
/// CORE PRINCIPLE (human-in-the-loop): AI never makes the final legal
/// decision. Every AI finding starts as [ViolationStatus.potential] and
/// becomes binding only after the authorised inspector accepts it.
enum ViolationStatus { potential, accepted, rejected, edited }

extension ViolationStatusX on ViolationStatus {
  String get label => switch (this) {
        ViolationStatus.potential => 'Potential',
        ViolationStatus.accepted => 'Confirmed by Inspector',
        ViolationStatus.rejected => 'Rejected by Inspector',
        ViolationStatus.edited => 'Edited by Inspector',
      };

  bool get isConfirmed => this == ViolationStatus.accepted || this == ViolationStatus.edited;
}

enum ViolationSeverity { low, medium, high, critical }

extension ViolationSeverityX on ViolationSeverity {
  String get label => switch (this) {
        ViolationSeverity.low => 'Low',
        ViolationSeverity.medium => 'Medium',
        ViolationSeverity.high => 'High',
        ViolationSeverity.critical => 'Critical',
      };
}

enum ViolationType {
  missingDeclaration,
  incorrectMrp,
  netQuantityIssue,
  consumerCareIssue,
  missingMrp,
  nonStandardUnits,
  missingOrigin,
  dateIssue,
  other,
}

extension ViolationTypeX on ViolationType {
  String get defaultLabel => switch (this) {
        ViolationType.missingDeclaration => 'Missing Declaration',
        ViolationType.incorrectMrp => 'Incorrect MRP Declaration',
        ViolationType.netQuantityIssue => 'Net Quantity Issue',
        ViolationType.consumerCareIssue => 'Consumer Care Information Issue',
        ViolationType.missingMrp => 'MRP Not Declared',
        ViolationType.nonStandardUnits => 'Non-standard Unit Declaration',
        ViolationType.missingOrigin => 'Country of Origin Not Declared',
        ViolationType.dateIssue => 'Date Marking Issue',
        ViolationType.other => 'Other Declaration Issue',
      };
}

/// A single AI-detected or inspector-added violation finding.
class Violation {
  const Violation({
    required this.id,
    required this.type,
    required this.description,
    required this.severity,
    required this.status,
    required this.detectedAt,
    this.ruleSection,
    this.ruleTitle,
    this.confidence,
    this.recommendation,
    this.sourceImageId,
    this.inspectorRemark,
    this.isAiGenerated = false,
  });

  final String id;
  final ViolationType type;
  final String description;

  final ViolationSeverity severity;

  /// POTENTIAL until inspector verifies.
  final ViolationStatus status;

  /// Applicable section/rule — supplied by the Legal Knowledge Base
  /// (Member 5) through the backend, e.g. "Rule 6(1)(a), LM (Packaged
  /// Commodities) Rules, 2011".
  final String? ruleSection;
  final String? ruleTitle;

  /// 0.0–1.0 — present only for AI findings.
  final double? confidence;

  /// Suggested correction for the business.
  final String? recommendation;

  /// Evidence image this finding is based on.
  final String? sourceImageId;

  /// Free-text remark recorded when the inspector accepts/edits.
  final String? inspectorRemark;

  final bool isAiGenerated;
  final DateTime detectedAt;

  bool get isConfirmed => status.isConfirmed;

  factory Violation.fromJson(Map<String, dynamic> json) => Violation(
        id: json['id'] as String,
        type: ViolationType.values.firstWhere(
          (t) => t.name == (json['type'] as String?),
          orElse: () => ViolationType.other,
        ),
        description: json['description'] as String? ?? '',
        severity: ViolationSeverity.values.firstWhere(
          (s) => s.name == (json['severity'] as String?),
          orElse: () => ViolationSeverity.medium,
        ),
        status: ViolationStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String?),
          orElse: () => ViolationStatus.potential,
        ),
        ruleSection: json['ruleSection'] as String?,
        ruleTitle: json['ruleTitle'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble(),
        recommendation: json['recommendation'] as String?,
        sourceImageId: json['sourceImageId'] as String?,
        inspectorRemark: json['inspectorRemark'] as String?,
        isAiGenerated: json['isAiGenerated'] as bool? ?? false,
        detectedAt:
            DateTime.tryParse(json['detectedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Violation copyWith({
    String? id,
    ViolationType? type,
    String? description,
    ViolationSeverity? severity,
    ViolationStatus? status,
    String? ruleSection,
    String? ruleTitle,
    double? confidence,
    String? recommendation,
    String? sourceImageId,
    String? inspectorRemark,
    bool? isAiGenerated,
    DateTime? detectedAt,
  }) {
    return Violation(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      ruleSection: ruleSection ?? this.ruleSection,
      ruleTitle: ruleTitle ?? this.ruleTitle,
      confidence: confidence ?? this.confidence,
      recommendation: recommendation ?? this.recommendation,
      sourceImageId: sourceImageId ?? this.sourceImageId,
      inspectorRemark: inspectorRemark ?? this.inspectorRemark,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }
}

/// Inspector-added violation draft (no AI fields).
class AddViolationRequest {
  const AddViolationRequest({
    required this.type,
    required this.description,
    required this.severity,
    this.ruleSection,
    this.recommendation,
    this.sourceImageId,
  });

  final ViolationType type;
  final String description;
  final ViolationSeverity severity;
  final String? ruleSection;
  final String? recommendation;
  final String? sourceImageId;
}
