import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/inspection.dart';
import '../../../models/notice.dart';
import '../../../core/auth/auth_controller.dart';

/// INSPECTOR DASHBOARD — assigned inspections, pending count, active cases,
/// notices requiring action, and today's inspections with quick actions.
class InspectorDashboardScreen extends ConsumerStatefulWidget {
  const InspectorDashboardScreen({super.key});

  @override
  ConsumerState<InspectorDashboardScreen> createState() =>
      _InspectorDashboardScreenState();
}

class _InspectorDashboardScreenState
    extends ConsumerState<InspectorDashboardScreen> {
  bool _loading = true;
  String? _error;
  List<Inspection> _assigned = [];
  List<Notice> _draftNotices = [];
  int _activeCases = 0;
  int _pendingSelfCheckAlerts = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inspections =
          await ref.read(inspectionRepositoryProvider).listInspections();
      final notices = await ref
          .read(noticeRepositoryProvider)
          .listNoticesForInspector('current');
      final cases = await ref
          .read(caseRepositoryProvider)
          .listCases(onlyActive: true);
      if (!mounted) return;
      setState(() {
        _assigned =
            inspections.where((i) => i.status.isActive).take(6).toList();
        _draftNotices =
            notices.where((n) => n.status.isEditableByInspector).toList();
        _activeCases = cases.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your dashboard. Please check your connection and retry.';
        _loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final dateFormat = DateFormat('EEEE, d MMM yyyy');
    final today = _assigned
        .where((i) => DateUtils.isSameDay(i.scheduledAt, DateTime.now()))
        .toList();

    return AppScaffold(
      title: 'Inspector Dashboard',
      subtitle: user != null ? '${user.name} · ${user.jurisdiction ?? ''}' : null,
      showBack: false,
      body: _loading
          ? const LoadingView(message: 'Loading your dashboard…')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      // Greeting card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Namaste, ${user?.name.split(' ').first ?? 'Officer'} 👋',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Assigned Inspections',
                              value: '${_assigned.length}',
                              icon: Icons.assignment_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              label: 'Active Cases',
                              value: '$_activeCases',
                              icon: Icons.folder_copy_outlined,
                              color: AppColors.aiAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Draft Notices',
                              value: '${_draftNotices.length}',
                              icon: Icons.description_outlined,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              label: 'Pending Actions',
                              value: '${_draftNotices.length + _pendingSelfCheckAlerts}',
                              icon: Icons.pending_actions_outlined,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Quick actions
                      const SectionHeader(title: 'Quick Actions'),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.photo_camera_outlined,
                              label: 'Start Inspection',
                              onTap: () =>
                                  context.go(RouteNames.businessSearch),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.search,
                              label: 'Search Business',
                              onTap: () =>
                                  context.go(RouteNames.businessSearch),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.assignment_outlined,
                              label: 'My Inspections',
                              onTap: () => context.go(RouteNames.inspectorInspections),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Today's inspections
                      if (today.isNotEmpty) ...[
                        const SectionHeader(title: "Today's Inspections"),
                        ...today.map(_InspectionTile.new),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Assigned
                      const SectionHeader(title: 'Assigned Inspections'),
                      if (_assigned.isEmpty)
                        const EmptyState(
                          title: 'No inspections assigned',
                          message:
                              'New inspection assignments from the Controller office will appear here.',
                          icon: Icons.assignment_outlined,
                        )
                      else
                        ..._assigned.map(_InspectionTile.new),

                      // Draft notices requiring action
                      if (_draftNotices.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const SectionHeader(title: 'Notices Requiring Action'),
                        ..._draftNotices.map(
                          (n) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: NoticeCard(notice: n),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 4),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectionTile extends StatelessWidget {
  const _InspectionTile(this.inspection);

  final Inspection inspection;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM, h:mm a');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          onTap: () => context.go(inspectionDetailPath(inspection.id)),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.storefront, color: AppColors.primary, size: 22),
          ),
          title: Text(
            inspection.business.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${inspection.type.label} · ${dateFormat.format(inspection.scheduledAt)}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        ),
      ),
    );
  }
}
