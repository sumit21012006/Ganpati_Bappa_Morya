import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../models/ocr_result.dart';

/// STEP 3 — OCR result review: every extracted field is editable.
///
/// Inspector corrects OCR errors, fills missing declarations, and confirms
/// the information before compliance analysis continues.
class OcrReviewStep extends StatefulWidget {
  const OcrReviewStep({
    super.key,
    required this.ocrResult,
    required this.onConfirmed,
    required this.onBack,
  });

  final OcrResult? ocrResult;
  final ValueChanged<OcrResult> onConfirmed;
  final VoidCallback onBack;

  @override
  State<OcrReviewStep> createState() => _OcrReviewStepState();
}

class _OcrReviewStepState extends State<OcrReviewStep> {
  late List<ExtractedField> _workingFields;
  late Map<String, TextEditingController> _controllers;
  late Set<String> _corrected;
  late Set<String> _removed;
  late Set<String> _missingAck;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant OcrReviewStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ocrResult != widget.ocrResult) {
      _initControllers();
    }
  }

  void _initControllers() {
    final fields = widget.ocrResult?.fields ?? const <ExtractedField>[];
    final seenKeys = <String>{};
    _workingFields = [];
    for (final f in fields) {
      if (seenKeys.add(f.key)) {
        _workingFields.add(f);
      }
    }
    _controllers = {
      for (final f in _workingFields)
        f.key: TextEditingController(text: f.isMissing ? '' : f.value),
    };
    _corrected = {};
    _removed = {};
    _missingAck = {};
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.ocrResult;
    if (result == null) {
      return const ErrorView(message: 'No OCR result available. Go back and retry analysis.');
    }
    final fields = _workingFields.where((f) => !_removed.contains(f.key)).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const AiAssistanceBanner(
                message:
                    'AI/OCR EXTRACTED — VERIFY BEFORE PROCEEDING. Every field '
                    'below is editable. Correct any recognition errors before '
                    'confirming.',
              ),
              const SizedBox(height: AppSpacing.lg),
              // Raw text preview
              if (result.rawTextPreview != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RAW OCR TEXT',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.rawTextPreview!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),

              ...fields.map((field) => _FieldEditor(
                    field: field,
                    controller: _controllers.putIfAbsent(
                      field.key,
                      () => TextEditingController(text: field.isMissing ? '' : field.value),
                    ),
                    isCorrected: _corrected.contains(field.key),
                    onCorrected: () =>
                        setState(() => _corrected.add(field.key)),
                    onRemove: () =>
                        setState(() => _removed.add(field.key)),
                  )),

              // Add missing field
              const SizedBox(height: AppSpacing.md),
              _AddFieldButton(onAdd: (field) {
                setState(() {
                  if (!_workingFields.any((f) => f.key == field.key)) {
                    _workingFields.add(field);
                  }
                  _controllers[field.key] =
                      TextEditingController(text: field.value);
                  _removed.remove(field.key);
                  _corrected.add(field.key);
                });
              }),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
        BottomActionBar(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Confirm Information',
                icon: Icons.verified_outlined,
                onPressed: () {
                  final baseResult = widget.ocrResult;
                  if (baseResult != null) {
                    final updatedFields = _workingFields
                        .where((f) => !_removed.contains(f.key))
                        .map((f) {
                      final text = _controllers[f.key]?.text.trim() ?? '';
                      final wasCorrected = _corrected.contains(f.key);
                      return f.copyWith(
                        value: text,
                        isMissing: text.isEmpty,
                        isCorrected: wasCorrected,
                        confidence: wasCorrected ? 1.0 : f.confidence,
                      );
                    }).toList();

                    final updatedResult = baseResult.copyWith(
                      fields: updatedFields,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Extracted information verified by inspector',
                        ),
                      ),
                    );
                    widget.onConfirmed(updatedResult);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldEditor extends StatelessWidget {
  const _FieldEditor({
    required this.field,
    required this.controller,
    required this.isCorrected,
    required this.onCorrected,
    required this.onRemove,
  });

  final ExtractedField field;
  final TextEditingController controller;
  final bool isCorrected;
  final VoidCallback onCorrected;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final lowConfidence = field.confidence > 0 && field.confidence < 0.75;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (field.isMissing)
                const StatusChip(
                  label: 'MISSING',
                  color: AppColors.warning,
                  showDot: false,
                )
              else if (isCorrected)
                const StatusChip(
                  label: 'CORRECTED',
                  color: AppColors.secondary,
                  showDot: false,
                )
              else if (field.confidence > 0)
                AIConfidenceIndicator(confidence: field.confidence),
              if (lowConfidence) ...[
                const SizedBox(width: 4),
                const Icon(Icons.warning_amber_outlined,
                    size: 16, color: AppColors.warning),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onCorrected(),
                  decoration: InputDecoration(
                    hintText: field.isMissing
                        ? 'Not detected — enter manually'
                        : 'Enter ${field.label.toLowerCase()}',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove incorrect field',
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.textHint),
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddFieldButton extends StatelessWidget {
  const _AddFieldButton({required this.onAdd});

  final ValueChanged<ExtractedField> onAdd;

  static const _knownFields = [
    ExtractedField(key: OcrFieldKeys.genericName, label: 'Generic Name (Rule 6(1)(b))', value: '', confidence: 0),
    ExtractedField(key: OcrFieldKeys.packer, label: 'Packer', value: '', confidence: 0),
    ExtractedField(key: OcrFieldKeys.importer, label: 'Importer', value: '', confidence: 0),
    ExtractedField(key: OcrFieldKeys.fssaiLicense, label: 'FSSAI License No (Food Safety)', value: '', confidence: 0),
    ExtractedField(key: OcrFieldKeys.unitSalePrice, label: 'Unit Sale Price (Rule 6(11))', value: '', confidence: 0),
    ExtractedField(key: OcrFieldKeys.batchOrLot, label: 'Batch / Lot Number (Rule 6(1)(d))', value: '', confidence: 0),
    ExtractedField(key: OcrFieldKeys.expiryOrUseBy, label: 'Expiry / Best Before (Rule 6(1)(da))', value: '', confidence: 0),
    ExtractedField(key: OcrFieldKeys.countryOfOrigin, label: 'Country of Origin (Rule 6(1)(aa))', value: '', confidence: 0),
    ExtractedField(key: OcrFieldKeys.other, label: 'Other Statutory Declaration', value: '', confidence: 0),
  ];

  @override
  Widget build(BuildContext context) {
    final available = _knownFields
        .where((f) => f.key != OcrFieldKeys.other || true)
        .toList();
    return SecondaryButton(
      label: 'Add Missing Field',
      icon: Icons.add_circle_outline,
      onPressed: () async {
        final selected = await showDialog<ExtractedField>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Add field'),
            children: available
                .map(
                  (f) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, f),
                    child: Text(f.label),
                  ),
                )
                .toList(),
          ),
        );
        if (selected != null) onAdd(selected);
      },
    );
  }
}
