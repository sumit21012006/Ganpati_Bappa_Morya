import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../di/providers.dart';
import '../../../models/notice.dart';

/// BUSINESS DASHBOARD — prevention-first view: scan packaging before
/// selling, with case, notice and payment summaries.
class BusinessDashboardScreen extends ConsumerStatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  ConsumerState<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState
    extends ConsumerState<BusinessDashboardScreen> {
  bool _loading = true;
  int _activeCases = 0;
  int _pendingNotices = 0;
  double _pendingAmount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notices = await ref.read(businessCaseRepositoryProvider).listNotices();
      final cases = await ref.read(businessCaseRepositoryProvider).listCases();
      final payments = await ref.read(paymentRepositoryProvider).listPayments();
      if (!mounted) return;
      setState(() {
        _pendingNotices = notices.where((n) => n.requiresAction).length;
        _activeCases = cases.where((c) => c.status != CaseStatus.closed).length;
        _pendingAmount = payments
            .where((p) => p.isPending)
            .fold<double>(0, (sum, p) => sum + p.amount);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Portal'),
            Text(
              user?.name ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Sign out?',
                message: 'You will need to sign in again to access your account.',
                confirmLabel: 'Sign out',
                danger: true,
              );
              if (confirmed && context.mounted) {
                await ref.read(authControllerProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingView(message: 'Loading your dashboard…')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Welcome
                  Text(
                    'Welcome, ${user?.name.split(' ').first ?? 'Business'} 👋',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // PREVENTION HERO — the differentiator
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Text(
                            'PREVENTIVE COMPLIANCE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Check your packaging before you sell',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Scan the package, find issues, correct them — '
                          'avoid penalties and offences. Private to you.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton.icon(
                          onPressed: () => context.go(RouteNames.selfCheck),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 52),
                          ),
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text(
                            'Scan Packaging',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Active Cases',
                          value: '$_activeCases',
                          icon: Icons.folder_copy_outlined,
                          color: AppColors.primary,
                          onTap: () => context.go(RouteNames.businessCases),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatCard(
                          label: 'Pending Notices',
                          value: '$_pendingNotices',
                          icon: Icons.mark_email_unread_outlined,
                          color: AppColors.warning,
                          onTap: () => context.go(RouteNames.businessNotices),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Pending Amount',
                          value: '₹${_pendingAmount.toStringAsFixed(0)}',
                          icon: Icons.payments_outlined,
                          color: _pendingAmount > 0 ? AppColors.error : AppColors.success,
                          onTap: () => context.go(RouteNames.payments),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: StatCard(
                          label: 'Compliance Score',
                          value: 'Good',
                          icon: Icons.verified_outlined,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Quick actions
                  const SectionHeader(title: 'Quick Actions'),
                  QuickAction(
                    label: 'Self Compliance Check',
                    subtitle: 'Private check of your packaging',
                    icon: Icons.fact_check_outlined,
                    color: AppColors.secondary,
                    onTap: () => context.go(RouteNames.selfCheck),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  QuickAction(
                    label: 'My Cases',
                    subtitle: 'Track case progress and deadlines',
                    icon: Icons.folder_copy_outlined,
                    onTap: () => context.go(RouteNames.businessCases),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  QuickAction(
                    label: 'My Notices',
                    subtitle: 'Official notices and responses',
                    icon: Icons.mark_email_unread_outlined,
                    color: AppColors.warning,
                    onTap: () => context.go(RouteNames.businessNotices),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  QuickAction(
                    label: 'Payments',
                    subtitle: 'Penalties and receipts',
                    icon: Icons.payments_outlined,
                    color: AppColors.aiAccent,
                    onTap: () => context.go(RouteNames.payments),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  QuickAction(
                    label: 'Self-Check History',
                    subtitle: 'Private reports — never shared with inspectors',
                    icon: Icons.history,
                    color: AppColors.textSecondary,
                    onTap: () => context.go(RouteNames.selfCheckHistory),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const PrivateDataBanner(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}
