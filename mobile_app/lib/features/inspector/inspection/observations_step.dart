import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import 'supplier_declaration_sheet.dart';
import 'seizure_step.dart';

/// STEP 6 — Streamlined Observations: Supplier Declaration & Seizure Recording.
///
/// Removes redundant manual observation text fields and highlights the two critical
/// statutory actions required during physical inspection:
/// 1. Declare Supplier / Upstream Source (multi-tier supply chain traceability)
/// 2. Record Seizure / Sample Collection (panchanama witnesses and evidence)
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
  bool _supplierDeclared = false;
  bool _sampleSeized = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SectionHeader(
                title: 'Inspection Actions & Observations',
                subtitle:
                    'Record statutory upstream supply chain links and formal seizure/sample documentation',
              ),
              const SizedBox(height: AppSpacing.sm),

              // Card 1: Declare Supplier / Source
              _ActionCard(
                title: 'Declare Supplier / Source',
                subtitle:
                    'Link this retailer to distributor or manufacturer (auto-creates upstream inspection for Controller)',
                icon: Icons.link_outlined,
                actionLabel: _supplierDeclared ? 'Update Supplier Link' : 'Declare Supplier / Source',
                statusLabel: _supplierDeclared ? 'Declared & Linked' : 'Optional / Recommended',
                isCompleted: _supplierDeclared,
                onPressed: () async {
                  await SupplierDeclarationSheet.show(context, widget.inspectionId);
                  setState(() => _supplierDeclared = true);
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Card 2: Record Seizure / Sample
              _ActionCard(
                title: 'Record Seizure / Sample',
                subtitle:
                    'Record seized sample units, seizure reason, panchanama witnesses, and official sample ID',
                icon: Icons.inventory_2_outlined,
                actionLabel: _sampleSeized ? 'Update Seizure Record' : 'Record Seizure / Sample',
                statusLabel: _sampleSeized ? 'Samples Recorded' : 'If Samples Seized On-site',
                isCompleted: _sampleSeized,
                onPressed: () async {
                  await SeizureSheet.show(context, widget.inspectionId);
                  setState(() => _sampleSeized = true);
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outline),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Captured packaging photos, OCR declarations, and verified violations are automatically attached to the statutory notice in the next step.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
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
                label: 'Continue to Notice Generation',
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.statusLabel,
    required this.isCompleted,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final String statusLabel;
  final bool isCompleted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isCompleted ? AppColors.success.withValues(alpha: 0.5) : AppColors.outline,
          width: isCompleted ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.successContainer
                      : AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isCompleted ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: AppColors.success, size: 22),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: isCompleted
                ? OutlinedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(actionLabel),
                  )
                : ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: Icon(icon, size: 18),
                    label: Text(actionLabel),
                  ),
          ),
        ],
      ),
    );
  }
}
