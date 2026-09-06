import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../models/evidence.dart';
import '../../shared/camera_capture_screen.dart';

/// STEP 1 — guided multi-angle evidence capture.
///
/// Front / Back / Side guidance, unlimited additional captures, retake and
/// delete. Images are NOT OCR'd locally; upload happens in the next step.
class EvidenceStep extends ConsumerStatefulWidget {
  const EvidenceStep({
    super.key,
    required this.evidence,
    required this.onEvidenceChanged,
    required this.onContinue,
  });

  final List<EvidenceItem> evidence;
  final ValueChanged<List<EvidenceItem>> onEvidenceChanged;
  final VoidCallback? onContinue;

  @override
  ConsumerState<EvidenceStep> createState() => _EvidenceStepState();
}

class _EvidenceStepState extends ConsumerState<EvidenceStep> {
  static const _guideSlots = [PackageSide.front, PackageSide.back, PackageSide.side];

  Future<void> _capture(PackageSide side) async {
    final path = await CameraCaptureScreen.capture(
      context,
      title: 'Capture ${side.label} of package',
    );
    if (path == null) return;
    final item = EvidenceItem(
      id: 'evd-${DateTime.now().millisecondsSinceEpoch}',
      filePath: path,
      side: side,
      capturedAt: DateTime.now(),
    );
    widget.onEvidenceChanged([...widget.evidence, item]);
  }

  void _delete(EvidenceItem item) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Remove photo?',
      message: 'This photo will be removed from the evidence set.',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!confirmed) return;
    widget.onEvidenceChanged(
      widget.evidence.where((e) => e.id != item.id).toList(),
    );
  }

  Future<void> _retake(EvidenceItem item) async {
    final path = await CameraCaptureScreen.capture(
      context,
      title: 'Retake ${item.side.label}',
    );
    if (path == null) return;
    final updated = item.copyWith(filePath: path, capturedAt: DateTime.now());
    widget.onEvidenceChanged(
      widget.evidence.map((e) => e.id == item.id ? updated : e).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capturedSides = widget.evidence.map((e) => e.side).toSet();
    final dateFormat = DateFormat('h:mm a');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const AiAssistanceBanner(
                message:
                    'Capture 2–3 clear sides of the package for better '
                    'analysis. Front, back and side panels carry different '
                    'legal declarations.',
              ),
              const SizedBox(height: AppSpacing.xl),

              // Guided slots
              const SectionHeader(
                title: 'Guided capture',
                subtitle: 'Tap a panel to photograph that side',
              ),
              Row(
                children: [
                  for (final side in _guideSlots) ...[
                    Expanded(
                      child: _GuideSlot(
                        side: side,
                        captured: capturedSides.contains(side),
                        count: widget.evidence.where((e) => e.side == side).length,
                        onTap: () => _capture(side),
                      ),
                    ),
                    if (side != _guideSlots.last) const SizedBox(width: AppSpacing.md),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Captured thumbnails
              if (widget.evidence.isNotEmpty) ...[
                const SectionHeader(title: 'Captured photos'),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.evidence.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, i) {
                    final item = widget.evidence[i];
                    return EvidenceCard(
                      imagePath: item.filePath,
                      sideLabel: item.side.label,
                      capturedAtLabel: dateFormat.format(item.capturedAt),
                      onRetake: () => _retake(item),
                      onDelete: () => _delete(item),
                      onTap: () => _preview(item),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                SecondaryButton(
                  label: 'Add another photo',
                  icon: Icons.add_a_photo_outlined,
                  onPressed: () => _capture(PackageSide.other),
                ),
              ] else
                EmptyState(
                  title: 'No photos captured yet',
                  message:
                      'Photograph at least the front and back of the package. '
                      'You can also add photos from the gallery inside the camera screen.',
                  icon: Icons.photo_camera_outlined,
                  actionLabel: 'Capture front side',
                  onAction: () => _capture(PackageSide.front),
                ),
            ],
          ),
        ),
        BottomActionBar(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: 'Upload & Analyse',
                    icon: Icons.cloud_upload_outlined,
                    onPressed: widget.evidence.isEmpty ? null : widget.onContinue,
                  ),
                  if (widget.evidence.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Capture at least one package photo to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _preview(EvidenceItem item) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: Image.file(item.file, fit: BoxFit.contain)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                '${item.side.label} · captured ${DateFormat('d MMM, h:mm a').format(item.capturedAt)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideSlot extends StatelessWidget {
  const _GuideSlot({
    required this.side,
    required this.captured,
    required this.count,
    required this.onTap,
  });

  final PackageSide side;
  final bool captured;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: captured ? AppColors.secondaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: captured ? AppColors.secondary : AppColors.outlineVariant,
            width: captured ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              captured ? Icons.check_circle : Icons.add_a_photo_outlined,
              size: 26,
              color: captured ? AppColors.secondary : AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              side.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: captured ? AppColors.onSecondaryContainer : AppColors.textPrimary,
              ),
            ),
            if (captured)
              Text(
                '$count photo${count > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, color: AppColors.onSecondaryContainer),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  side.guidance,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
