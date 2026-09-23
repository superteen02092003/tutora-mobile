import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';

/// Buổi học được chọn để ghi âm — thứ màn "Đang ghi" cần để hiển thị.
///
/// Đúng một trong ba định danh được gửi lên server: [lessonId] (buổi có
/// booking), [recorderLessonId] (buổi đã tạo cho học sinh ngoài nền tảng) hoặc
/// [studentId] (ghi ngay cho học sinh ngoài nền tảng). Phần còn lại là để gia
/// sư nhìn và chắc chắn mình đang ghi đúng buổi.
class RecordingTarget {
  const RecordingTarget({
    this.lessonId = 0,
    required this.studentName,
    this.studentId,
    this.recorderLessonId,
    this.subjectName = '',
    this.timeStart = '',
    this.timeEnd = '',
    this.scheduledEnd,
  });

  factory RecordingTarget.fromSession(TutorTodaySessionDto s) =>
      RecordingTarget(
        lessonId: s.lessonId,
        recorderLessonId: s.recorderLessonId,
        studentName: s.studentName,
        subjectName: s.subjectName,
        timeStart: s.timeStart,
        timeEnd: s.timeEnd,
        scheduledEnd: DateTime.tryParse(s.scheduledEnd)?.toLocal(),
      );

  /// classSessionId của buổi có booking; 0 khi không phải buổi booking.
  final int lessonId;

  /// Học sinh ngoài nền tảng — ghi ngay, server tự tạo buổi.
  final String? studentId;

  /// Buổi đã tạo sẵn trong nhật ký (học sinh ngoài nền tảng).
  final String? recorderLessonId;

  bool get isOffPlatform => studentId != null || recorderLessonId != null;
  final String studentName;
  final String subjectName;
  final String timeStart;
  final String timeEnd;
  final DateTime? scheduledEnd;

  factory RecordingTarget.fromStudent(RecorderStudentDto s) => RecordingTarget(
    studentId: s.studentId,
    studentName: s.fullName,
    subjectName: s.subtitle,
  );

  factory RecordingTarget.fromRecorderLesson(RecorderLessonDto l) {
    String hm(DateTime? d) => d == null
        ? ''
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return RecordingTarget(
      recorderLessonId: l.lessonId,
      studentName: l.studentName,
      subjectName: [
        if (l.subject != null && l.subject!.isNotEmpty) l.subject!,
        if (l.grade != null) 'Lớp ${l.grade}',
      ].join(' · '),
      timeStart: hm(l.scheduledStart),
      timeEnd: hm(l.scheduledEnd),
      scheduledEnd: l.scheduledEnd,
    );
  }

  /// "Toán 9 · 19:00 – 20:30"
  String get subtitle {
    final time = timeStart.isEmpty
        ? ''
        : (timeEnd.isEmpty ? timeStart : '$timeStart – $timeEnd');
    return [subjectName, time].where((p) => p.isNotEmpty).join(' · ');
  }
}
