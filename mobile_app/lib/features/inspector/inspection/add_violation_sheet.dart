import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/mock_data.dart';
import '../../../models/violation.dart';

/// Bottom sheet for manually adding a violation (inspector-authored).
/// Sections are selected from the Legal Knowledge Base library (Member 5).
class AddViolationSheet extends StatefulWidget {
  const AddViolationSheet({super.key});

  @override
  State<AddViolationSheet> createState() => _AddViolationSheetState();
}

class _AddViolationSheetState extends State<AddViolationSheet> {
  final _description = TextEditingController();
  ViolationType _type = ViolationType.missingDeclaration;
  ViolationSeverity _severity = ViolationSeverity.medium;
  String? _selectedSectionId;

  @override
  void dispose() {
    _description.dispose();
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
              'Add Violation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Recorded as an inspector-verified violation.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            DropdownButtonFormField<ViolationType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Violation type'),
              items: ViolationType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.defaultLabel)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description of the violation',
                hintText: 'Describe what was observed on the package…',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Severity',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Applicable rule / section (from Legal Knowledge Base)',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...noticeSectionLibrary.map((section) {
              return RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(section.citation, style: const TextStyle(fontSize: 13)),
                subtitle: Text(section.title, style: const TextStyle(fontSize: 12)),
                value: section.id,
                groupValue: _selectedSectionId,
                onChanged: (v) => setState(() => _selectedSectionId = v),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Add Violation',
              icon: Icons.add_moderator_outlined,
              onPressed: () {
                if (_description.text.trim().isEmpty) return;
                final section = noticeSectionLibrary
                    .where((s) => s.id == _selectedSectionId)
                    .firstOrNull;
                Navigator.of(context).pop(AddViolationRequest(
                  type: _type,
                  description: _description.text.trim(),
                  severity: _severity,
                  ruleSection: section?.citation,
                  recommendation: section?.title,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
