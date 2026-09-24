import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';

/// Danh bạ học sinh ngoài nền tảng. Không autoDispose: trang chủ, bảng ghi âm
/// và màn học sinh cùng đọc — tải một lần, làm mới bằng
/// [reloadRecorderStudentData].
final recorderStudentsProvider = FutureProvider<List<RecorderStudentDto>>(
  (ref) => ref.read(recorderDatasourceProvider).students(),
);

/// Tải lại dữ liệu học sinh ngoài nền tảng ngay sau khi thêm / sửa / xoá.
///
/// Provider không autoDispose dùng `refresh` (gọi API ngay) thay vì
/// `invalidate`. Log server 2026-09-25: sau khi tạo và sau khi xoá học sinh,
/// app không gọi lại `GET /recorder/students` cho tới khi gia sư kéo làm mới
/// trang chủ (38 s, 94 s), dù form đã invalidate. Chưa rõ vì sao lượt làm mới
/// theo lịch của Riverpod bị bỏ qua; `refresh` không phụ thuộc lượt đó.
void reloadRecorderStudentData(WidgetRef ref) {
  ref
    // Bỏ kết quả refresh có chủ đích: màn hình đọc dữ liệu mới qua ref.watch.
    // ignore: unused_result
    ..refresh(recorderStudentsProvider)
    // Bỏ kết quả refresh có chủ đích (như trên).
    // ignore: unused_result
    ..refresh(recorderTodayLessonsProvider)
    ..invalidate(tutorAgendaLessonsProvider)
    ..invalidate(recorderStudentLessonsProvider);
}

/// Các buổi của một học sinh, mới nhất trước.
final AutoDisposeFutureProviderFamily<List<RecorderLessonDto>, String>
recorderStudentLessonsProvider = FutureProvider.autoDispose
    .family<List<RecorderLessonDto>, String>(
      (ref, studentId) =>
          ref.read(recorderDatasourceProvider).lessons(studentId: studentId),
    );

/// Buổi đã ghi âm cần gia sư xử lý (AI đang viết / chờ duyệt / AI lỗi) trong
/// 14 ngày gần nhất — hiện ở trang chủ. Gồm cả buổi booking lẫn ngoài nền tảng.
final recorderPendingReviewsProvider = FutureProvider<List<RecorderLessonDto>>((
  ref,
) async {
  final from = DateTime.now().subtract(const Duration(days: 14));
  final all = await ref.read(recorderDatasourceProvider).lessons(from: from);
  return all
      .where(
        (l) =>
            l.status == 'processing' ||
            l.status == 'awaiting_approval' ||
            l.status == 'failed',
      )
      .toList();
});

/// Buổi hôm nay của học sinh ngoài nền tảng (theo thời khoá biểu), dạng giống
/// buổi booking để trang chủ và sheet ghi âm hiển thị chung.
final recorderTodayLessonsProvider = FutureProvider<List<TutorTodaySessionDto>>(
  (
    ref,
  ) async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final list = await ref
        .read(recorderDatasourceProvider)
        .lessons(from: dayStart, to: dayStart.add(const Duration(days: 1)));
    return list
        .where((l) => l.studentId != null && l.scheduledStart != null)
        .where((l) => l.status != 'discarded')
        .map(
          (l) => TutorTodaySessionDto(
            lessonId: 0,
            studentName: l.studentName,
            subjectName: [
              if (l.subject != null && l.subject!.isNotEmpty) l.subject!,
              if (l.grade != null) 'Lớp ${l.grade}',
            ].join(' · '),
            scheduledStart: l.scheduledStart!.toUtc().toIso8601String(),
            scheduledEnd:
                (l.scheduledEnd ??
                        l.scheduledStart!.add(const Duration(minutes: 90)))
                    .toUtc()
                    .toIso8601String(),
            status: l.status,
            recorderLessonId: l.lessonId,
            recorderStatus: l.status,
          ),
        )
        .toList();
  },
);

/// Mọi buổi đã ghi của gia sư (cả booking lẫn ngoài nền tảng) — màn chi tiết
/// lớp booking lọc theo classSessionId của lớp.
final AutoDisposeFutureProvider<List<RecorderLessonDto>>
recorderAllLessonsProvider =
    FutureProvider.autoDispose<List<RecorderLessonDto>>(
      (ref) => ref.read(recorderDatasourceProvider).lessons(),
    );
