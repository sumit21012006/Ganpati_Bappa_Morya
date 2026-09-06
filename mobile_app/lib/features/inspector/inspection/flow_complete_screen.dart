import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

/// Final step — confirms issuance and offers next actions.
class FlowCompleteScreen extends StatelessWidget {
  const FlowCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Complete')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.task_alt, size: 52, color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Notice Issued',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'The signed notice has been issued to the business and is '
                'now visible in their notice inbox. The case will continue '
                'through response, re-inspection and resolution stages.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 260,
                child: PrimaryButton(
                  label: 'Back to Dashboard',
                  icon: Icons.dashboard_outlined,
                  onPressed: () => context.go(RouteNames.inspectorDashboard),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 260,
                child: SecondaryButton(
                  label: 'View Cases',
                  icon: Icons.folder_copy_outlined,
                  onPressed: () => context.go(RouteNames.inspectorCases),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
