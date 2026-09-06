import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/notice.dart';
import '../../shared/camera_capture_screen.dart';

/// Seizure / sample recording — samples with witness details and photos.
/// Sample IDs come from the backend (mock generates temporary ones).
class SeizureSheet extends ConsumerStatefulWidget {
  const SeizureSheet({super.key, required this.inspectionId});

  final String inspectionId;

  static Future<void> show(BuildContext context, String inspectionId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SeizureSheet(inspectionId: inspectionId),
    );
  }

  @override
  ConsumerState<SeizureSheet> createState() => _SeizureSheetState();
}

class _SeizureSheetState extends ConsumerState<SeizureSheet> {
  final _productName = TextEditingController();
  final _quantity = TextEditingController();
  final _reasonController = TextEditingController();
  final _w1Name = TextEditingController();
  final _w1Phone = TextEditingController();
  final _w2Name = TextEditingController();
  final _w2Phone = TextEditingController();
  final _remarks = TextEditingController();
  String? _samplePhotoPath;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _productName.dispose();
    _quantity.dispose();
    _reasonController.dispose();
    _w1Name.dispose();
    _w1Phone.dispose();
    _w2Name.dispose();
    _w2Phone.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _captureSamplePhoto() async {
    final path = await CameraCaptureScreen.capture(
      context,
      title: 'Sample photo',
    );
    if (path != null) setState(() => _samplePhotoPath = path);
  }

  Future<void> _save() async {
    if (_productName.text.trim().isEmpty || _reasonController.text.trim().isEmpty) {
      setState(() => _error = 'Product and reason are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final sample = SeizureSample(
        id: 'temp',
        productId: 'unknown',
        productName: _productName.text.trim(),
        quantity: _quantity.text.trim(),
        reason: _reasonController.text.trim(),
        capturedAt: DateTime.now(),
        samplePhotoPath: _samplePhotoPath,
        witness1Name: _w1Name.text.trim(),
        witness1Phone: _w1Phone.text.trim(),
        witness2Name: _w2Name.text.trim(),
        witness2Phone: _w2Phone.text.trim(),
        remarks: _remarks.text.trim(),
      );
      final saved = await ref.read(seizureRepositoryProvider).createSamples(
            widget.inspectionId,
            [sample],
            reason: _reasonController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sample recorded (${saved.first.id}). A panchanama is required '
            'for seizure documentation.',
          ),
        ),
      );
    } on AppException catch (e) {
      setState(() {
        _error = e.friendlyMessage;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Seizure / Sample',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _productName,
                decoration: const InputDecoration(labelText: 'Product'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _quantity,
                decoration: const InputDecoration(
                  labelText: 'Quantity (e.g. 24 packs of 1 kg)',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason for seizure',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: _samplePhotoPath == null
                          ? 'Sample Photo'
                          : 'Photo Added ✓',
                      icon: Icons.camera_alt_outlined,
                      onPressed: _captureSamplePhoto,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Witnesses',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _w1Name,
                      decoration: const InputDecoration(
                          labelText: 'Witness 1 name', isDense: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _w1Phone,
                      decoration: const InputDecoration(
                          labelText: 'Witness 1 phone', isDense: true),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _w2Name,
                      decoration: const InputDecoration(
                          labelText: 'Witness 2 name', isDense: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _w2Phone,
                      decoration: const InputDecoration(
                          labelText: 'Witness 2 phone', isDense: true),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _remarks,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Record Seizure',
                icon: Icons.inventory_2_outlined,
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
