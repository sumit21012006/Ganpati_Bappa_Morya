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

/// All inspections assigned to the inspector.
class InspectionsScreen extends ConsumerStatefulWidget {
  const InspectionsScreen({super.key});

  @override
  ConsumerState<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends ConsumerState<InspectionsScreen> {
  List<Inspection>? _inspections;
  String? _error;
  String _filter = 'All';

  static const _filters = ['All', 'Active', 'Completed'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await ref.read(inspectionRepositoryProvider).listInspections();
      if (!mounted) return;
      setState(() => _inspections = list);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    return AppScaffold(
      title: 'My Inspections',
      showBack: false,
      body: _inspections == null && _error == null
          ? const LoadingView(message: 'Loading inspections…')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        children: _filters
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.sm + 2),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: _filter == f,
                                  onSelected: (_) => setState(() => _filter = f),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _filtered().isEmpty
                            ? const EmptyState(
                                title: 'No inspections here',
                                message:
                                    'Inspections you create or receive by assignment will appear in this list.',
                                icon: Icons.assignment_outlined,
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                itemCount: _filtered().length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, i) {
                                  final inspection = _filtered()[i];
                                  return Card(
                                    child: ListTile(
                                      onTap: () => context.go(
                                        inspectionDetailPath(inspection.id),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                        vertical: AppSpacing.sm + 2,
                                      ),
                                      title: Text(
                                        inspection.business.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          '${inspection.id} · '
                                          '${dateFormat.format(inspection.scheduledAt)}',
                                          style: const TextStyle(fontSize: 12.5),
                                        ),
                                      ),
                                      trailing: StatusChip(
                                        label: inspection.status.label,
                                        color: inspection.status.isActive
                                            ? AppColors.primary
                                            : AppColors.success,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Inspection> _filtered() {
    final list = _inspections ?? const <Inspection>[];
    return switch (_filter) {
      'Active' => list.where((i) => i.status.isActive).toList(),
      'Completed' => list.where((i) => !i.status.isActive).toList(),
      _ => list,
    };
  }
}
