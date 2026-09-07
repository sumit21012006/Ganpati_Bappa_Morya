import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/evidence.dart';
import '../../../models/ocr_result.dart';
import '../../../models/self_check.dart';
import '../../../models/violation.dart' show ViolationSeverity, ViolationSeverityX;
import '../../shared/camera_capture_screen.dart';

/// BUSINESS SELF-COMPLIANCE CHECK — the preventive differentiator.
///
/// PRIVATE: results never create cases or offences and are never shown to
/// inspectors. The banner below is repeated on every self-check surface.
class SelfCheckScreen extends ConsumerStatefulWidget {
  const SelfCheckScreen({super.key});

  @override
  ConsumerState<SelfCheckScreen> createState() => _SelfCheckScreenState();
}

class _SelfCheckScreenState extends ConsumerState<SelfCheckScreen> {
  final List<EvidenceItem> _evidence = [];
  final _productNameController = TextEditingController(text: '');
  SelfCheckReport? _report;
  OcrPipelineStep? _currentStep;
  bool _running = false;
  String? _error;

  @override
  void dispose() {
    _productNameController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final path = await CameraCaptureScreen.capture(
      context,
      title: 'Capture package side',
    );
    if (path == null) return;
    setState(() {
      _evidence.add(EvidenceItem(
        id: 'evd-${DateTime.now().millisecondsSinceEpoch}',
        filePath: path,
        side: PackageSide.other,
        capturedAt: DateTime.now(),
      ));
    });
  }

  Future<void> _runCheck() async {
    if (_evidence.isEmpty) return;
    setState(() {
      _running = true;
      _error = null;
      _report = null;
    });
    try {
      final report = await ref.read(selfCheckRepositoryProvider).performSelfCheck(
            PerformSelfCheckRequest(
              imagePaths: _evidence.map((e) => e.filePath).toList(),
              productNameHint: _productNameController.text.trim().isEmpty
                  ? 'Unspecified product'
                  : _productNameController.text.trim(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _report = report;
        _running = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Self-check could not be completed. Please retry.';
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Self Compliance Check',
      subtitle: 'Check packaging before selling — private to you',
      showBack: false,
      body: _running
          ? _buildProcessing()
          : _report != null
              ? _buildResult(context, _report!)
              : _buildCapture(context),
    );
  }

  Widget _buildCapture(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PrivateDataBanner(),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(
          title: 'Photograph your package',
          subtitle: '2–3 clear sides give the most accurate analysis',
        ),
        if (_evidence.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _evidence.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, i) => EvidenceCard(
              imagePath: _evidence[i].filePath,
              sideLabel: _evidence[i].side.label,
              capturedAtLabel: '',
              onDelete: () => setState(() => _evidence.removeAt(i)),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: _evidence.isEmpty ? 'Capture Package Photo' : 'Add Another Photo',
          icon: Icons.add_a_photo_outlined,
          onPressed: _capture,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _productNameController,
          decoration: const InputDecoration(
            labelText: 'Product name (optional)',
            hintText: 'e.g. House Blend Chilli Powder 500 g',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Run Compliance Check',
          icon: Icons.fact_check_outlined,
          onPressed: _evidence.isEmpty ? null : _runCheck,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What is checked?',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              const Text(
                '• MRP declaration and format\n'
                '• Net quantity and standard units\n'
                '• Consumer-care details\n'
                '• Manufacturer / packer declarations\n'
                '• Month & year of manufacture\n'
                '• Country of origin (imports)',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    const steps = OcrPipelineStep.values;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Center(
          child: SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(strokeWidth: 2.8),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Analysing your packaging…',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xl),
        ...steps.map((s) => _ProcessingRow(
              label: s.label,
              isDone: _currentStep != null &&
                  steps.indexOf(_currentStep!) > steps.indexOf(s),
              isCurrent: _currentStep == s,
            )),
        const SizedBox(height: AppSpacing.xxl),
        const PrivateDataBanner(),
      ],
    );
  }

  Widget _buildResult(BuildContext context, SelfCheckReport report) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Result banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: report.isCompliant ? AppColors.successContainer : AppColors.warningContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            children: [
              Icon(
                report.isCompliant ? Icons.verified : Icons.report_problem_outlined,
                size: 48,
                color: report.isCompliant ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                report.isCompliant ? 'COMPLIANT' : 'POTENTIAL ISSUES FOUND',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: report.isCompliant
                      ? AppColors.onSecondaryContainer
                      : AppColors.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                report.productName,
                style: TextStyle(
                  fontSize: 13,
                  color: report.isCompliant
                      ? AppColors.onSecondaryContainer
                      : AppColors.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const PrivateDataBanner(),
        const SizedBox(height: AppSpacing.xl),

        if (report.issues.isEmpty)
          const EmptyState(
            title: 'No issues found',
            message:
                'The analysed declarations meet the packaging requirements. '
                'Keep monitoring each new print run.',
            icon: Icons.verified_outlined,
          )
        else ...[
          const SectionHeader(title: 'Recommended corrections'),
          ...report.issues.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: InfoCard(
                  title: issue.field,
                  trailing: StatusChip(
                    label: issue.severity.label,
                    color: issue.severity == ViolationSeverity.medium
                        ? AppColors.warning
                        : AppColors.info,
                  ),
                  children: [
                    Text(
                      issue.issue,
                      style: const TextStyle(fontSize: 13.5, height: 1.45),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REQUIREMENT',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            issue.requirement,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.build_circle_outlined,
                            size: 17, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            issue.recommendedCorrection,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(
          label: 'Run Another Check',
          icon: Icons.replay,
          onPressed: () => setState(() {
            _report = null;
            _evidence.clear();
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ProcessingRow extends StatelessWidget {
  const _ProcessingRow({
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle
                : isCurrent
                    ? Icons.timelapse
                    : Icons.radio_button_unchecked,
            size: 20,
            color: isDone
                ? AppColors.success
                : isCurrent
                    ? AppColors.primary
                    : AppColors.outline,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: isDone || isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isDone || isCurrent ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
