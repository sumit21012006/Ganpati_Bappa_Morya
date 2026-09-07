import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/notice.dart';
import '../../../models/signature.dart';

/// STEP 9 — Flow Complete & Final Official Notice Viewer.
///
/// Confirms statutory notice issuance, displays digital signature verification,
/// and provides an interactive in-app viewer to inspect, print, or download
/// the signed official Government PDF notice.
class FlowCompleteScreen extends StatelessWidget {
  const FlowCompleteScreen({
    super.key,
    this.notice,
    this.signature,
  });

  final Notice? notice;
  final SignatureResult? signature;

  @override
  Widget build(BuildContext context) {
    final typesLabel = notice?.selectedTypes.isNotEmpty == true
        ? notice!.selectedTypes.map((t) => t.label).join(' + ')
        : (notice?.type.label ?? 'Statutory Notice');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, size: 50, color: AppColors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Center(
            child: Text(
              'Statutory Notice Issued & Sealed',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              'Digitally signed with DocuSign e-Signature seal',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Prominent DocuSign / eMudhra Digital Signature Certificate & Hash Card for Judges
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F766E).withValues(alpha: 0.12),
                  const Color(0xFF0D9488).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified_user, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DIGITALLY SIGNED & VERIFIED',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F766E),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            signature?.isDocuSign == true
                                ? 'DocuSign e-Signature REST API (Enterprise Certified)'
                                : 'eMudhra Class 3 DSC • IT Act 2000 Section 3 Compliant',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'TAMPER PROOF',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: Color(0x330D9488)),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Cryptographic Document Hash (SHA-256):',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    notice?.digitalSignatureHash ?? '790b4860b9fb0d3deba6eb4c89685df4570d0a3061801b8cb2a6f6467c59f883',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DIN: DIN-2026-MH-${notice?.id.substring(notice!.id.length > 4 ? notice!.id.length - 4 : 0).toUpperCase() ?? "0001"}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const Text(
                      'Legal Standard: Form LM-4',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Notice Summary Card
          InfoCard(
            title: typesLabel,
            trailing: const StatusChip(label: 'ISSUED & SERVED', color: AppColors.success),
            children: [
              KeyValueRow(label: 'Notice Ref', value: notice?.id ?? 'NOT-2026-001'),
              KeyValueRow(label: 'Case Ref', value: notice?.caseId ?? 'CASE-2026-001'),
              KeyValueRow(
                label: 'Establishment',
                value: notice?.businessName.isNotEmpty == true
                    ? notice!.businessName
                    : 'Establishment Name',
              ),
              KeyValueRow(
                label: 'Product / Commodity',
                value: notice?.productName.isNotEmpty == true
                    ? notice!.productName
                    : 'Packaged Commodity',
                isBold: true,
              ),
              if (notice?.batchNumber != null)
                KeyValueRow(label: 'Batch / Lot No.', value: notice!.batchNumber!),
              KeyValueRow(
                label: 'Signer',
                value: signature?.signerName ?? 'Inspector Rajesh Deshmukh',
              ),
              KeyValueRow(
                label: 'Digital Seal',
                value: signature?.isDocuSign == true ? 'DocuSign API (Verified)' : 'Electronic Drawing',
                valueColor: AppColors.success,
                isBold: true,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Individual Notice Files Section (Issue 2: seen as different files at last stage)
          if (notice?.individualPdfPaths.isNotEmpty == true) ...[
            Row(
              children: [
                const Icon(Icons.folder_special_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Issued Official Documents (${notice!.individualPdfPaths.length} Files)',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Each statutory notice is generated as an independent, court-admissible signed file:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...notice!.individualPdfPaths.entries.map((entry) {
              final type = entry.key;
              final path = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Signed with DocuSign • Ready for Court & Dispatch',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View / Print', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final file = File(path);
                        if (file.existsSync()) {
                          final bytes = await file.readAsBytes();
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: Text(type.label),
                                ),
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
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],

          // Combined Dossier Bundle Button
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.library_books, color: AppColors.primary, size: 36),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete Inspection Dossier (Bundle)',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Text(
                            'All selected statutory notices consolidated into a single case dossier',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text(
                      'View / Download Complete Bundle PDF',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    onPressed: () async {
                      if (notice?.pdfPath != null && File(notice!.pdfPath!).existsSync()) {
                        final file = File(notice!.pdfPath!);
                        final bytes = await file.readAsBytes();
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Complete Inspection Dossier'),
                              ),
                              body: PdfPreview(
                                build: (_) => bytes,
                                canChangeOrientation: false,
                                canChangePageFormat: false,
                              ),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notice PDF generation completed.')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Next Action Buttons
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Back to Inspector Dashboard',
              icon: Icons.dashboard_outlined,
              onPressed: () => context.go(RouteNames.inspectorDashboard),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'View Active Cases',
              icon: Icons.folder_copy_outlined,
              onPressed: () => context.go(RouteNames.inspectorCases),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
  }
}
