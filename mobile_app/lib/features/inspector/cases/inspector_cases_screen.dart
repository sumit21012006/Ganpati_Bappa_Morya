import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/notice.dart';

/// Inspector case list across the enforcement lifecycle.
class InspectorCasesScreen extends ConsumerStatefulWidget {
  const InspectorCasesScreen({super.key});

  @override
  ConsumerState<InspectorCasesScreen> createState() =>
      _InspectorCasesScreenState();
}

class _InspectorCasesScreenState extends ConsumerState<InspectorCasesScreen> {
  List<LegalCase>? _cases;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final cases = await ref.read(caseRepositoryProvider).listCases();
      if (!mounted) return;
      setState(() => _cases = cases);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    }
  }

  Color _statusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.closed:
        return AppColors.success;
      case CaseStatus.disputed:
        return AppColors.error;
      case CaseStatus.awaitingPayment:
      case CaseStatus.compounding:
        return AppColors.aiAccent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    return AppScaffold(
      title: 'Cases',
      showBack: false,
      body: _cases == null && _error == null
          ? const LoadingView(message: 'Loading cases…')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: (_cases ?? []).isEmpty
                      ? const EmptyState(
                          title: 'No cases yet',
                          message:
                              'Cases appear here once notices are issued from inspections.',
                          icon: Icons.folder_copy_outlined,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _cases!.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) {
                            final c = _cases![i];
                            return Card(
                              child: ListTile(
                                onTap: () => context.go(caseDetailPath(c.id)),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm + 2,
                                ),
                                title: Text(
                                  c.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    '${c.productName}\n'
                                    'Opened ${dateFormat.format(c.openedAt)} · '
                                    '${c.counterpartyName}',
                                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: StatusChip(
                                  label: c.status.label,
                                  color: _statusColor(c.status),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
