import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/inspection.dart';
import '../../../models/notice.dart';
import '../../../models/signature.dart';
import '../../../repositories/notice_repository.dart' show SignIssueRequest;

/// STEP 8 — digital signature capture (prototype) and notice issuance.
///
/// PROTOTYPE NOTE: the drawn signature is a UI demonstration only and is
/// NOT a legally valid eMudhra signature. Member 6 will replace the
/// capture artifact with a DSC-backed eSign via [SignatureService].
class SignatureStep extends ConsumerStatefulWidget {
  const SignatureStep({
    super.key,
    required this.inspection,
    required this.draftNotice,
    required this.onSigned,
    required this.onBack,
  });

  final Inspection? inspection;
  final Notice? draftNotice;
  final void Function(SignatureResult signature, Notice issuedNotice) onSigned;
  final VoidCallback onBack;

  @override
  ConsumerState<SignatureStep> createState() => _SignatureStepState();
}

class _SignatureStepState extends ConsumerState<SignatureStep> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2.6,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  late final TextEditingController _nameController;
  bool _issuing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.inspection?.inspectorName ?? '',
    );
    _signatureController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signAndIssue(Notice draft) async {
    if (!_signatureController.isNotEmpty) return;
    setState(() {
      _issuing = true;
      _error = null;
    });
    try {
      // 1. Export the drawn signature as PNG.
      final bytes = await _signatureController.toPngBytes();
      if (bytes == null) throw const SignatureException('Signature could not be captured.');
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      // 2. Persist via the signature service abstraction.
      final signature = await ref.read(signatureServiceProvider).saveDrawnSignature(
            pngFilePath: file.path,
            signerName: _nameController.text.trim(),
          );

      // 3. Issue the notice with the signature attached.
      final issued = await ref.read(noticeRepositoryProvider).signAndIssue(
            SignIssueRequest(
              noticeId: draft.id,
              signerName: _nameController.text.trim(),
              signatureImagePath: file.path,
            ),
          );

      if (!mounted) return;
      widget.onSigned(signature, issued);
    } on AppException catch (e) {
      setState(() {
        _error = e.friendlyMessage;
        _issuing = false;
      });
    } catch (_) {
      setState(() {
        _error = 'The notice could not be issued. Please retry.';
        _issuing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draftNotice;
    return Column(
      children: [
        Expanded(
          child: _issuing
              ? const LoadingView(message: 'Signing and issuing notice…')
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    InfoCard(
                      title: 'Ready for signature',
                      children: [
                        KeyValueRow(
                            label: 'Notice', value: draft?.id ?? '—'),
                        KeyValueRow(
                            label: 'Case', value: draft?.caseId ?? '—'),
                        KeyValueRow(
                            label: 'Business',
                            value: draft?.businessName ?? '—'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(title: 'Draw your signature'),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Signature(
                        controller: _signatureController,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _signatureController.clear,
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Signing as (full name)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: AppColors.onTertiaryContainer),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Prototype: the drawn signature demonstrates '
                              'the signing flow. A legally valid eMudhra '
                              'digital signature will be integrated by the '
                              'identity team.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onTertiaryContainer,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
        ),
        BottomActionBar(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Sign & Issue Notice',
                icon: Icons.verified_outlined,
                isLoading: _issuing,
                onPressed: !_signatureController.isNotEmpty || _issuing
                    ? null
                    : () => _signAndIssue(widget.draftNotice!),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
