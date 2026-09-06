import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/evidence.dart';
import '../../../models/ocr_result.dart';
import '../../../models/violation.dart';
import 'add_violation_sheet.dart';

/// STEP 4 — AI violation review (human-in-the-loop).
///
/// AI findings arrive as POTENTIAL. The inspector must Accept / Reject /
/// Edit each one, and may add violations manually. Confirmation is recorded
/// per-violation through the violation repository.
class ViolationsStep extends ConsumerStatefulWidget {
  const ViolationsStep({
    super.key,
    required this.inspectionId,
    required this.ocrResult,
    required this.evidence,
    required this.onAnyConfirmed,
    this.onViolationsChanged,
    required this.onContinue,
    required this.onBack,
  });

  final String inspectionId;
  final OcrResult? ocrResult;
  final List<EvidenceItem> evidence;
  final VoidCallback onAnyConfirmed;
  final ValueChanged<List<Violation>>? onViolationsChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<ViolationsStep> createState() => _ViolationsStepState();
}

class _ViolationsStepState extends ConsumerState<ViolationsStep> {
  List<Violation>? _violations;
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await ref.read(violationRepositoryProvider).getViolations(widget.inspectionId);
      if (!mounted) return;
      setState(() {
        _violations = list;
        _loading = false;
      });
      widget.onViolationsChanged?.call(list);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.friendlyMessage;
        _loading = false;
      });
    }
  }

  Future<void> _accept(Violation v) async {
    setState(() => _busy.add(v.id));
    try {
      final updated =
          await ref.read(violationRepositoryProvider).confirmViolation(v.id);
      _replace(updated);
      widget.onAnyConfirmed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Violation confirmed by inspector')),
        );
      }
    } on AppException catch (e) {
      _showError(e.friendlyMessage);
    } finally {
      setState(() => _busy.remove(v.id));
    }
  }

  Future<void> _reject(Violation v) async {
    final reasonController = TextEditingController();
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Reject AI finding?',
      message:
          'The finding will be recorded as rejected with your reason. '
          'Rejected findings are excluded from the notice.',
      confirmLabel: 'Reject',
      danger: true,
    );
    if (!confirmed) return;
    setState(() => _busy.add(v.id));
    try {
      final updated = await ref
          .read(violationRepositoryProvider)
          .rejectViolation(v.id, remark: reasonController.text);
      _replace(updated);
    } on AppException catch (e) {
      _showError(e.friendlyMessage);
    } finally {
      setState(() => _busy.remove(v.id));
    }
  }

  Future<void> _edit(Violation v) async {
    final result = await showModalBottomSheet<Violation>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditViolationSheet(violation: v),
    );
    if (result == null) return;
    setState(() => _busy.add(v.id));
    try {
      final updated = await ref.read(violationRepositoryProvider).editViolation(result);
      _replace(updated);
    } on AppException catch (e) {
      _showError(e.friendlyMessage);
    } finally {
      setState(() => _busy.remove(v.id));
    }
  }

  Future<void> _add() async {
    final request = await showModalBottomSheet<AddViolationRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddViolationSheet(),
    );
    if (request == null) return;
    try {
      final created = await ref
          .read(violationRepositoryProvider)
          .addViolation(widget.inspectionId, request);
      setState(() {
        _violations = [...(_violations ?? []), created];
      });
      widget.onAnyConfirmed();
      widget.onViolationsChanged?.call(_violations!);
    } on AppException catch (e) {
      _showError(e.friendlyMessage);
    }
  }

  void _replace(Violation updated) {
    setState(() {
      _violations = (_violations ?? [])
          .map((v) => v.id == updated.id ? updated : v)
          .toList();
    });
    widget.onViolationsChanged?.call(_violations!);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final violations = _violations ?? [];
    final potential = violations.where((v) => v.status == ViolationStatus.potential).length;
    final confirmed = violations.where((v) => v.isConfirmed).length;
    final rejected = violations.where((v) => v.status == ViolationStatus.rejected).length;

    return Column(
      children: [
        Expanded(
          child: _loading
              ? const LoadingView(message: 'Loading AI findings…')
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        const AiAssistanceBanner(),
                        const SizedBox(height: AppSpacing.lg),
                        // Summary chips
                        Row(
                          children: [
                            StatusChip(label: '$potential potential', color: AppColors.warning),
                            const SizedBox(width: AppSpacing.sm),
                            StatusChip(label: '$confirmed confirmed', color: AppColors.success),
                            const SizedBox(width: AppSpacing.sm),
                            StatusChip(label: '$rejected rejected', color: AppColors.textHint),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (violations.isEmpty)
                          const EmptyState(
                            title: 'No violations detected',
                            message:
                                'The AI compliance engine did not flag any '
                                'potential violations for the extracted declarations.',
                            icon: Icons.verified_outlined,
                          )
                        else
                          ...violations.map(
                            (v) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                              child: ViolationCard(
                                violation: v,
                                onAccept:
                                    v.status == ViolationStatus.potential && !_busy.contains(v.id)
                                        ? () => _accept(v)
                                        : null,
                                onReject:
                                    v.status == ViolationStatus.potential && !_busy.contains(v.id)
                                        ? () => _reject(v)
                                        : null,
                                onEdit: !_busy.contains(v.id) ? () => _edit(v) : null,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        SecondaryButton(
                          label: 'Add Violation Manually',
                          icon: Icons.add_moderator_outlined,
                          onPressed: _add,
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

/// Inline edit sheet for a violation.
class _EditViolationSheet extends ConsumerStatefulWidget {
  const _EditViolationSheet({required this.violation});

  final Violation violation;

  @override
  ConsumerState<_EditViolationSheet> createState() => _EditViolationSheetState();
}

class _EditViolationSheetState extends ConsumerState<_EditViolationSheet> {
  late final TextEditingController _description =
      TextEditingController(text: widget.violation.description);
  late final TextEditingController _section =
      TextEditingController(text: widget.violation.ruleSection ?? '');
  late ViolationSeverity _severity = widget.violation.severity;

  @override
  void dispose() {
    _description.dispose();
    _section.dispose();
    super.dispose();
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Violation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _section,
              decoration: const InputDecoration(
                labelText: 'Rule / section',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              children: ViolationSeverity.values.map((s) {
                return ChoiceChip(
                  label: Text(s.label),
                  selected: _severity == s,
                  onSelected: (_) => setState(() => _severity = s),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Save Changes',
              icon: Icons.check,
              onPressed: () {
                Navigator.of(context).pop(widget.violation.copyWith(
                  description: _description.text.trim(),
                  ruleSection: _section.text.trim(),
                  severity: _severity,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
