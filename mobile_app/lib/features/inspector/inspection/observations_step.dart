import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/inspection.dart';
import 'supplier_declaration_sheet.dart';
import 'seizure_step.dart';

/// STEP 6 — structured observation recording, editable before finalisation.
class ObservationsStep extends StatefulWidget {
  const ObservationsStep({
    super.key,
    required this.inspectionId,
    required this.onContinue,
    required this.onBack,
  });

  final String inspectionId;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  State<ObservationsStep> createState() => _ObservationsStepState();
}

class _ObservationsStepState extends State<ObservationsStep> {
  final _product = TextEditingController();
  final _batch = TextEditingController();
  final _declaredQty = TextEditingController();
  final _observedQty = TextEditingController();
  final _declaredMrp = TextEditingController();
  final _observedMrp = TextEditingController();
  final _manufacturer = TextEditingController();
  final _supplier = TextEditingController();
  final _remarks = TextEditingController();

  @override
  void dispose() {
    _product.dispose();
    _batch.dispose();
    _declaredQty.dispose();
    _observedQty.dispose();
    _declaredMrp.dispose();
    _observedMrp.dispose();
    _manufacturer.dispose();
    _supplier.dispose();
    _remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SectionHeader(
                title: 'Inspection observations',
                subtitle: 'Editable summary recorded with the inspection record',
              ),
              _ObservationField(
                  controller: _product, label: 'Product'),
              _ObservationField(
                  controller: _batch, label: 'Batch / Lot No.'),
              _ObservationField(
                  controller: _declaredQty,
                  label: 'Declared quantity',
                  keyboard: TextInputType.text),
              _ObservationField(
                  controller: _observedQty,
                  label: 'Observed quantity',
                  keyboard: TextInputType.text),
              _ObservationField(
                  controller: _declaredMrp, label: 'Declared MRP'),
              _ObservationField(
                  controller: _observedMrp, label: 'Observed MRP'),
              _ObservationField(
                  controller: _manufacturer,
                  label: 'Manufacturer / Packer / Importer'),
              _ObservationField(
                  controller: _supplier,
                  label: 'Supplier / Source'),
              _ObservationField(
                controller: _remarks,
                label: 'Remarks',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                label: 'Declare Supplier / Source',
                icon: Icons.link_outlined,
                onPressed: () =>
                    SupplierDeclarationSheet.show(context, widget.inspectionId),
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'Record Seizure / Sample',
                icon: Icons.inventory_2_outlined,
                onPressed: () => SeizureSheet.show(context, widget.inspectionId),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 18, color: AppColors.textSecondary),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Observations are attached to the inspection record '
                        'and referenced in any issued notice.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
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

class _ObservationField extends StatelessWidget {
  const _ObservationField({
    required this.controller,
    required this.label,
    this.keyboard,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
      ),
    );
  }
}
