import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/mock_data.dart';
import '../../../di/providers.dart';
import '../../../models/inspection.dart';
import '../../../models/notice.dart';
import '../../../models/ocr_result.dart';
import '../../../models/violation.dart';
import '../../../../services/notice_pdf_generator.dart';

/// STEP 7 — Multi-Notice Generation, Official Government PDF Generation, Review & Edit.
///
/// Supports multi-notice selection (e.g. Improvement Notice + Seizure Notice).
/// Generates official Government of Maharashtra / Government of India PDFs
/// matching the exact structure in `Compounding_SAMPLE_GENERATED.pdf`.
class NoticeStep extends ConsumerStatefulWidget {
  const NoticeStep({
    super.key,
    required this.inspectionId,
    required this.inspection,
    required this.violations,
    this.ocrResult,
    required this.onNoticeIssued,
    required this.onBack,
  });

  final String inspectionId;
  final Inspection? inspection;
  final List<Violation> violations;
  final OcrResult? ocrResult;
  final ValueChanged<Notice> onNoticeIssued;
  final VoidCallback onBack;

  @override
  ConsumerState<NoticeStep> createState() => _NoticeStepState();
}

class _NoticeStepState extends ConsumerState<NoticeStep> {
  Notice? _draft;
  bool _generating = false;
  String? _error;
  final Set<NoticeType> _selectedTypes = {NoticeType.improvement};



  String get _productName {
    final ocr = widget.ocrResult;
    if (ocr?.productName?.isNotEmpty == true) {
      return ocr!.productName!;
    }
    if (ocr?.genericName?.isNotEmpty == true) {
      return ocr!.genericName!;
    }
    return widget.inspection?.business.name ?? 'Packaged Commodity';
  }

  String get _businessName {
    final ocr = widget.ocrResult;
    if (ocr?.manufacturerDetails?.isNotEmpty == true) {
      return ocr!.manufacturerDetails!.split(',').first.trim();
    }
    if (widget.inspection?.business.name.trim().isNotEmpty == true) {
      return widget.inspection!.business.name.trim();
    }
    return 'Manufacturer / Packer';
  }

  String get _businessAddress {
    final ocr = widget.ocrResult;
    if (ocr?.manufacturerDetails?.isNotEmpty == true) {
      final parts = ocr!.manufacturerDetails!.split(',');
      if (parts.length > 1) {
        return parts.sublist(1).join(',').trim();
      }
    }
    return widget.inspection?.business.location.singleLine ??
        'Address as per Inspection Record';
  }

  String get _batchNumber =>
      widget.ocrResult?.batchNumber ?? 'N/A';

  String get _mrp =>
      widget.ocrResult?.mrp ?? 'Not declared';

  String get _netQuantity =>
      widget.ocrResult?.netQuantity ?? 'Not declared';

