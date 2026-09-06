import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../data/mock_data.dart';
import '../../../di/providers.dart';
import '../../../models/inspection.dart';
import '../../../models/notice.dart';
import '../../../models/violation.dart';

/// STEP 7 — notice generation, review and edit.
///
/// Generation is requested through NestJS (NLP draft — Member 4). The draft
/// is displayed as AI-GENERATED and must be reviewed/edited by the
/// inspector before signature.
class NoticeStep extends ConsumerStatefulWidget {
  const NoticeStep({
    super.key,
    required this.inspectionId,
    required this.inspection,
    required this.violations,
    required this.onNoticeIssued,
    required this.onBack,
  });

  final String inspectionId;
  final Inspection? inspection;
  final List<Violation> violations;
  final ValueChanged<Notice> onNoticeIssued;
  final VoidCallback onBack;

  @override
  ConsumerState<NoticeStep> createState() => _NoticeStepState();
}

class _NoticeStepState extends ConsumerState<NoticeStep> {
  Notice? _draft;
  bool _generating = false;
  String? _error;
  NoticeType _selectedType = NoticeType.improvement;
  bool _selectedForNotice = false;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final confirmed = widget.violations.where((v) => v.isConfirmed).toList();
      final notice = await ref.read(noticeRepositoryProvider).generateNotice(
            GenerateNoticeRequest(
              inspectionId: widget.inspectionId,
              noticeType: _selectedType,
              confirmedViolations: confirmed,
              remarks: 'Issued during field inspection.',
            ),
          );
      if (!mounted) return;
      setState(() {
        _draft = notice;
        _generating = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.friendlyMessage;
        _generating = false;
      });
    }
  }

  Future<void> _addSection(Notice notice) async {
    final selected = await showDialog<NoticeSection>(
      context: context,
      builder: (context) => _SectionPickerDialog(exclude: notice.sections),
    );
    if (selected == null) return;
    try {
      final updated = await ref
          .read(noticeRepositoryProvider)
          .addSection(notice.id, selected);
      setState(() => _draft = updated);
    } on AppException catch (e) {
      _snack(e.friendlyMessage);
    }
  }

  Future<void> _saveEdits(Notice notice, String bodyText, String remark) async {
    try {
      final updated = await ref.read(noticeRepositoryProvider).editNotice(
            notice.copyWith(bodyText: bodyText, inspectorRemark: remark),
          );
      setState(() => _draft = updated);
      _snack('Notice updated');
    } on AppException catch (e) {
      _snack(e.friendlyMessage);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    final confirmedViolations =
        widget.violations.where((v) => v.isConfirmed).toList();

    if (_draft == null && !_generating && _error == null) {
      return _buildSelectionView(context, confirmedViolations);
    }

    return Column(
      children: [
        Expanded(
          child: _generating
              ? const LoadingView(
                  message:
                      'Generating notice draft with AI/NLP. This may take a '
                      'few seconds…')
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _generate)
                  : _buildDraftReview(context, dateFormat),
        ),
        if (_draft != null)
          BottomActionBar(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Continue to Signature',
                  icon: Icons.draw_outlined,
                  onPressed: () async {
                    final confirmed = await ConfirmationDialog.show(
                      context,
                      title: 'Confirm notice review',
                      message:
                          'You have reviewed the draft. Proceed to sign and '
                          'issue this notice?',
                      confirmLabel: 'Proceed',
                    );
                    if (confirmed) widget.onNoticeIssued(_draft!);
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSelectionView(
    BuildContext context,
    List<Violation> confirmedViolations,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SectionHeader(
          title: 'Generate Notice',
          subtitle:
              'An AI/NLP draft will be prepared from the confirmed violations',
        ),
        ...NoticeType.values.map(
          (t) => RadioListTile<NoticeType>(
            title: Text(t.label),
            value: t,
            groupValue: _selectedType,
            onChanged: (v) => setState(() => _selectedType = v!),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (confirmedViolations.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Text(
              'No violations are confirmed yet. You can still generate a '
              'notice, but confirm violations first for a complete draft.',
              style: TextStyle(fontSize: 13, color: AppColors.onTertiaryContainer),
            ),
          )
        else
          InfoCard(
            title: 'Violations to be cited',
            children: confirmedViolations
                .map((v) => KeyValueRow(
                      label: v.severity.label,
                      value: v.type.defaultLabel,
                    ))
                .toList(),
          ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Generate Draft Notice',
          icon: Icons.auto_awesome,
          isLoading: _generating,
          onPressed: _generate,
        ),
      ],
    );
  }

  Widget _buildDraftReview(BuildContext context, DateFormat dateFormat) {
    final notice = _draft!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // AI draft banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.aiContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.aiAccent.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: AppColors.aiAccent),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'AI-GENERATED DRAFT — INSPECTOR VERIFICATION REQUIRED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.aiAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        InfoCard(
          title: notice.type.label,
          trailing: StatusChip(label: notice.status.label, color: AppColors.textHint),
          children: [
            KeyValueRow(label: 'Notice ID', value: notice.id),
            KeyValueRow(label: 'Case ID', value: notice.caseId),
            KeyValueRow(label: 'Business', value: notice.businessName),
            KeyValueRow(label: 'Product', value: notice.productName),
            KeyValueRow(label: 'Issued on', value: dateFormat.format(notice.issuedDate)),
            if (notice.deadline != null)
              KeyValueRow(
                label: 'Compliance deadline',
                value: dateFormat.format(notice.deadline!),
                valueColor: AppColors.error,
                isBold: true,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Sections
        SectionHeader(
          title: 'Cited sections (${notice.sections.length})',
          actionLabel: 'Add section',
          onAction: () => _addSection(notice),
        ),
        ...notice.sections.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InfoCard(
              title: s.citation,
              trailing: s.isAddedByInspector
                  ? const StatusChip(
                      label: 'ADDED BY INSPECTOR',
                      color: AppColors.secondary,
                      showDot: false,
                    )
                  : null,
              children: [
                Text(
                  s.title,
                  style: const TextStyle(fontSize: 13.5),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Editable body
        SectionHeader(
          title: 'Notice body',
          actionLabel: 'Edit',
          onAction: () => _editBodyDialog(context, notice),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Text(
            notice.bodyText ?? '—',
            style: const TextStyle(fontSize: 13.5, height: 1.55),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _editBodyDialog(BuildContext context, Notice notice) async {
    final bodyController = TextEditingController(text: notice.bodyText ?? '');
    final remarkController =
        TextEditingController(text: notice.inspectorRemark ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit notice'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: bodyController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Notice body text',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: remarkController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Inspector remarks',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await _saveEdits(notice, bodyController.text, remarkController.text);
    }
  }
}

/// Section picker from the Legal Knowledge Base library (Member 5).
class _SectionPickerDialog extends StatelessWidget {
  const _SectionPickerDialog({required this.exclude});

  final List<NoticeSection> exclude;

  @override
  Widget build(BuildContext context) {
    final available = noticeSectionLibrary
        .where((s) => !exclude.any((e) => e.citation == s.citation))
        .toList();
    return AlertDialog(
      title: const Text('Add section'),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: available.isEmpty
            ? const Center(child: Text('All library sections already cited.'))
            : ListView(
                children: available
                    .map(
                      (s) => ListTile(
                        title: Text(s.citation,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w700)),
                        subtitle: Text(s.title,
                            style: const TextStyle(fontSize: 12.5)),
                        onTap: () => Navigator.pop(context, s),
                      ),
                    )
                    .toList(),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
