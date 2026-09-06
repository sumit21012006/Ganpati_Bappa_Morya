import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/self_check.dart';
import '../../../models/violation.dart';

/// PRIVATE self-check history — never shared with inspectors.
class SelfCheckHistoryScreen extends ConsumerStatefulWidget {
  const SelfCheckHistoryScreen({super.key});

  @override
  ConsumerState<SelfCheckHistoryScreen> createState() =>
      _SelfCheckHistoryScreenState();
}

class _SelfCheckHistoryScreenState extends ConsumerState<SelfCheckHistoryScreen> {
  List<SelfCheckReport>? _reports;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final reports = await ref.read(selfCheckRepositoryProvider).getSelfCheckHistory();
      if (!mounted) return;
      setState(() => _reports = reports);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    return AppScaffold(
      title: 'Self-Check History',
      subtitle: 'Private reports',
      body: _reports == null && _error == null
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
                      ),
                      child: PrivateDataBanner(),
                    ),
                    Expanded(
                      child: (_reports ?? []).isEmpty
                          ? const EmptyState(
                              title: 'No self-checks yet',
                              message:
                                  'Run your first private packaging check from the Self Check tab.',
                              icon: Icons.history,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: _reports!.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, i) {
                                final r = _reports![i];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                r.productName,
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            StatusChip(
                                              label: r.resultLabel,
                                              color: r.isCompliant
                                                  ? AppColors.success
                                                  : AppColors.warning,
                                              icon: r.isCompliant
                                                  ? Icons.verified
                                                  : Icons.report_problem_outlined,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${dateFormat.format(r.performedAt)} · ${r.id}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (r.issues.isNotEmpty) ...[
                                          const SizedBox(height: AppSpacing.md),
                                          ...r.issues.map(
                                            (issue) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .remove_circle_outline,
                                                      size: 15,
                                                      color:
                                                          AppColors.warning),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      issue.issue,
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