  Future<void> _generate() async {
    if (_selectedTypes.isEmpty) {
      _snack('Please select at least one notice type to issue.');
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final confirmed = widget.violations.where((v) => v.isConfirmed).toList();
      final primaryType = _selectedTypes.contains(NoticeType.compounding)
          ? NoticeType.compounding
          : _selectedTypes.first;

      Notice notice;
      try {
        notice = await ref.read(noticeRepositoryProvider).generateNotice(
              GenerateNoticeRequest(
                inspectionId: widget.inspectionId,
                noticeType: primaryType,
                noticeTypes: _selectedTypes,
                confirmedViolations: confirmed,
                productName: _productName,
                businessName: _businessName,
                businessAddress: _businessAddress,
                manufacturerName: _businessName,
                batchNumber: _batchNumber,
                mrp: _mrp,
                netQuantity: _netQuantity,
                remarks: 'Issued during field inspection under Rule 6.',
              ),
            );
      } catch (_) {
        notice = Notice(
          id: 'NOT-${DateTime.now().millisecondsSinceEpoch}',
          caseId: 'CASE-2026-${widget.inspectionId}',
          type: primaryType,
          status: NoticeStatus.draft,
          productName: _productName,
          issuedDate: DateTime.now(),
          deadline: DateTime.now().add(const Duration(days: 15)),
          penaltyAmount: primaryType == NoticeType.compounding ? 15000.0 : 5000.0,
          sections: [
            const NoticeSection(
              id: 's1',
              citation: 'Section 18',
              title: 'Declarations on Pre-packaged Commodities',
            ),
            const NoticeSection(
              id: 's2',
              citation: 'Rule 6(1)',
              title: 'Mandatory Declarations on Packaging',
            ),
            const NoticeSection(
              id: 's3',
              citation: 'Section 36(1)',
              title: 'Penalty for Non-declaration',
            ),
          ],
          violations: confirmed,
          isAiDraft: true,
          inspectionId: widget.inspectionId,
          businessId: widget.inspection?.business.id ?? 'biz-001',
          businessName: _businessName,
          businessAddress: _businessAddress,
          manufacturerName: _businessName,
          batchNumber: _batchNumber,
          mrp: _mrp,
          netQuantity: _netQuantity,
          bodyText:
              'Statutory legal notice issued under Section 15 of the Legal Metrology Act, 2009 and Rule 6 of the Legal Metrology (Packaged Commodities) Rules, 2011 in respect of $_productName.',
        );
      }

      // Generate both the official Government multi-notice PDF bundle AND individual notice PDFs!
      final pdfGen = NoticePdfGenerator();
      final bundlePath = await pdfGen.generateNoticePdf(
        noticeTypes: _selectedTypes.toList(),
        notice: notice,
        inspection: widget.inspection,
        violations: confirmed,
      );

      final individualPaths = await pdfGen.generateIndividualNoticePdfs(
        noticeTypes: _selectedTypes.toList(),
        notice: notice,
        inspection: widget.inspection,
        violations: confirmed,
      );

      final finalNotice = notice.copyWith(
        selectedTypes: _selectedTypes,
        pdfPath: bundlePath,
        individualPdfPaths: individualPaths,
        productName: _productName,
        businessName: _businessName,
        businessAddress: _businessAddress,
        manufacturerName: _businessName,
        batchNumber: _batchNumber,
        mrp: _mrp,
        netQuantity: _netQuantity,
      );

      if (!mounted) return;
      setState(() {
        _draft = finalNotice;
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to generate notice PDF: $e';
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
    } catch (_) {
      final updatedSections = List<NoticeSection>.from(notice.sections)..add(selected);
      setState(() => _draft = notice.copyWith(sections: updatedSections));
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
                      'Generating official Government PDF notice(s) with legal rule citations…')
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _generate)
                  : _buildDraftReview(context, dateFormat),
        ),
        if (_draft != null)
          BottomActionBar(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: _selectedTypes.length > 1
                      ? 'Continue to Sign (${_selectedTypes.length} Notices)'
                      : 'Continue to Signature',
                  icon: Icons.draw_outlined,
                  onPressed: () async {
                    final confirmed = await ConfirmationDialog.show(
                      context,
                      title: 'Confirm Notice Review',
                      message: _selectedTypes.length > 1
                          ? 'You have reviewed all ${_selectedTypes.length} official statutory notices. Proceed to digitally sign and issue them?'
                          : 'You have reviewed the official statutory notice. Proceed to sign and issue this notice?',
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
          title: 'Select Statutory Notices to Issue',
          subtitle:
              'Select one or multiple notices (e.g. Seizure Notice can be generated alongside Improvement Notice)',
        ),
        const SizedBox(height: AppSpacing.sm),

        // Multi-notice Checkboxes
        ...NoticeType.values.map(
          (t) {
            final isChecked = _selectedTypes.contains(t);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: isChecked ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(
                    color: isChecked ? AppColors.primary : AppColors.outline,
                    width: isChecked ? 1.5 : 1.0,
                  ),
                ),
                child: CheckboxListTile(
                  title: Text(
                    t.label,
                    style: TextStyle(
                      fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(_getNoticeSubtitle(t), style: const TextStyle(fontSize: 12)),
                  value: isChecked,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedTypes.add(t);
                      } else {
                        if (_selectedTypes.length > 1) {
                          _selectedTypes.remove(t);
                        } else {
                          _snack('At least one notice type must remain selected.');
                        }
                      }
                    });
                  },
                ),
              ),
            );
          },
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
              'No violations are confirmed yet. You can still generate notices, '
              'but confirming violations ensures full statutory citations.',
              style: TextStyle(fontSize: 13, color: AppColors.onTertiaryContainer),
            ),
          )
        else
          InfoCard(
            title: 'Violations to be Cited (${confirmedViolations.length})',
            children: confirmedViolations
                .map((v) => KeyValueRow(
                      label: v.severity.label,
                      value: v.ruleTitle ?? v.description,
                    ))
                .toList(),
          ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Generate Official PDF Notice(s)',
          icon: Icons.picture_as_pdf_outlined,
          isLoading: _generating,
          onPressed: _generate,
        ),
      ],
    );
  }

  String _getNoticeSubtitle(NoticeType t) {
    switch (t) {
      case NoticeType.improvement:
        return 'Mandatory demand for rectification under Section 15(6) with 15-day compliance deadline.';
      case NoticeType.seizure:
        return 'Seizure bill & sample custody memo under Section 15(1) & (4).';
      case NoticeType.compounding:
        return 'Official Compounding Order under Section 48(3) with statutory penalty amount.';
      case NoticeType.panchanama:
        return 'Panchanama document with two independent witnesses (Panchas).';
    }
  }

  Widget _buildDraftReview(BuildContext context, DateFormat dateFormat) {
    final notice = _draft!;
    final noticeLabels = notice.selectedTypes.map((t) => t.label).join(' + ');

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
          child: Row(
            children: [
              const Icon(Icons.verified, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'OFFICIAL PDF NOTICE GENERATED — REVIEW BEFORE SIGNATURE',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Official PDF Preview Button
        if (notice.pdfPath != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Official PDF Document Ready',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      Text(
                        'Formatted as Government of Maharashtra statutory notice',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () async {
                    final file = File(notice.pdfPath!);
                    if (file.existsSync()) {
                      final bytes = await file.readAsBytes();
                      await Printing.layoutPdf(onLayout: (_) => bytes);
                    }
                  },
                  child: const Text('Preview Bundle'),
                ),
              ],
            ),
          ),

        if (notice.individualPdfPaths.isNotEmpty && notice.individualPdfPaths.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Individual Notice Documents (Separate Files):',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...notice.individualPdfPaths.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      entry.key.label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Preview', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final file = File(entry.value);
                      if (file.existsSync()) {
                        final bytes = await file.readAsBytes();
                        await Printing.layoutPdf(onLayout: (_) => bytes);
                      }
                    },
                  ),
                ],
              ),
            );
          }),
        ],

        const SizedBox(height: AppSpacing.lg),

        InfoCard(
          title: noticeLabels.isNotEmpty ? noticeLabels : notice.type.label,
          trailing: StatusChip(label: notice.status.label, color: AppColors.textHint),
          children: [
            KeyValueRow(label: 'Notice Reference', value: notice.id),
            KeyValueRow(label: 'Case ID', value: notice.caseId),
            KeyValueRow(label: 'Establishment', value: notice.businessName),
            KeyValueRow(label: 'Issued Date & Time', value: DateFormat('d MMM yyyy, h:mm a').format(notice.issuedDate)),
            if (notice.deadline != null)
              KeyValueRow(
                label: 'Compliance Deadline',
                value: dateFormat.format(notice.deadline!),
                valueColor: AppColors.error,
                isBold: true,
              ),
            if (notice.penaltyAmount != null)
              KeyValueRow(
                label: 'Compounding Penalty',
                value: '₹ ${notice.penaltyAmount!.toStringAsFixed(2)}',
                valueColor: AppColors.primary,
                isBold: true,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Sections
        SectionHeader(
          title: 'Cited Statutory Sections (${notice.sections.length})',
          actionLabel: 'Add Section',
          onAction: () => _addSection(notice),
        ),
        ...notice.sections.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InfoCard(
              title: s.citation,
              children: [
                Text(s.title, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Notice body
        const SectionHeader(title: 'Notice Summary & Directives'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Text(
            notice.bodyText ?? 'Statutory notice issued.',
            style: const TextStyle(fontSize: 13.5, height: 1.55),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _SectionPickerDialog extends StatelessWidget {
  const _SectionPickerDialog({required this.exclude});
  final List<NoticeSection> exclude;

  @override
  Widget build(BuildContext context) {
    final available = noticeSectionLibrary
        .where((s) => !exclude.any((x) => x.citation == s.citation))
        .toList();
    return AlertDialog(
      title: const Text('Add Legal Citation'),
      content: SizedBox(
        width: double.maxFinite,
        child: available.isEmpty
            ? const Text('All statutory sections already cited.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: available.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = available[i];
                  return ListTile(
                    title: Text(s.citation, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s.title, style: const TextStyle(fontSize: 12)),
                    onTap: () => Navigator.of(context).pop(s.copyWith(isAddedByInspector: true)),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      ],
    );
  }
}
