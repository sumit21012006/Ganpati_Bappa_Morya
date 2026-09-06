import 'dart:io';

/// Side of the package captured — used for guided multi-angle capture.
enum PackageSide { front, back, side, other }

extension PackageSideX on PackageSide {
  String get label => switch (this) {
        PackageSide.front => 'Front',
        PackageSide.back => 'Back',
        PackageSide.side => 'Side',
        PackageSide.other => 'Additional',
      };

  String get guidance => switch (this) {
        PackageSide.front =>
          'Centre the front panel — product name and MRP must be legible.',
        PackageSide.back =>
          'Capture the back panel — declarations list and net quantity.',
        PackageSide.side =>
          'Capture a side panel — batch and manufacturing details.',
        PackageSide.other =>
          'Any additional panel carrying printed declarations.',
      };
}

/// Local evidence item. [filePath] points to the captured/picked file on the
/// device. After upload, [remoteUrl] is populated by the backend response.
class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.filePath,
    required this.side,
    required this.capturedAt,
    this.remoteUrl,
    this.uploaded = false,
    this.isSamplePhoto = false,
  });

  final String id;
  final String filePath;
  final PackageSide side;
  final DateTime capturedAt;

  /// Backend CDN/object-store URL once uploaded (NestJS response).
  final String? remoteUrl;
  final bool uploaded;

  /// Marks photos captured for seizure samples vs. general package evidence.
  final bool isSamplePhoto;

  File get file => File(filePath);

  EvidenceItem copyWith({
    String? id,
    String? filePath,
    PackageSide? side,
    DateTime? capturedAt,
    String? remoteUrl,
    bool? uploaded,
    bool? isSamplePhoto,
  }) {
    return EvidenceItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      side: side ?? this.side,
      capturedAt: capturedAt ?? this.capturedAt,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      uploaded: uploaded ?? this.uploaded,
      isSamplePhoto: isSamplePhoto ?? this.isSamplePhoto,
    );
  }

  factory EvidenceItem.fromJson(Map<String, dynamic> json) => EvidenceItem(
        id: json['id'] as String,
        filePath: json['filePath'] as String? ?? '',
        side: PackageSide.values.firstWhere(
          (s) => s.name == (json['side'] as String?),
          orElse: () => PackageSide.other,
        ),
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        remoteUrl: json['remoteUrl'] as String?,
        uploaded: json['uploaded'] as bool? ?? false,
        isSamplePhoto: json['isSamplePhoto'] as bool? ?? false,
      );
}
