import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';

/// Danh bạ học sinh ngoài nền tảng. Không autoDispose: trang chủ, bảng ghi âm
/// và màn học sinh cùng đọc — tải một lần, làm mới bằng invalidate.
final recorderStudentsProvider = FutureProvider<List<RecorderStudentDto>>(
  (ref) => ref.read(recorderDatasourceProvider).students(),
);

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
final recorderTodayLessonsProvider = FutureProvider<List<TutorTodaySessionDto>>((
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
          scheduledEnd: (l.scheduledEnd ?? l.scheduledStart!.add(const Duration(minutes: 90)))
              .toUtc()
              .toIso8601String(),
          status: l.status,
          recorderLessonId: l.lessonId,
          recorderStatus: l.status,
        ),
      )
      .toList();
});

/// Mọi buổi đã ghi của gia sư (cả booking lẫn ngoài nền tảng) — màn chi tiết
/// lớp booking lọc theo classSessionId của lớp.
final AutoDisposeFutureProvider<List<RecorderLessonDto>> recorderAllLessonsProvider =
    FutureProvider.autoDispose<List<RecorderLessonDto>>(
      (ref) => ref.read(recorderDatasourceProvider).lessons(),
    );
