import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/evidence.dart';
import '../../../models/ocr_result.dart';

/// STEP 2 — evidence upload + OCR pipeline progress.
///
/// Displays the five pipeline stages with live progress; designed for the
/// asynchronous backend (polling) integration. Retry is offered on failure.
class OcrStep extends ConsumerStatefulWidget {
  const OcrStep({
    super.key,
    required this.evidence,
    required this.inspectionId,
    required this.onCompleted,
    required this.onContinue,
  });

  final List<EvidenceItem> evidence;
  final String inspectionId;
  final ValueChanged<OcrResult> onCompleted;
  final VoidCallback onContinue;

  @override
  ConsumerState<OcrStep> createState() => _OcrStepState();
}

class _OcrStepState extends ConsumerState<OcrStep> {
  int _completedSteps = 0;
  OcrPipelineStep? _current;
  bool _failed = false;
  String? _failureMessage;
  OcrResult? _result;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _completedSteps = 0;
      _current = null;
      _failed = false;
      _failureMessage = null;
      _result = null;
    });
    try {
      final result = await ref.read(ocrRepositoryProvider).analyzePackage(
            ownerId: widget.inspectionId,
            images: widget.evidence,
            onStep: (step) {
              if (!mounted) return;
              final index = OcrPipelineStep.values.indexOf(step);
              setState(() {
                _completedSteps = index;
                _current = step;
              });
            },
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _completedSteps = OcrPipelineStep.values.length;
        _current = null;
      });
      widget.onCompleted(result);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _failureMessage = e.friendlyMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _failureMessage =
            'Image analysis failed. Please retry — unclear photos can also '
            'be retaken from the previous step.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = OcrPipelineStep.values;
    return Column(
      children: [
        Expanded(
          child: _failed
              ? ErrorView(
                  message: _failureMessage ?? 'Image analysis failed.',
                  onRetry: _run,
                  icon: Icons.document_scanner_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: AppColors.aiContainer,
                          shape: BoxShape.circle,
                        ),
                        child: _result != null
                            ? const Icon(Icons.task_alt,
                                size: 40, color: AppColors.aiAccent)
                            : const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(strokeWidth: 2.6),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _result != null ? 'Analysis Complete' : 'Analysing Package…',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${widget.evidence.length} photo(s) submitted for '
                      'AI-assisted declaration extraction. This typically '
                      'takes a few seconds.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Pipeline steps
                    ...List.generate(steps.length, (i) {
                      final step = steps[i];
                      final isDone = i < _completedSteps || _result != null;
                      final isCurrent = _current == step && _result == null;
                      return _PipelineRow(
                        label: step.label,
                        isDone: isDone,
                        isCurrent: isCurrent,
                        isLast: i == steps.length - 1,
                      );
                    }),
                  ],
                ),
        ),
        if (_result != null)
          BottomActionBar(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Review Extracted Information',
                  icon: Icons.receipt_long_outlined,
                  onPressed: widget.onContinue,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : AppColors.outline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? color : AppColors.surface,
              border: Border.all(color: color, width: 2),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : isCurrent
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: isDone || isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isDone || isCurrent
                  ? AppColors.textPrimary
                  : AppColors.textHint,
            ),
          ),
          const Spacer(),
          if (isDone)
            const Text('✓', style: TextStyle(color: AppColors.success, fontSize: 14)),
          if (isCurrent)
            const Text(
              'in progress…',
              style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
            ),
        ],
      ),
    );
  }
}
