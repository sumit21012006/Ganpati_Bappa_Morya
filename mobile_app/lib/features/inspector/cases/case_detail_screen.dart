import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/notice.dart';

/// Case detail with the visual timeline (only backend-returned states are
/// shown) plus the required next action for the inspector.
class CaseDetailScreen extends ConsumerStatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  LegalCase? _case;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final c = await ref.read(caseRepositoryProvider).getCase(widget.caseId);
      if (!mounted) return;
      setState(() => _case = c);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _case;
    final dateFormat = DateFormat('d MMM yyyy');
    if (c == null) {
      return const AppScaffold(
        title: 'Case Detail',
        body: LoadingView(),
      );
    }
    return AppScaffold(
      title: 'Case Detail',
      subtitle: c.id,
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    InfoCard(
                      title: c.productName,
                      trailing: StatusChip(
                        label: c.status.label,
                        color: AppColors.primary,
                      ),
                      children: [
                        KeyValueRow(label: 'Case ID', value: c.id),
                        KeyValueRow(label: 'Business', value: c.counterpartyName),
                        KeyValueRow(
                            label: 'Opened', value: dateFormat.format(c.openedAt)),
                        if (c.deadline != null)
                          KeyValueRow(
                            label: 'Deadline',
                            value: dateFormat.format(c.deadline!),
                            valueColor: AppColors.error,
                            isBold: true,
                          ),
                        KeyValueRow(
                            label: 'Violation', value: c.violationSummary),
                      ],
                    ),
                    if (c.requiredAction != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.infoContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flag_outlined,
                                size: 20, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Required action: ${c.requiredAction!}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(title: 'Case Timeline'),
                    ...List.generate(c.timeline.length, (i) {
                      final t = c.timeline[i];
                      return TimelineItem(
                        title: t.title,
                        dateTime: t.dateTime,
                        isDone: t.isDone,
                        isCurrent: t.isCurrent,
                        isLast: i == c.timeline.length - 1,
                        details: t.details,
                        actor: t.actor,
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
    );
  }
}
