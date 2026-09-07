import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/business.dart';
import '../../../models/supply_chain.dart';

/// Supplier / source declaration — recorded through the backend; creates
/// supply-chain relationships and any resulting inspection assignments
/// for the supplier business.
///
/// Supports searching existing businesses via GET /api/v1/businesses?q=...
/// and sending the real business_id, while keeping the free-text path as a fallback.
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

  // Search & Autocomplete state
  Business? _selectedBusiness;
  List<Business> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  static const _types = [
    'Manufacturer', 'Packer', 'Importer', 'Wholesaler', 'Distributor', 'Retailer',
  ];

  @override
  void initState() {
    super.initState();
    _name.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _name.removeListener(_onNameChanged);
    _name.dispose();
    _gstin.dispose();
    _address.dispose();
    _billNumber.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final query = _name.text.trim();
    if (_selectedBusiness != null && query != _selectedBusiness!.name) {
      setState(() {
        _selectedBusiness = null;
      });
    }

    _debounceTimer?.cancel();
    if (query.length < 2 || _selectedBusiness != null) {
      if (_searchResults.isNotEmpty || _isSearching) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await ref.read(businessRepositoryProvider).searchBusinesses(query, limit: 5);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectBusiness(Business biz) {
    setState(() {
      _selectedBusiness = biz;
      _searchResults = [];
      _name.text = biz.name;
      if (biz.gstin != null && biz.gstin!.isNotEmpty) {
        _gstin.text = biz.gstin!;
      }
      if (biz.location.addressLine.isNotEmpty) {
        _address.text = biz.location.addressLine;
      }
      final typeLabel = biz.type.label;
      if (_types.contains(typeLabel)) {
        _type = typeLabel;
      }
    });
  }

  void _clearSelectedBusiness() {
    setState(() {
      _selectedBusiness = null;
      _searchResults = [];
    });
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
              businessId: _selectedBusiness?.id,
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
        SnackBar(
          content: Text(
            _selectedBusiness != null
                ? 'Supplier "${_selectedBusiness!.name}" (${_selectedBusiness!.id}) linked directly to upstream supply chain.'
                : 'Supplier declaration recorded as unresolved lead. Upstream link created.',
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
              'Search registered businesses to link directly, or enter free-text for unregistered leads.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Supplier business name input with live search indicator
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Supplier business name',
                hintText: 'Type business name or GSTIN...',
                prefixIcon: const Icon(Icons.store_outlined),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _selectedBusiness != null
                        ? IconButton(
                            icon: const Icon(Icons.check_circle, color: AppColors.success),
                            tooltip: 'Linked directly to registered business',
                            onPressed: _clearSelectedBusiness,
                          )
                        : null,
              ),
            ),

            // Active Registered Business Banner
            if (_selectedBusiness != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Linked: ${_selectedBusiness!.name} (${_selectedBusiness!.id})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'GSTIN: ${_selectedBusiness!.gstin ?? "Unregistered"} • ${_selectedBusiness!.location.city}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Clear link and use custom details',
                      onPressed: _clearSelectedBusiness,
                    ),
                  ],
                ),
              ),
            ],

            // Autocomplete Search Results Dropdown List
            if (_selectedBusiness == null && _searchResults.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: _searchResults.map((biz) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.business, size: 20, color: AppColors.primary),
                      title: Text(
                        biz.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        'GSTIN: ${biz.gstin ?? "None"} • ${biz.location.city}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Text(
                        'Select',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () => _selectBusiness(biz),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Fallback indicator when no match found
            if (_selectedBusiness == null &&
                !_isSearching &&
                _name.text.trim().length >= 2 &&
                _searchResults.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Unregistered supplier name. Will be logged as an unresolved lead for Controller review.',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
              label: _selectedBusiness != null ? 'Link Registered Supplier' : 'Submit Declaration',
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
