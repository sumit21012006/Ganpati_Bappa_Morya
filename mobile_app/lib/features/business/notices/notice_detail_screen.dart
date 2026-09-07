import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/notice.dart';
import '../../../models/payment.dart';
import '../../../models/violation.dart';

/// Business notice detail — actions depend on the current notice status:
/// Submit Correction / Raise Dispute / Give Consent / Pay Penalty.
class BusinessNoticeDetailScreen extends ConsumerStatefulWidget {
  const BusinessNoticeDetailScreen({super.key, required this.noticeId});

  final String noticeId;

  @override
  ConsumerState<BusinessNoticeDetailScreen> createState() =>
      _BusinessNoticeDetailScreenState();
}

class _BusinessNoticeDetailScreenState
    extends ConsumerState<BusinessNoticeDetailScreen> {
  Notice? _notice;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final notice = await ref.read(businessCaseRepositoryProvider).getNotice(widget.noticeId);
      if (!mounted) return;
      setState(() => _notice = notice);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is AppException ? e.friendlyMessage : 'Failed to load notice: ');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------- correction

  Future<void> _submitCorrection(Notice notice) async {
    final commentsController = TextEditingController();
    final pickedPaths = <String>[];

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                  'Submit Correction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: commentsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'What was corrected?',
                    hintText: 'Describe the packaging correction made…',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SecondaryButton(
                  label: 'Attach corrected package photos',
                  icon: Icons.add_photo_alternate_outlined,
                  onPressed: () async {
                    final picker = ImagePicker();
                    final images = await picker.pickMultiImage(
                      maxWidth: 2048,
                      imageQuality: 85,
                    );
                    setSheetState(() {
                      pickedPaths.addAll(images.map((i) => i.path));
                    });
                  },
                ),
                if (pickedPaths.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      '${pickedPaths.length} photo(s) attached',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Submit Correction',
                  icon: Icons.task_alt,
                  onPressed: () => Navigator.pop(sheetContext, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (submitted != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(businessCaseRepositoryProvider).submitCorrection(
            CorrectionSubmission(
              noticeId: notice.id,
              comments: commentsController.text.trim(),
              evidenceImagePaths: pickedPaths,
            ),
          );
      await _load();
      _snack('Correction submitted for verification');
    } on AppException catch (e) {
      _snack(e.friendlyMessage);
    } finally {
      setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- dispute

  Future<void> _raiseDispute(Notice notice) async {
    final reasonController = TextEditingController();
    final commentsController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raise Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: commentsController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Comments'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit Dispute'),
          ),
        ],
      ),
    );

    if (submitted != true || reasonController.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(businessCaseRepositoryProvider).submitDispute(
            DisputeRequest(
              noticeId: notice.id,
              reason: reasonController.text.trim(),
              comments: commentsController.text.trim(),
            ),
          );
      await _load();
      _snack('Dispute submitted — status: Under Review');
    } on AppException catch (e) {
      _snack(e.friendlyMessage);
    } finally {
      setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- consent

  Future<void> _giveConsent(Notice notice) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Give Consent',
      message:
          'You confirm that you consent to the compounding of the offence '
          'under Section 46 of the Legal Metrology Act, 2009 and accept the '
          'stated penalty. This confirmation is recorded against your account.',
      confirmLabel: 'I Consent',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await ref.read(businessCaseRepositoryProvider).submitConsent(
            ConsentRequest(
              noticeId: notice.id,
              confirmedBy: notice.businessName,
            ),
          );
      await _load();
      _snack('Consent recorded');
    } on AppException catch (e) {
      _snack(e.friendlyMessage);
    } finally {
      setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- payment

  Future<void> _payPenalty(Notice notice) async {
    final amount = notice.penaltyAmount ?? 0;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Pay Penalty',
      message:
          'Pay ₹${amount.toStringAsFixed(0)} for case ${notice.caseId} via the '
          'secure payment gateway. Payment success is confirmed only after '
          'backend verification.',
      confirmLabel: 'Proceed to Pay',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      final initiation = await ref.read(paymentRepositoryProvider).initiatePayment(
            caseId: notice.caseId,
            amount: amount,
            description: 'Penalty for ${notice.type.label} ${notice.id}',
          );
      if (!mounted) return;

      final url = initiation.checkoutUrl;
      if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        bool launched = false;
        try {
          // Open as an in-app overlay so Flutter never backgrounds or gets killed by OS
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppBrowserView,
            browserConfiguration: const BrowserConfiguration(showTitle: true),
          );
        } catch (_) {}
        if (!launched) {
          try {
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (_) {}
        }
      }

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Razorpay Gateway Active',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Order ${initiation.orderId} for ₹${amount.toStringAsFixed(0)} is active on Razorpay.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Open Razorpay Payment Page',
                icon: Icons.open_in_browser,
                onPressed: () {
                  if (url != null) {
                    launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView, browserConfiguration: const BrowserConfiguration(showTitle: true));
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Check Status / Refresh',
                icon: Icons.refresh,
                onPressed: () {
                  Navigator.pop(ctx);
                  _load();
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      );
    } on AppException catch (e) {
      _snack(e.friendlyMessage);
    } finally {
      setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------ build views

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    if (notice == null) {
      return AppScaffold(
        title: 'Notice Detail',
        body: _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : const LoadingView(),
      );
    }
    return AppScaffold(
      title: 'Notice Detail',
      subtitle: notice.id,
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    InfoCard(
                      title: notice.type.label,
                      trailing: StatusChip(
                        label: notice.status.label,
                        color: _statusColor(notice.status),
                      ),
                      children: [
                        KeyValueRow(label: 'Case ID', value: notice.caseId),
                        KeyValueRow(label: 'Product', value: notice.productName),
                        KeyValueRow(
                            label: 'Issued on',
                            value: dateFormat.format(notice.issuedDate)),
                        if (notice.deadline != null)
                          KeyValueRow(
                            label: 'Deadline',
                            value: dateFormat.format(notice.deadline!),
                            valueColor: AppColors.error,
                            isBold: true,
                          ),
                        if (notice.penaltyAmount != null)
                          KeyValueRow(
                            label: 'Compounding Fee',
                            value: '₹${notice.penaltyAmount!.toStringAsFixed(0)}',
                            valueColor: (notice.paymentStatus?.toUpperCase() == 'PAID' || notice.status == NoticeStatus.closed)
                                ? AppColors.success
                                : AppColors.error,
                            isBold: true,
                          ),
                        KeyValueRow(
                          label: 'Payment Status',
                          value: (notice.paymentStatus ?? ((notice.status == NoticeStatus.closed) ? 'PAID' : 'UNPAID')).toUpperCase(),
                          valueColor: (notice.paymentStatus?.toUpperCase() == 'PAID' || notice.status == NoticeStatus.closed)
                              ? AppColors.success
                              : AppColors.warning,
                          isBold: true,
                        ),
                        if (notice.digitalSignatureHash != null && notice.digitalSignatureHash!.isNotEmpty)
                          KeyValueRow(
                            label: 'DSC Signature',
                            value: 'VERIFIED (${notice.digitalSignatureHash!.substring(0, notice.digitalSignatureHash!.length < 14 ? notice.digitalSignatureHash!.length : 14)}…)',
                            valueColor: AppColors.success,
                          ),
                      ],
                    ),
                    if (notice.pdfPath != null && notice.pdfPath!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                            const SizedBox(width: AppSpacing.md),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Official Statutory PDF Document',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    'Issued by Legal Metrology Organisation',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('View / Print'),
                              onPressed: () async {
                                final path = notice.pdfPath!;
                                final file = File(path);
                                if (file.existsSync()) {
                                  final bytes = await file.readAsBytes();
                                  if (!context.mounted) return;
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => Scaffold(
                                        appBar: AppBar(title: Text(notice.type.label)),
                                        body: PdfPreview(
                                          build: (_) => bytes,
                                          canChangeOrientation: false,
                                          canChangePageFormat: false,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (notice.bodyText != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Text(
                          notice.bodyText!,
                          style: const TextStyle(fontSize: 13.5, height: 1.55),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(title: 'Applicable legal sections'),
                    ...notice.sections.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: InfoCard(
                          title: s.citation,
                          children: [
                            Text(s.title, style: const TextStyle(fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ),
                    const SectionHeader(title: 'Violations cited'),
                    ...notice.violations.map(
                      (v) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: InfoCard(
                          title: v.type.defaultLabel,
                          trailing: StatusChip(
                            label: v.severity.label,
                            color: v.severity == ViolationSeverity.high
                                ? AppColors.error
                                : AppColors.warning,
                          ),
                          children: [
                            Text(
                              v.description,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.45),
                            ),
                            if (v.ruleSection != null)
                              KeyValueRow(
                                  label: 'Section', value: v.ruleSection!),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                    _buildActions(notice),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
    );
  }

  Widget _buildActions(Notice notice) {
    final isPaid = (notice.paymentStatus?.toUpperCase() == 'PAID') || notice.status == NoticeStatus.closed;
    final hasUnpaidPenalty = notice.penaltyAmount != null && notice.penaltyAmount! > 0 && !isPaid;

    final canRespond = !isPaid && notice.status.canBusinessRespond;
    final canPay = hasUnpaidPenalty &&
        (notice.type == NoticeType.compounding ||
            notice.status == NoticeStatus.consentGiven ||
            notice.status == NoticeStatus.complianceSubmitted ||
            notice.status == NoticeStatus.issued);
    final canConsent = !isPaid &&
        notice.penaltyAmount != null &&
        notice.type != NoticeType.compounding &&
        notice.status == NoticeStatus.issued;

    if (isPaid) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.successContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Compounding fee has been paid and verified. This case is legally settled.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    if (!canRespond && !canPay && !canConsent) {
      return InfoCard(
        title: 'Status',
        children: [
          const Text(
            'No action is required from you at this stage. The notice is '
            'under departmental processing.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canPay) ...[
          PrimaryButton(
            label: 'Pay Fees',
            icon: Icons.payment_outlined,
            isLoading: _busy,
            onPressed: () => _payPenalty(notice),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (canRespond) ...[
          PrimaryButton(
            label: 'Submit Correction',
            icon: Icons.build_circle_outlined,
            isLoading: _busy,
            onPressed: () => _submitCorrection(notice),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Raise Dispute',
            icon: Icons.gavel_outlined,
            onPressed: _busy ? null : () => _raiseDispute(notice),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (canConsent) ...[
          PrimaryButton(
            label: 'Give Consent to Compound',
            icon: Icons.handshake_outlined,
            isLoading: _busy,
            onPressed: () => _giveConsent(notice),
          ),
        ],
      ],
    );
  }

  Color _statusColor(NoticeStatus status) => switch (status) {
        NoticeStatus.issued => AppColors.info,
        NoticeStatus.delivered => AppColors.info,
        NoticeStatus.underDispute => AppColors.error,
        NoticeStatus.consentGiven => AppColors.success,
        NoticeStatus.complianceSubmitted => AppColors.aiAccent,
        NoticeStatus.closed => AppColors.success,
        _ => AppColors.textHint,
      };
}
