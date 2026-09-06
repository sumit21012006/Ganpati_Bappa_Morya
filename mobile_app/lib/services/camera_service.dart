import 'package:permission_handler/permission_handler.dart';

import '../core/errors/app_exception.dart';

/// Camera/permission capability service.
///
/// Handles the full permission lifecycle (granted / denied /
/// permanently denied) and never lets a permission failure crash the app.
class CameraService {
  CameraService();

  /// True when camera permission is granted; requests if not determined.
  Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) return true;
    final result = await Permission.camera.request();
    return result.isGranted || result.isLimited;
  }

  /// True when the permission is permanently denied (user must open
  /// Settings — the UI shows an explanation + open-settings action).
  Future<bool> isPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  /// Explains why the permission is needed — shown before requesting.
  String get permissionRationale =>
      'The camera is used to photograph product packaging as inspection '
      'evidence. Photos are uploaded to the enforcement system for '
      'compliance verification. You can also choose images from your '
      'gallery instead.';
}
