import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/inspection.dart';

/// Inspection summary with option to continue the guided flow.
class InspectionDetailScreen extends ConsumerStatefulWidget {
  const InspectionDetailScreen({super.key, required this.inspectionId});

  final String inspectionId;

  @override
  ConsumerState<InspectionDetailScreen> createState() =>
      _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends ConsumerState<InspectionDetailScreen> {
  Inspection? _inspection;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final inspection =
          await ref.read(inspectionRepositoryProvider).getInspection(widget.inspectionId);
      if (!mounted) return;
      setState(() => _inspection = inspection);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final inspection = _inspection;
    if (inspection == null) {
      return AppScaffold(
        title: 'Inspection Details',
        body: _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : const LoadingView(),
      );
    }
    return AppScaffold(
      title: 'Inspection Details',
      subtitle: inspection.id,
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    InfoCard(
                      title: inspection.business.name,
                      trailing: StatusChip(
                        label: inspection.status.label,
                        color: inspection.status.isActive
                            ? AppColors.primary
                            : AppColors.success,
                      ),
                      children: [
                        KeyValueRow(label: 'Inspection ID', value: inspection.id),
                        KeyValueRow(label: 'Type', value: inspection.type.label),
                        KeyValueRow(
                            label: 'Scheduled',
                            value: dateFormat.format(inspection.scheduledAt)),
                        if (inspection.complaintId != null)
                          KeyValueRow(
                              label: 'Complaint', value: inspection.complaintId!),
                        KeyValueRow(
                            label: 'Officer',
                            value: inspection.inspectorName ?? '—'),
                        KeyValueRow(
                            label: 'Address',
                            value: inspection.business.location.singleLine),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (inspection.products.isNotEmpty)
                      InfoCard(
                        title: 'Products under inspection',
                        children: inspection.products
                            .map((p) => KeyValueRow(label: p.category ?? 'Product',
                                value: p.name))
                            .toList(),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    if (inspection.status.isActive)
                      PrimaryButton(
                        label: inspection.status == InspectionStatus.assigned
                            ? 'Start Inspection'
                            : 'Continue Inspection',
                        icon: Icons.play_arrow,
                        onPressed: () => context.go(
                          inspectionFlowPath(inspection.id),
                        ),
                      ),
                  ],
                ),
    );
  }
}
