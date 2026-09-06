import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/notice.dart';

/// Business notice inbox.
class BusinessNoticesScreen extends ConsumerStatefulWidget {
  const BusinessNoticesScreen({super.key});

  @override
  ConsumerState<BusinessNoticesScreen> createState() =>
      _BusinessNoticesScreenState();
}

class _BusinessNoticesScreenState extends ConsumerState<BusinessNoticesScreen> {
  List<Notice>? _notices;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final notices = await ref.read(businessCaseRepositoryProvider).listNotices();
      if (!mounted) return;
      setState(() => _notices = notices);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Notices',
      showBack: false,
      body: _notices == null && _error == null
          ? const LoadingView(message: 'Loading notices…')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: (_notices ?? []).isEmpty
                      ? const EmptyState(
                          title: 'No notices',
                          message:
                              'Official notices issued to your business will appear here. '
                              'Run a Self Check to stay compliant and avoid notices.',
                          icon: Icons.mark_email_unread_outlined,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _notices!.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) => NoticeCard(
                            notice: _notices![i],
                            onTap: () => context.go(
                              businessNoticeDetailPath(_notices![i].id),
                            ),
                          ),
                        ),
                ),
    );
  }
}
