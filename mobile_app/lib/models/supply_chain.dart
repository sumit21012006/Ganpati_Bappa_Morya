/// Supply-chain models — mirrors shared `suppliers`, `purchase_bills`,
/// `purchase_bill_items` and `supply_chain_relationships` tables.
///
/// Flutter only SUBMITS supplier/source declarations and purchase evidence
/// through NestJS; the backend creates supply-chain relationships (and any
/// resulting inspection requirements for suppliers). No direct Neo4j or
/// graph-store access from this app.
library;

import 'package:intl/intl.dart';

class PurchaseBillItem {
  const PurchaseBillItem({
    required this.productName,
    required this.quantity,
    this.unitPrice,
  });

  final String productName;
  final String quantity;
  final double? unitPrice;
}

/// A purchase bill submitted as supply-chain evidence.
class PurchaseBill {
  const PurchaseBill({
    required this.billNumber,
    required this.billDate,
    required this.supplierName,
    required this.items,
    this.totalAmount,
    this.invoiceImagePath,
    this.notes,
  });

  final String billNumber;
  final DateTime billDate;
  final String supplierName;
  final List<PurchaseBillItem> items;
  final double? totalAmount;
  final String? invoiceImagePath;
  final String? notes;

  String get formattedDate => DateFormat('d MMM yyyy').format(billDate);
}

/// Request to record supplier/source information for an inspection.
class SupplierDeclarationRequest {
  const SupplierDeclarationRequest({
    required this.inspectionId,
    required this.supplierName,
    required this.supplierType,
    this.supplierGstin,
    this.supplierAddress,
    this.purchaseBill,
    this.remarks,
  });

  final String inspectionId;
  final String supplierName;
  final String supplierType;
  final String? supplierGstin;
  final String? supplierAddress;
  final PurchaseBill? purchaseBill;
  final String? remarks;
}
