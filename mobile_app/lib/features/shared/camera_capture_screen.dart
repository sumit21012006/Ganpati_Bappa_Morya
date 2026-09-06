import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/camera_service.dart';
import '../../core/theme/app_theme.dart';

/// Full-screen in-app camera for evidence capture.
///
/// Permission lifecycle:
/// - not determined → rationale dialog → request
/// - denied → explanation + retry
/// - permanently denied → open-settings action
/// - hardware/initialisation failure → friendly error + gallery fallback
///
/// Returns the captured file path via `Navigator.pop(context, path)`.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    super.key,
    this.lensDirection = CameraLensDirection.back,
    this.title,
  });

  final CameraLensDirection lensDirection;
  final String? title;

  static Future<String?> capture(BuildContext context, {String? title}) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CameraCaptureScreen(title: title),
      ),
    );
  }

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  final CameraService _cameraService = CameraService();
  CameraController? _controller;
  bool _ready = false;
  bool _saving = false;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  Future<void> _initialise() async {
    final granted = await _cameraService.ensureCameraPermission();
    if (!mounted) return;

    if (!granted) {
      final permanentlyDenied = await _cameraService.isPermanentlyDenied();
      if (!mounted) return;
      setState(() {
        _failure = permanentlyDenied
            ? 'Camera access is disabled for this app. Enable it from system '
              'Settings to capture evidence photos.'
            : 'Camera permission is needed to photograph the package. '
              'You can also pick a photo from the gallery instead.';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _failure = 'No camera is available on this device.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == widget.lensDirection,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      setState(() => _failure =
          'The camera could not be started. You can pick a photo from the '
          'gallery instead.');
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _saving) return;
    setState(() => _saving = true);
    try {
      final file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = 'The photo could not be captured. Please try again.';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (picked != null) Navigator.of(context).pop(picked.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failure = 'The image could not be opened. Please try again.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.title ?? 'Capture Evidence',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Guidance strip
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Text(
                'Capture 2–3 clear sides of the package for better analysis. '
                'Hold steady and ensure text is legible.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
              ),
            ),
            // Viewfinder
            Expanded(
              child: _failure != null
                  ? _FailurePane(
                      message: _failure!,
                      onOpenSettings: _openSettings,
                      onGallery: _pickFromGallery,
                    )
                  : !_ready
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _controller!.value.previewSize!.height,
                                    height: _controller!.value.previewSize!.width,
                                    child: CameraPreview(_controller!),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
            // Capture controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery
                  IconButton.filled(
                    onPressed: _pickFromGallery,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                  // Shutter
                  GestureDetector(
                    onTap: _ready && !_saving ? _capture : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _saving ? Colors.white38 : Colors.white,
                          ),
                          child: _saving
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  // Placeholder for symmetry
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }
}

class _FailurePane extends StatelessWidget {
  const _FailurePane({
    required this.message,
    required this.onOpenSettings,
    required this.onGallery,
  });

  final String message;
  final VoidCallback onOpenSettings;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_outlined,
                size: 48, color: Colors.white38),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonalIcon(
              onPressed: onGallery,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pick from gallery'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onOpenSettings,
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Open settings'),
            ),
          ],
        ),
      ),
    );
  }
}
