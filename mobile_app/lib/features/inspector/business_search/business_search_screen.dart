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
                        ? const EmptyState(
                            title: 'No businesses found',
                            message:
                                'Try a different name, GSTIN or city. New registrations appear here after verification.',
                            icon: Icons.storefront_outlined,
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
