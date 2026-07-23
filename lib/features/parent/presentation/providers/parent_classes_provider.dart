import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/parent/data/datasources/parent_datasource.dart';

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Buổi học sắp tới của tất cả các con (từ hôm nay → +30 ngày), sắp theo giờ.
/// Màn "Lớp học" tự lọc theo con đang chọn ở client.
final AutoDisposeFutureProvider<List<ParentLessonDto>>
parentUpcomingLessonsProvider =
    FutureProvider.autoDispose<List<ParentLessonDto>>((ref) async {
      final ds = ref.watch(parentDatasourceProvider);
      final now = DateTime.now();
      final lessons = await ds.getCalendarLessons(
        startDate: _fmt(now),
        endDate: _fmt(now.add(const Duration(days: 30))),
      );
      lessons.sort((a, b) => a.startDt.compareTo(b.startDt));
      return lessons;
    });

/// Buổi đã hoàn tất chờ phụ huynh xác nhận.
final AutoDisposeFutureProvider<List<ParentLessonDto>>
parentPendingLessonsProvider =
    FutureProvider.autoDispose<List<ParentLessonDto>>((ref) async {
      return ref.watch(parentDatasourceProvider).getPendingLessons();
    });

/// Chi tiết một buổi học theo id.
final AutoDisposeFutureProviderFamily<ParentLessonDto, int>
parentLessonDetailProvider = FutureProvider.autoDispose
    .family<ParentLessonDto, int>((ref, id) {
      return ref.watch(parentDatasourceProvider).getLessonDetail(id);
    });
