import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/notice.dart';

/// STEP 9 (DONE) — Confirms digital issuance and makes the final Government notice visible
/// with direct PDF and Word (.docx) download & preview capabilities.
class FlowCompleteScreen extends StatelessWidget {
  const FlowCompleteScreen({
    super.key,
    this.issuedNotice,
  });

  final Notice? issuedNotice;

  String _resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = AppConstants.apiBaseUrl.contains('/api/v1')
        ? AppConstants.apiBaseUrl.split('/api/v1').first
        : AppConstants.apiBaseUrl;
    final cleanBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBase$cleanPath';
  }

  Future<void> _openDocument(BuildContext context, String? url, String docType) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document link not available.')),
      );
      return;
    }
    final fullUrl = _resolveUrl(url);
    try {
      final uri = Uri.parse(fullUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open document: $fullUrl')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening $docType: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = issuedNotice;
    final dateFormat = DateFormat('d MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Finalised'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_outlined, size: 48, color: AppColors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Center(
            child: Text(
              'Statutory Notice Issued',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Center(
            child: Text(
              'Official Government Order has been sealed and digitally signed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // FINAL NOTICE CARD (VISIBLE)
          if (notice != null) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Government Seal & Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.gavel, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice.type.label.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Text(
                              'GOVERNMENT OF MAHARASHTRA / LEGAL METROLOGY',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 13, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              'SIGNED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.lg),

                  // Metadata Rows
                  _NoticeRow(label: 'Notice ID', value: notice.id),
                  _NoticeRow(label: 'Case ID', value: notice.caseId),
                  _NoticeRow(label: 'Establishment', value: notice.businessName),
                  if (notice.productName.isNotEmpty)
                    _NoticeRow(label: 'Commodity', value: notice.productName),
                  _NoticeRow(
                    label: 'Issued At',
                    value: dateFormat.format(notice.issuedDate),
                  ),
                  if (notice.deadline != null)
                    _NoticeRow(
                      label: 'Rectification Deadline',
                      value: DateFormat('d MMM yyyy').format(notice.deadline!),
                      valueColor: AppColors.error,
                      isBold: true,
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Direct Action Buttons: View PDF & Download Word
                  Row(
                    children: [
                      // View / Download PDF Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text(
                            'View PDF',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                          onPressed: () => _openDocument(
                            context,
                            notice.pdfUrl,
                            'Official PDF Notice',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Download Word Document Button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade800,
                            side: BorderSide(color: Colors.blue.shade800, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          icon: const Icon(Icons.description, size: 18),
                          label: const Text(
                            'Download Word',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                          onPressed: () => _openDocument(
                            context,
                            notice.docxUrl,
                            'Word (.docx) Notice',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Text(
                'Notice issued and recorded in the database. You can review all cases from the dashboard.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Navigation buttons
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Back to Dashboard',
              icon: Icons.dashboard_outlined,
              onPressed: () => context.go(RouteNames.inspectorDashboard),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'View Cases',
              icon: Icons.folder_copy_outlined,
              onPressed: () => context.go(RouteNames.inspectorCases),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
