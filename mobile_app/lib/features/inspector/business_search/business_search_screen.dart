import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/business.dart';
import '../../../models/inspection.dart';

/// Business search — by name, GSTIN, or location. Entry point for
/// starting a new inspection.
class BusinessSearchScreen extends ConsumerStatefulWidget {
  const BusinessSearchScreen({super.key});

  @override
  ConsumerState<BusinessSearchScreen> createState() =>
      _BusinessSearchScreenState();
}

class _BusinessSearchScreenState extends ConsumerState<BusinessSearchScreen> {
  final _controller = TextEditingController();
  List<Business>? _results;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results =
          await ref.read(businessRepositoryProvider).searchBusinesses(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.friendlyMessage;
        _loading = false;
      });
    }
  }

  
  void _openAddBusinessSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddBusinessSheet(
        onCreated: (newBiz) {
          setState(() {
            _results = [newBiz, ...?_results];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Business "${newBiz.name}" added on the spot! Ready for inspection.'),
              backgroundColor: AppColors.success,
            ),
          );
          _openStartInspection(newBiz);
        },
      ),
    );
  }

  void _openStartInspection(Business business) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StartInspectionSheet(business: business),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Businesses',
      subtitle: 'Search by name, GSTIN, owner or city',
      showBack: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_business_outlined),
          tooltip: 'Add on Spot',
          onPressed: _openAddBusinessSheet,
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_business),
        label: const Text('Add on Spot'),
        onPressed: _openAddBusinessSheet,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search businesses…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView(message: 'Searching…')
                : _error != null
                    ? ErrorView(message: _error!, onRetry: () => _search(_controller.text))
                    : (_results == null || _results!.isEmpty)
                        ? EmptyState(
                            title: 'No businesses found',
                            message:
                                'Business not registered yet? Add it on the spot to start an immediate raid inspection.',
                            icon: Icons.storefront_outlined,
                            actionLabel: 'Add Business on Spot',
                            onAction: _openAddBusinessSheet,
                          )
                        : RefreshIndicator(
                            onRefresh: () => _search(_controller.text),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl,
                              ),
                              itemCount: _results!.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, i) =>
                                  _BusinessCard(
                                business: _results![i],
                                onStart: () => _openStartInspection(_results![i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business, required this.onStart});

  final Business business;
  final VoidCallback onStart;

  Color get _statusColor => switch (business.status) {
        BusinessStatus.active => AppColors.success,
        BusinessStatus.pending => AppColors.warning,
        BusinessStatus.suspended => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${business.type.label} · ${business.location.city}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(label: business.status.label, color: _statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            KeyValueRow(label: 'GSTIN', value: business.gstin ?? 'Not provided'),
            KeyValueRow(
              label: 'Address',
              value: business.location.singleLine,
            ),
            KeyValueRow(label: 'Owner', value: business.ownerName ?? '—'),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Start Inspection',
              icon: Icons.photo_camera_outlined,
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}

class _StartInspectionSheet extends ConsumerStatefulWidget {
  const _StartInspectionSheet({required this.business});

  final Business business;

  @override
  ConsumerState<_StartInspectionSheet> createState() =>
      _StartInspectionSheetState();
}

class _StartInspectionSheetState extends ConsumerState<_StartInspectionSheet> {
  InspectionType _type = InspectionType.routine;
  final _complaintController = TextEditingController();
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final inspection = await ref.read(inspectionRepositoryProvider).createInspection(
            CreateInspectionRequest(
              businessId: widget.business.id,
              type: _type,
              complaintId:
                  _type == InspectionType.complaintBased && _complaintController.text.isNotEmpty
                      ? _complaintController.text.trim()
                      : null,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/inspector/inspection-flow/${inspection.id}');
    } on AppException catch (e) {
      setState(() {
        _error = e.friendlyMessage;
        _creating = false;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Start Inspection',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            widget.business.name,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...InspectionType.values.map(
            (t) => RadioListTile<InspectionType>(
              title: Text(t.label),
              subtitle: Text(t.description, style: const TextStyle(fontSize: 12.5)),
              value: t,
              groupValue: _type,
              onChanged: (v) => setState(() => _type = v!),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (_type == InspectionType.complaintBased) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _complaintController,
              decoration: const InputDecoration(
                labelText: 'Complaint ID (e.g. CMP/2026/0891)',
                prefixIcon: Icon(Icons.report_outlined),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'The Inspection ID is generated by the backend and associated '
            'with your officer account, the business, and the timestamp.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Begin Inspection',
            icon: Icons.play_arrow,
            isLoading: _creating,
            onPressed: _create,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}


class _AddBusinessSheet extends ConsumerStatefulWidget {
  const _AddBusinessSheet({required this.onCreated});

  final ValueChanged<Business> onCreated;

  @override
  ConsumerState<_AddBusinessSheet> createState() => _AddBusinessSheetState();
}

class _AddBusinessSheetState extends ConsumerState<_AddBusinessSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _latController = TextEditingController(text: '19.0760');
  final _lngController = TextEditingController(text: '72.8777');
  final _districtController = TextEditingController(text: 'Mumbai');

  BusinessType _selectedType = BusinessType.retailer;
  bool _submitting = false;
  bool _gpsDetected = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _phoneController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _detectGps() {
    setState(() {
      _latController.text = '18.5204';
      _lngController.text = '73.8567';
      _districtController.text = 'Pune';
      _gpsDetected = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device GPS acquired: 18.5204 N, 73.8567 E (Pune)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());

      final newBiz = await ref.read(businessRepositoryProvider).quickAddBusiness(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            type: _selectedType,
            gstin: _gstinController.text.trim().isNotEmpty ? _gstinController.text.trim() : null,
            contactPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
            latitude: lat,
            longitude: lng,
            district: _districtController.text.trim().isNotEmpty ? _districtController.text.trim() : 'Mumbai',
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated(newBiz);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.friendlyMessage;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to add business: $e';
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.add_business, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Text(
                            'Add Business on Spot',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Raid mode: quickly record an unverified/unregistered vendor to start inspection immediately.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Business / Trade Name *',
                  hintText: 'e.g. Ramesh Kirana Stores',
                  prefixIcon: Icon(Icons.storefront),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter business name' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<BusinessType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Business Type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: BusinessType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Premises Address *',
                  hintText: 'Shop No, Street, Landmark, Market Area',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full premises address' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outline.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _gpsDetected ? Icons.my_location : Icons.location_searching,
                                color: _gpsDetected ? AppColors.success : AppColors.textHint,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  'GPS Coordinates',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.gps_fixed, size: 15),
                          label: const Text('Capture', style: TextStyle(fontSize: 12)),
                          onPressed: _detectGps,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _gstinController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'GSTIN (Optional)',
                  hintText: 'Leave empty if vendor is unregistered',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone (Optional)',
                  hintText: 'Vendor / Representative phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: 'Save & Start Inspection',
                icon: Icons.check_circle_outline,
                isLoading: _submitting,
                onPressed: _submit,
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
