import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/inspection.dart';
import '../../../models/ocr_result.dart';
import '../../../models/offence_history.dart';

/// STEP 5 — previous product offence history.
///
/// The backend resolves product identity (normalisation/matching) and
/// returns previous offence records. Flutter displays only — no local
/// offence logic.
class OffenceStep extends ConsumerStatefulWidget {
  const OffenceStep({
    super.key,
    required this.ocrResult,
    required this.inspection,
    required this.onContinue,
    required this.onBack,
  });

  final OcrResult? ocrResult;
  final Inspection? inspection;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<OffenceStep> createState() => _OffenceStepState();
}

class _OffenceStepState extends ConsumerState<OffenceStep> {
  OffenceHistory? _history;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final productName =
          widget.ocrResult?.fields.where((f) => f.key == OcrFieldKeys.productName).firstOrNull?.value ??
              'Unknown product';
      final history = await ref
          .read(offenceRepositoryProvider)
          .getProductOffenceHistoryForBusiness(
            productName,
            widget.inspection?.business.id ?? '',
          );
      if (!mounted) return;
      setState(() {
        _history = history;
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    return Column(
      children: [
        Expanded(
          child: _loading
              ? const LoadingView(
                  message:
                      'Checking previous offence history for this product…')
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _lookup)
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        _history!.hasPreviousOffence
                            ? Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.history,
                                        size: 28, color: AppColors.error),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'PREVIOUS OFFENCE FOUND',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.4,
                                              color: AppColors.onErrorContainer,
                                            ),
                                          ),
                                          Text(
                                            _history!.tier.label,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.onErrorContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.successContainer,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 28, color: AppColors.success),
                                    const SizedBox(width: AppSpacing.md),
                                    const Expanded(
                                      child: Text(
                                        'No previous offence found for this product.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        const SizedBox(height: AppSpacing.lg),
                        InfoCard(
                          title: 'Product match',
                          children: [
                            KeyValueRow(
                              label: 'Matched product',
                              value: _history!.matchedProductName,
                            ),
                            if (_history!.matchConfidence != null)
                              KeyValueRow(
                                label: 'Match confidence',
                                value:
                                    '${(_history!.matchConfidence! * 100).round()}%',
                              ),
                            KeyValueRow(
                              label: 'Checked at',
                              value: dateFormat.format(_history!.checkedAt),
                            ),
                          ],
                        ),
                        if (_history!.records.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const SectionHeader(title: 'Previous cases'),
                          ..._history!.records.map(
                            (r) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: InfoCard(
                                title: r.caseId,
                                trailing: StatusChip(
                                  label: r.caseStatus,
                                  color: AppColors.warning,
                                ),
                                children: [
                                  KeyValueRow(
                                      label: 'Business', value: r.businessName),
                                  KeyValueRow(label: 'Location', value: r.location),
                                  KeyValueRow(
                                      label: 'Date',
                                      value: dateFormat.format(r.date)),
                                  KeyValueRow(
                                      label: 'Violation',
                                      value: r.violationSummary),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        const AiAssistanceBanner(
                          message:
                              'Product identity is resolved by the backend '
                              'matching service. Offence tiers follow the '
                              'shared case history.',
                        ),
                      ],
                    ),
        ),
        BottomActionBar(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: widget.onContinue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
