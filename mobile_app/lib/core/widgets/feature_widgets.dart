import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/notice.dart';
import '../../models/violation.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

/// ViolationCard — displays an AI potential finding or inspector-added
/// violation with human-in-the-loop actions.
class ViolationCard extends StatelessWidget {
  const ViolationCard({
    super.key,
    required this.violation,
    this.onAccept,
    this.onReject,
    this.onEdit,
  });

  final Violation violation;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onEdit;

  Color get _severityColor => switch (violation.severity) {
        ViolationSeverity.low => AppColors.info,
        ViolationSeverity.medium => AppColors.warning,
        ViolationSeverity.high => AppColors.error,
        ViolationSeverity.critical => const Color(0xFF8B1E3F),
      };

  Color get _statusColor => switch (violation.status) {
        ViolationStatus.potential => AppColors.warning,
        ViolationStatus.accepted => AppColors.success,
        ViolationStatus.edited => AppColors.info,
        ViolationStatus.rejected => AppColors.textHint,
      };

  @override
  Widget build(BuildContext context) {
    final canAct = onAccept != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: canAct ? AppColors.outlineVariant : AppColors.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  violation.type.defaultLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusChip(label: violation.severity.label, color: _severityColor),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              StatusChip(
                label: violation.status.label,
                color: _statusColor,
                icon: violation.status == ViolationStatus.accepted
                    ? Icons.verified
                    : violation.status == ViolationStatus.potential
                        ? Icons.auto_awesome
                        : null,
              ),
              if (violation.confidence != null) ...[
                const SizedBox(width: 8),
                AIConfidenceIndicator(confidence: violation.confidence!),
              ],
              if (violation.isAiGenerated) ...[
                const SizedBox(width: 8),
                const Text(
                  'AI finding',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.aiAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            violation.description,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          if (violation.ruleSection != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'APPLICABLE RULE / SECTION',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    violation.ruleSection!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  if (violation.ruleTitle != null)
                    Text(
                      violation.ruleTitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (violation.recommendation != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    size: 16, color: AppColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    violation.recommendation!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (canAct) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.close, size: 17),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.onPrimaryContainer,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      backgroundColor: AppColors.secondary,
                    ),
                    icon: const Icon(Icons.check, size: 17),
                    label: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// NoticeCard — notice inbox / list card.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.notice,
    this.onTap,
    this.showBusiness = false,
  });

  final Notice notice;
  final VoidCallback? onTap;
  final bool showBusiness;

  Color get _statusColor => switch (notice.status) {
        NoticeStatus.draft => AppColors.textHint,
        NoticeStatus.pendingSignature => AppColors.warning,
        NoticeStatus.issued => AppColors.info,
        NoticeStatus.delivered => AppColors.info,
        NoticeStatus.responseSubmitted => AppColors.aiAccent,
        NoticeStatus.underDispute => AppColors.error,
        NoticeStatus.consentGiven => AppColors.success,
        NoticeStatus.complianceSubmitted => AppColors.aiAccent,
        NoticeStatus.closed => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.type.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Case ${notice.caseId}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(label: notice.status.label, color: _statusColor),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              KeyValueRow(label: 'Product', value: notice.productName),
              if (showBusiness)
                KeyValueRow(label: 'Business', value: notice.businessName),
              KeyValueRow(
                label: 'Issued on',
                value: dateFormat.format(notice.issuedDate),
              ),
              if (notice.deadline != null)
                KeyValueRow(
                  label: 'Deadline',
                  value: dateFormat.format(notice.deadline!),
                  valueColor: AppColors.error,
                  isBold: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TimelineItem — one step of the visual case timeline.
class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.title,
    required this.dateTime,
    required this.isDone,
    required this.isCurrent,
    this.isLast = false,
    this.details,
    this.actor,
  });

  final String title;
  final DateTime dateTime;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final String? details;
  final String? actor;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final dotColor = isCurrent
        ? AppColors.primary
        : isDone
            ? AppColors.success
            : AppColors.outline;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone || isCurrent ? dotColor : AppColors.surface,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: isDone && !isCurrent
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : isCurrent
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? AppColors.outline : AppColors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isCurrent || isDone
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDone || isCurrent
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        const StatusChip(label: 'CURRENT', color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDone || isCurrent
                        ? dateFormat.format(dateTime)
                        : 'Pending',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      details!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (actor != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text(
                          actor!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ImagePreviewSheet — full-screen image preview with delete/retake actions.
class ImagePreviewScreen extends StatelessWidget {
  const ImagePreviewScreen({
    super.key,
    required this.imagePath,
    required this.title,
  });

  final String imagePath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}

/// PrivateDataBanner — privacy label for business self-check surfaces.
class PrivateDataBanner extends StatelessWidget {
  const PrivateDataBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 20, color: AppColors.onSecondaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRIVATE SELF-CHECK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
                Text(
                  message ??
                      'This preventive report is not shared with inspectors.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// AiAssistanceBanner — human-in-the-loop notice.
class AiAssistanceBanner extends StatelessWidget {
  const AiAssistanceBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.aiContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: AppColors.aiAccent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message ??
                  'AI-assisted finding. Final verification is required from '
                  'the authorized inspector.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.onPrimaryContainer,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
