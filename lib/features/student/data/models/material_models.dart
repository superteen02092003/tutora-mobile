import 'package:intl/intl.dart';

/// Tài liệu học tập gia sư chia sẻ cho một lớp (booking).
/// Nguồn: GET /bookings/{bookingId}/materials
class LearningMaterialDto {
  const LearningMaterialDto({
    required this.materialId,
    required this.title,
    required this.fileUrl,
    this.description,
    this.fileType,
    this.fileSize,
    this.uploadedBy,
    this.ownerType,
    this.createdAt,
  });

  factory LearningMaterialDto.fromJson(Map<String, dynamic> j) =>
      LearningMaterialDto(
        materialId: (j['materialId'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? 'Tài liệu',
        fileUrl: j['fileUrl'] as String? ?? '',
        description: j['description'] as String?,
        fileType: j['fileType'] as String?,
        fileSize: (j['fileSize'] as num?)?.toInt(),
        uploadedBy: j['uploadedBy'] as String?,
        ownerType: j['ownerType'] as String?,
        createdAt: j['createdAt'] as String?,
      );

  final int materialId;
  final String title;
  final String fileUrl;
  final String? description;
  final String? fileType;
  final int? fileSize;
  final String? uploadedBy;
  final String? ownerType;
  final String? createdAt;

  DateTime? get createdAtDt =>
      createdAt == null ? null : DateTime.tryParse(createdAt!)?.toLocal();

  String get createdLabel {
    final d = createdAtDt;
    return d == null ? '' : DateFormat('dd/MM/yyyy').format(d);
  }

  /// Phần mở rộng suy ra từ fileType hoặc đuôi URL — dùng chọn icon.
  String get extension {
    final type = (fileType ?? '').toLowerCase();
    if (type.isNotEmpty && !type.contains('/')) return type;
    final path = Uri.tryParse(fileUrl)?.path ?? fileUrl;
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  MaterialKind get kind => switch (extension) {
    'pdf' => MaterialKind.pdf,
    'doc' || 'docx' => MaterialKind.doc,
    'xls' || 'xlsx' || 'csv' => MaterialKind.sheet,
    'ppt' || 'pptx' => MaterialKind.slide,
    'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'heic' => MaterialKind.image,
    'mp4' || 'mov' || 'avi' || 'mkv' => MaterialKind.video,
    'zip' || 'rar' || '7z' => MaterialKind.archive,
    _ => MaterialKind.other,
  };

  /// "1,2 MB" / "840 KB" — null nếu BE không trả kích thước.
  String? get sizeLabel {
    final bytes = fileSize;
    if (bytes == null || bytes <= 0) return null;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  }

  /// Tài liệu do gia sư gửi (phân biệt với tài liệu học sinh tự tải lên).
  bool get fromTutor => (ownerType ?? '').toLowerCase() == 'tutor';
}

enum MaterialKind { pdf, doc, sheet, slide, image, video, archive, other }
