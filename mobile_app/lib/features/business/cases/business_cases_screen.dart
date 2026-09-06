import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/notice.dart';

/// Business case tracking: current stage, deadline, required action,
/// with the standard lifecycle timeline.
class BusinessCasesScreen extends ConsumerStatefulWidget {
  const BusinessCasesScreen({super.key});

  @override
  ConsumerState<BusinessCasesScreen> createState() => _BusinessCasesScreenState();
}

class _BusinessCasesScreenState extends ConsumerState<BusinessCasesScreen> {
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
      final cases = await ref.read(businessCaseRepositoryProvider).listCases();
      if (!mounted) return;
      setState(() => _cases = cases);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    return AppScaffold(
      title: 'My Cases',
      showBack: false,
      body: _cases == null && _error == null
          ? const LoadingView(message: 'Loading cases…')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: (_cases ?? []).isEmpty
                      ? const EmptyState(
                          title: 'No cases',
                          message:
                              'You have no compliance cases. Preventive self-checks help keep it that way.',
                          icon: Icons.verified_outlined,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _cases!.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) {
                            final c = _cases![i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c.id,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        StatusChip(
                                          label: c.status.label,
                                          color: c.status == CaseStatus.closed
                                              ? AppColors.success
                                              : AppColors.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    KeyValueRow(
                                        label: 'Product', value: c.productName),
                                    KeyValueRow(
                                        label: 'Violation',
                                        value: c.violationSummary),
                                    if (c.deadline != null)
                                      KeyValueRow(
                                        label: 'Deadline',
                                        value: dateFormat.format(c.deadline!),
                                        valueColor: AppColors.error,
                                        isBold: true,
                                      ),
                                    if (c.requiredAction != null)
                                      KeyValueRow(
                                          label: 'Required action',
                                          value: c.requiredAction!),
                                    const SizedBox(height: AppSpacing.lg),
                                    ...c.timeline.map(
                                      (t) => TimelineItem(
                                        title: t.title,
                                        dateTime: t.dateTime,
                                        isDone: t.isDone,
                                        isCurrent: t.isCurrent,
                                        isLast: t == c.timeline.last,
                                        details: t.details,
                                        actor: t.actor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
