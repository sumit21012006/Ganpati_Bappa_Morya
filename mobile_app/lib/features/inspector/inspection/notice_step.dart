import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/mock_data.dart';
import '../../../di/providers.dart';
import '../../../models/inspection.dart';
import '../../../models/notice.dart';
import '../../../models/violation.dart';

/// STEP 7 — Statutory Notice & Document Generation (Official GOI / Maharashtra Format).
/// Multi-select allowed (e.g. Seizure Notice + Improvement Notice).
/// Official PDF and Word documents generated matching Compounding_SAMPLE_GENERATED.pdf.
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

  // Multi-select notice types. "Official Notice" (other) removed.
  static const List<NoticeType> _availableTypes = [
    NoticeType.improvement,
    NoticeType.seizure,
    NoticeType.compounding,
    NoticeType.panchanama,
  ];

  final Set<NoticeType> _selectedTypes = {NoticeType.improvement};

  String _resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    var base = AppConstants.apiBaseUrl;
    if (base.contains('/api/v1')) {
      base = base.split('/api/v1').first;
    } else if (base.contains('/api/v')) {
      base = base.split('/api/v').first;
    }
    final cleanBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBase$cleanPath';
  }

  Future<void> _openDocument(String? url, String docType) async {
    if (url == null || url.isEmpty) {
      _snack('Document URL is not available.');
      return;
    }
    final fullUrl = _resolveUrl(url);
    try {
      final uri = Uri.parse(fullUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _snack('Could not open document URL: $fullUrl');
      }
    } catch (e) {
      _snack('Error opening $docType: $e');
    }
  }

  Future<void> _generate() async {
    if (_selectedTypes.isEmpty) {
      _snack('Please select at least one statutory notice to generate.');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final confirmed = widget.violations.where((v) => v.isConfirmed).toList();
      final notice = await ref.read(noticeRepositoryProvider).generateNotice(
            GenerateNoticeRequest(
              inspectionId: widget.inspectionId,
              noticeType: _selectedTypes.first,
              noticeTypes: _selectedTypes.toList(),
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Notice generation failed: $e';
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
      _snack('Notice updated successfully.');
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
                      'Generating official Government Notice & Orders in PDF and Word format '
                      'matching official Legal Metrology standards…')
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
                          'You have reviewed the official statutory draft notice. '
                          'Proceed to draw digital signature and seal the order?',
                      confirmLabel: 'Proceed to Sign',
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
          title: 'Select Statutory Notices',
          subtitle:
              'Choose one or multiple official notices to generate simultaneously (e.g. Seizure Memo + Improvement Notice)',
        ),
        const SizedBox(height: AppSpacing.sm),

        // Multi-select checkbox cards for official notices
        ..._availableTypes.map((type) {
          final isSelected = _selectedTypes.contains(type);
          String subtitle = switch (type) {
            NoticeType.improvement =>
              'Directs trader to rectify packaging non-compliances within 15 days (Section 15(6)).',
            NoticeType.seizure =>
              'Official receipt and detention memo for sample packages seized as legal evidence (Section 15).',
            NoticeType.compounding =>
              'Statutory compounding determination under Section 48(3) with GRAS portal deposit order.',
            NoticeType.panchanama =>
              'Spot Panchanama recorded in presence of two independent Panch witnesses (Section 15(4) / CrPC).',
            _ => '',
          };

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: CheckboxListTile(
              value: isSelected,
              title: Text(
                type.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              secondary: Icon(
                switch (type) {
                  NoticeType.improvement => Icons.assignment_late_outlined,
                  NoticeType.seizure => Icons.inventory_2_outlined,
                  NoticeType.compounding => Icons.account_balance_outlined,
                  NoticeType.panchanama => Icons.groups_outlined,
                  _ => Icons.description_outlined,
                },
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              onChanged: (bool? val) {
                setState(() {
                  if (val == true) {
                    _selectedTypes.add(type);
                  } else {
                    if (_selectedTypes.length > 1) {
                      _selectedTypes.remove(type);
                    } else {
                      _snack('At least one notice type must remain selected.');
                    }
                  }
                });
              },
            ),
          );
        }),

        const SizedBox(height: AppSpacing.md),

        if (confirmedViolations.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.onTertiaryContainer, size: 20),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'No confirmed violations detected. Standard statutory clauses will be populated in the draft.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          )
        else
          InfoCard(
            title: 'Violations Cited in Notice (${confirmedViolations.length})',
            children: confirmedViolations
                .map((v) => KeyValueRow(
                      label: v.severity.label,
                      value: v.type.defaultLabel,
                    ))
                .toList(),
          ),

        const SizedBox(height: AppSpacing.xl),

        PrimaryButton(
          label: 'Generate Official Government Notices',
          icon: Icons.picture_as_pdf_outlined,
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
        // Government header banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GOVERNMENT OF MAHARASHTRA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'LEGAL METROLOGY ORGANISATION — OFFICIAL STATUTORY DRAFT',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Document Details Card
        InfoCard(
          title: notice.type.label,
          trailing: const StatusChip(label: 'DRAFT READY', color: AppColors.warning),
          children: [
            KeyValueRow(label: 'Notice ID', value: notice.id),
            KeyValueRow(label: 'Case ID', value: notice.caseId),
            KeyValueRow(label: 'Establishment', value: notice.businessName),
            KeyValueRow(label: 'Commodity', value: notice.productName),
            KeyValueRow(label: 'Date of Order', value: dateFormat.format(notice.issuedDate)),
            if (notice.deadline != null)
              KeyValueRow(
                label: 'Compliance Deadline',
                value: dateFormat.format(notice.deadline!),
                valueColor: AppColors.error,
                isBold: true,
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Official Document Download & Preview Actions Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.file_present_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Official Generated Documents',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Formatted strictly per Government of Maharashtra Legal Metrology notification standards.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  // PDF Preview Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('View PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => _openDocument(notice.pdfUrl, 'PDF Document'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Word DOCX Download Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade800,
                        side: BorderSide(color: Colors.blue.shade800),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      icon: const Icon(Icons.description, size: 18),
                      label: const Text('Download Word', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => _openDocument(notice.docxUrl, 'Word Document'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Cited Legal Sections
        SectionHeader(
          title: 'Cited Statutory Sections (${notice.sections.length})',
          actionLabel: 'Add section',
          onAction: () => _addSection(notice),
        ),
        ...notice.sections.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InfoCard(
              title: s.citation,
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

        // Notice Body Preview
        SectionHeader(
          title: 'Statutory Notice Body',
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
        title: const Text('Edit Notice Content'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: bodyController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Notice Statutory Body Text',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: remarkController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Inspector Remarks',
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

class _SectionPickerDialog extends StatelessWidget {
  const _SectionPickerDialog({required this.exclude});

  final List<NoticeSection> exclude;

  @override
  Widget build(BuildContext context) {
    final available = noticeSectionLibrary
        .where((s) => !exclude.any((e) => e.citation == s.citation))
        .toList();
    return AlertDialog(
      title: const Text('Add Statutory Section'),
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
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
