import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/payment.dart';

/// Business payments — penalties pending, payment status, receipts.
///
/// IMPORTANT: payment success is confirmed ONLY by backend verification
/// (Razorpay webhook — Member 6). The app polls status; it never marks
/// success locally.
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  List<PaymentRecord>? _payments;
  String? _error;
  final Set<String> _polling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final payments = await ref.read(paymentRepositoryProvider).listPayments();
      if (!mounted) return;
      setState(() => _payments = payments);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.friendlyMessage);
    }
  }

  /// Polls a pending payment until backend verification completes
  /// (simulated in demo; real implementation polls NestJS).
  Future<void> _checkStatus(String paymentId) async {
    setState(() => _polling.add(paymentId));
    try {
      await ref.read(paymentRepositoryProvider).getPaymentStatus(paymentId);
      await _load();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
    } finally {
      setState(() => _polling.remove(paymentId));
    }
  }

  Color _statusColor(PaymentStatus status) => switch (status) {
        PaymentStatus.success => AppColors.success,
        PaymentStatus.failed => AppColors.error,
        PaymentStatus.refunded => AppColors.aiAccent,
        _ => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final rupees = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final pending = (_payments ?? []).where((p) => p.isPending).toList();
    final settled = (_payments ?? []).where((p) => !p.isPending).toList();

    return AppScaffold(
      title: 'Payments',
      showBack: false,
      body: _payments == null && _error == null
          ? const LoadingView(message: 'Loading payments…')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      if (pending.isNotEmpty) ...[
                        const SectionHeader(title: 'Pending Payments'),
                        ...pending.map((p) => _PaymentCard(
                              record: p,
                              statusColor: _statusColor(p.status),
                              dateFormat: dateFormat,
                              rupees: rupees,
                              isPolling: _polling.contains(p.id),
                              onCheckStatus: () => _checkStatus(p.id),
                            )),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(title: 'Payment History'),
                      if (settled.isEmpty && pending.isEmpty)
                        const EmptyState(
                          title: 'No payments',
                          message:
                              'Penalty payments, when due, will appear here with receipts.',
                          icon: Icons.payments_outlined,
                        )
                      else
                        ...settled.map((p) => _PaymentCard(
                              record: p,
                              statusColor: _statusColor(p.status),
                              dateFormat: dateFormat,
                              rupees: rupees,
                              isPolling: _polling.contains(p.id),
                              onCheckStatus:
                                  p.isPending ? () => _checkStatus(p.id) : null,
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.record,
    required this.statusColor,
    required this.dateFormat,
    required this.rupees,
    required this.isPolling,
    required this.onCheckStatus,
  });

  final PaymentRecord record;
  final Color statusColor;
  final DateFormat dateFormat;
  final NumberFormat rupees;
  final bool isPolling;
  final VoidCallback? onCheckStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusChip(label: record.status.label, color: statusColor),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              KeyValueRow(label: 'Case', value: record.caseId),
              KeyValueRow(label: 'Amount', value: rupees.format(record.amount),
                  isBold: true),
              KeyValueRow(
                  label: 'Created', value: dateFormat.format(record.createdAt)),
              if (record.completedAt != null)
                KeyValueRow(
                    label: 'Completed',
                    value: dateFormat.format(record.completedAt!)),
              if (record.isPending && onCheckStatus != null) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: 200,
                  child: SmallActionButton(
                    label: isPolling ? 'Checking…' : 'Check Status',
                    icon: Icons.refresh,
                    onPressed: isPolling ? null : onCheckStatus,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Payment success is confirmed by the department after '
                  'gateway verification.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
