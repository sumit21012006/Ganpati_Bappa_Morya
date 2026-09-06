import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import 'supplier_declaration_sheet.dart';
import 'seizure_step.dart';

/// STEP 6 — Procedural Actions (Supplier Declaration & Seizure Recording).
/// Text input fields removed as per official workflow requirements.
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
  bool _seizureRecorded = false;

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
                subtitle: 'Record upstream supply chain declarations and statutory sample seizures',
              ),
              const SizedBox(height: AppSpacing.md),

              // Option 1: Declare Supplier / Source Card
              _ActionCard(
                icon: Icons.link_outlined,
                iconColor: AppColors.primary,
                title: 'DECLARE SUPPLIER / SOURCE',
                subtitle:
                    'Link upstream manufacturer, wholesale distributor or packaging source for tracing contraventions under Section 18.',
                buttonLabel: _supplierDeclared ? 'Edit Supplier Declaration' : 'Declare Supplier / Source',
                buttonIcon: _supplierDeclared ? Icons.check_circle_outline : Icons.add_circle_outline,
                isCompleted: _supplierDeclared,
                onPressed: () async {
                  await SupplierDeclarationSheet.show(context, widget.inspectionId);
                  setState(() => _supplierDeclared = true);
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Option 2: Record Seizure / Sample Card
              _ActionCard(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.warning,
                title: 'RECORD SEIZURE / SAMPLE',
                subtitle:
                    'Record seized sample packages, panchanama witnesses, and detention memo under Section 15 of Legal Metrology Act.',
                buttonLabel: _seizureRecorded ? 'Edit Seizure Records' : 'Record Seizure / Sample',
                buttonIcon: _seizureRecorded ? Icons.check_circle_outline : Icons.inventory_2,
                isCompleted: _seizureRecorded,
                onPressed: () async {
                  await SeizureSheet.show(context, widget.inspectionId);
                  setState(() => _seizureRecorded = true);
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Statutory info note
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Declared suppliers and seizure memos will be linked to the official inspection dossier and automatically cited in the Government Notice generated in the next step.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.45,
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
                label: 'Continue to Notice',
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
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.isCompleted,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool isCompleted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isCompleted ? AppColors.success.withValues(alpha: 0.6) : AppColors.outlineVariant,
          width: isCompleted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Recorded',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: isCompleted
                ? OutlinedButton.icon(
                    icon: Icon(buttonIcon, size: 18),
                    label: Text(buttonLabel),
                    onPressed: onPressed,
                  )
                : FilledButton.icon(
                    icon: Icon(buttonIcon, size: 18),
                    label: Text(buttonLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: iconColor,
                    ),
                    onPressed: onPressed,
                  ),
          ),
        ],
      ),
    );
  }
}
