/// Inspection models — mirrors shared `inspections` and
/// `inspection_products` tables.
library;

import 'business.dart';
import 'product.dart';
enum InspectionType { routine, complaintBased, supplyChainLinked }

extension InspectionTypeX on InspectionType {
  String get label => switch (this) {
        InspectionType.routine => 'Routine',
        InspectionType.complaintBased => 'Complaint Based',
        InspectionType.supplyChainLinked => 'Supply Chain Linked',
      };

  String get description => switch (this) {
        InspectionType.routine =>
          'Scheduled compliance verification of a registered business.',
        InspectionType.complaintBased =>
          'Inspection triggered by a citizen complaint routed through the Controller portal.',
        InspectionType.supplyChainLinked =>
          'Follow-up inspection of a supplier/source linked through purchase records.',
      };

  static InspectionType fromLabel(String? label) =>
      InspectionType.values.where((t) => t.label == label).firstOrNull ??
          InspectionType.routine;
}

enum InspectionStatus {
  assigned,
  inProgress,
  evidenceCaptured,
  ocrProcessing,
  underReview,
  violationsConfirmed,
  noticeIssued,
  awaitingReinspection,
  completed,
  cancelled,
}

extension InspectionStatusX on InspectionStatus {
  String get label => switch (this) {
        InspectionStatus.assigned => 'Assigned',
        InspectionStatus.inProgress => 'In Progress',
        InspectionStatus.evidenceCaptured => 'Evidence Captured',
        InspectionStatus.ocrProcessing => 'Processing',
        InspectionStatus.underReview => 'Under Review',
        InspectionStatus.violationsConfirmed => 'Violations Confirmed',
        InspectionStatus.noticeIssued => 'Notice Issued',
        InspectionStatus.awaitingReinspection => 'Awaiting Re-inspection',
        InspectionStatus.completed => 'Completed',
        InspectionStatus.cancelled => 'Cancelled',
      };

  bool get isActive =>
      this != InspectionStatus.completed && this != InspectionStatus.cancelled;
}

class Inspection {
  const Inspection({
    required this.id,
    required this.business,
    required this.type,
    required this.status,
    required this.scheduledAt,
    required this.createdAt,
    this.inspectorId,
    this.inspectorName,
    this.complaintId,
    this.products = const [],
    this.notes,
    this.completedAt,
  });

  final String id;
  final Business business;
  final InspectionType type;
  final InspectionStatus status;

  final DateTime scheduledAt;
  final DateTime createdAt;

  final String? inspectorId;
  final String? inspectorName;

  /// Citizen complaint reference (from Controller/Citizen web portal).
  final String? complaintId;

  /// Products identified during inspection (`inspection_products`).
  final List<Product> products;

  final String? notes;
  final DateTime? completedAt;

  Inspection copyWith({
    String? id,
    Business? business,
    InspectionType? type,
    InspectionStatus? status,
    DateTime? scheduledAt,
    DateTime? createdAt,
    String? inspectorId,
    String? inspectorName,
    String? complaintId,
    List<Product>? products,
    String? notes,
    DateTime? completedAt,
  }) {
    return Inspection(
      id: id ?? this.id,
      business: business ?? this.business,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      complaintId: complaintId ?? this.complaintId,
      products: products ?? this.products,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Request to create a new inspection. The backend ultimately generates the
/// canonical Inspection ID; mock mode generates a realistic temporary one.
class CreateInspectionRequest {
  const CreateInspectionRequest({
    required this.businessId,
    required this.type,
    this.complaintId,
    this.notes,
  });

  final String businessId;
  final InspectionType type;
  final String? complaintId;
  final String? notes;
}

/// Structured observation recorded before finalisation.
class InspectionObservation {
  const InspectionObservation({
    this.product,
    this.batchOrLot,
    this.declaredQuantity,
    this.observedQuantity,
    this.declaredMrp,
    this.observedMrp,
    this.manufacturerOrPacker,
    this.supplierOrSource,
    this.remarks,
  });

  final String? product;
  final String? batchOrLot;
  final String? declaredQuantity;
  final String? observedQuantity;
  final String? declaredMrp;
  final String? observedMrp;
  final String? manufacturerOrPacker;
  final String? supplierOrSource;
  final String? remarks;

  InspectionObservation copyWith({
    String? product,
    String? batchOrLot,
    String? declaredQuantity,
    String? observedQuantity,
    String? declaredMrp,
    String? observedMrp,
    String? manufacturerOrPacker,
    String? supplierOrSource,
    String? remarks,
  }) {
    return InspectionObservation(
      product: product ?? this.product,
      batchOrLot: batchOrLot ?? this.batchOrLot,
      declaredQuantity: declaredQuantity ?? this.declaredQuantity,
      observedQuantity: observedQuantity ?? this.observedQuantity,
      declaredMrp: declaredMrp ?? this.declaredMrp,
      observedMrp: observedMrp ?? this.observedMrp,
      manufacturerOrPacker: manufacturerOrPacker ?? this.manufacturerOrPacker,
      supplierOrSource: supplierOrSource ?? this.supplierOrSource,
      remarks: remarks ?? this.remarks,
    );
  }
}
