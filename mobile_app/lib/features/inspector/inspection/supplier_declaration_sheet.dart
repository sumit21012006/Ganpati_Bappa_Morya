import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/supply_chain.dart';

/// Supplier / source declaration — recorded through NestJS; the backend
/// creates supply-chain relationships and any resulting inspection
/// assignments for the supplier business.
class SupplierDeclarationSheet extends ConsumerStatefulWidget {
  const SupplierDeclarationSheet({super.key, required this.inspectionId});

  final String inspectionId;

  static Future<void> show(BuildContext context, String inspectionId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SupplierDeclarationSheet(inspectionId: inspectionId),
    );
  }

  @override
  ConsumerState<SupplierDeclarationSheet> createState() =>
      _SupplierDeclarationSheetState();
}

class _SupplierDeclarationSheetState
    extends ConsumerState<SupplierDeclarationSheet> {
  final _name = TextEditingController();
  final _gstin = TextEditingController();
  final _address = TextEditingController();
  final _billNumber = TextEditingController();
  String _type = 'Wholesaler';
  bool _submitting = false;
  String? _error;

  static const _types = [
    'Manufacturer', 'Packer', 'Importer', 'Wholesaler', 'Distributor', 'Retailer',
  ];

  @override
  void dispose() {
    _name.dispose();
    _gstin.dispose();
    _address.dispose();
    _billNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter the supplier business name.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(supplyChainRepositoryProvider).submitSupplierDeclaration(
            SupplierDeclarationRequest(
              inspectionId: widget.inspectionId,
              supplierName: _name.text.trim(),
              supplierType: _type,
              supplierGstin: _gstin.text.trim().isEmpty ? null : _gstin.text.trim(),
              supplierAddress: _address.text.trim().isEmpty ? null : _address.text.trim(),
              purchaseBill: _billNumber.text.trim().isEmpty
                  ? null
                  : PurchaseBill(
                      billNumber: _billNumber.text.trim(),
                      billDate: DateTime.now(),
                      supplierName: _name.text.trim(),
                      items: const [],
                    ),
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supplier information recorded. The backend will create the '
            'supply-chain relationship.',
          ),
        ),
      );
    } on AppException catch (e) {
      setState(() {
        _error = e.friendlyMessage;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Declare Supplier / Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Recorded with the inspection; helps trace the supply chain.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Supplier business name',
                prefixIcon: Icon(Icons.store_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Supplier type'),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _gstin,
              decoration: const InputDecoration(
                labelText: 'Supplier GSTIN (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Supplier address (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _billNumber,
              decoration: const InputDecoration(
                labelText: 'Purchase invoice no. (optional)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Submit Declaration',
              icon: Icons.link_outlined,
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
