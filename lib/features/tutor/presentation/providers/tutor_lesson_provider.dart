import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_lesson_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';

// Schedule (calendar + list)

class TutorScheduleState {
  const TutorScheduleState({
    this.lessons = const [],
    this.isLoading = false,
    this.error,
  });

  final List<TutorLessonDto> lessons;
  final bool isLoading;
  final String? error;

  TutorScheduleState copyWith({
    List<TutorLessonDto>? lessons,
    bool? isLoading,
    String? error,
  }) => TutorScheduleState(
    lessons: lessons ?? this.lessons,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class TutorScheduleNotifier extends StateNotifier<TutorScheduleState> {
  TutorScheduleNotifier(this._ds) : super(const TutorScheduleState()) {
    unawaited(loadCurrentMonth());
  }

  final TutorLessonDatasource _ds;

  Future<void> loadCurrentMonth() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month).toIso8601String();
    final to = DateTime(now.year, now.month + 1, 0).toIso8601String();
    await loadRange(from: from, to: to);
  }

  Future<void> loadRange({required String from, required String to}) async {
    state = state.copyWith(isLoading: true);
    try {
      final lessons = await _ds.getCalendar(from: from, to: to);
      // Buổi huỷ và buổi mới giữ chỗ không lên lịch dạy
      state = state.copyWith(
        isLoading: false,
        lessons: lessons.where((l) => l.countsAsSession).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tutorScheduleProvider =
    StateNotifierProvider<TutorScheduleNotifier, TutorScheduleState>(
      (ref) => TutorScheduleNotifier(ref.read(tutorLessonDatasourceProvider)),
    );

// Lesson list (FE13)

class TutorLessonListState {
  const TutorLessonListState({
    this.lessons = const [],
    this.isLoading = false,
    this.error,
  });

  final List<TutorLessonDto> lessons;
  final bool isLoading;
  final String? error;

  TutorLessonListState copyWith({
    List<TutorLessonDto>? lessons,
    bool? isLoading,
    String? error,
  }) => TutorLessonListState(
    lessons: lessons ?? this.lessons,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class TutorLessonListNotifier extends StateNotifier<TutorLessonListState> {
  TutorLessonListNotifier(this._ds) : super(const TutorLessonListState()) {
    unawaited(load());
  }

  final TutorLessonDatasource _ds;

  Future<void> load({String? status, String? from, String? to}) async {
    state = state.copyWith(isLoading: true);
    try {
      final lessons = await _ds.getLessons(
        status: status,
        from: from,
        to: to,
      );
      state = state.copyWith(isLoading: false, lessons: lessons);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tutorLessonListProvider =
    StateNotifierProvider<TutorLessonListNotifier, TutorLessonListState>(
      (ref) => TutorLessonListNotifier(ref.read(tutorLessonDatasourceProvider)),
    );

// Availability (FE14

class TutorAvailabilityState {
  const TutorAvailabilityState({
    this.slots = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<TutorAvailabilityDto> slots;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  TutorAvailabilityState copyWith({
    List<TutorAvailabilityDto>? slots,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) => TutorAvailabilityState(
    slots: slots ?? this.slots,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    error: error,
  );
}

class TutorAvailabilityNotifier extends StateNotifier<TutorAvailabilityState> {
  TutorAvailabilityNotifier(this._ds) : super(const TutorAvailabilityState()) {
    unawaited(load());
  }

  final TutorLessonDatasource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final slots = await _ds.getAvailability();
      state = state.copyWith(isLoading: false, slots: slots);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Lưu trọn danh sách lịch rảnh. Backend chỉ nhận cả danh sách một lần
  /// (PUT), nên thêm/bớt một khung đều đi qua đây.
  Future<bool> saveSlots(List<CreateAvailabilityRequest> slots) async {
    state = state.copyWith(isSaving: true);
    try {
      final saved = await _ds.replaceAvailability(slots);
      state = state.copyWith(isSaving: false, slots: saved);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  static CreateAvailabilityRequest _toRequest(TutorAvailabilityDto s) =>
      CreateAvailabilityRequest(
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
        endTime: s.endTime,
      );

  Future<bool> addSlot(CreateAvailabilityRequest request) =>
      saveSlots([...state.slots.map(_toRequest), request]);

  Future<bool> removeSlot(int availabilityId) => saveSlots(
    state.slots
        .where((s) => s.availabilityId != availabilityId)
        .map(_toRequest)
        .toList(),
  );
}

final tutorAvailabilityProvider =
    StateNotifierProvider<TutorAvailabilityNotifier, TutorAvailabilityState>(
      (ref) =>
          TutorAvailabilityNotifier(ref.read(tutorLessonDatasourceProvider)),
    );

/// Danh sách lớp (booking) — nguồn cho tab "Lớp" ở màn Lịch dạy.
final AutoDisposeFutureProvider<TutorClassPage> tutorClassesProvider =
    FutureProvider.autoDispose<TutorClassPage>((ref) {
      return ref.read(tutorLessonDatasourceProvider).getClasses();
    });

/// Buổi học của một lớp
final AutoDisposeFutureProviderFamily<List<TutorLessonDto>, int>
classSessionsProvider = FutureProvider.autoDispose
    .family<List<TutorLessonDto>, int>((ref, bookingId) async {
      final items = await ref
          .read(tutorLessonDatasourceProvider)
          .getLessons(bookingId: bookingId, pageSize: 100);

      final canFilter = items.any((l) => l.bookingId != null);
      final safe = canFilter
          ? items.where((l) => l.bookingId == bookingId).toList()
          : <TutorLessonDto>[];

      return safe..sort((a, b) {
        final x = a.startDt;
        final y = b.startDt;
        if (x == null || y == null) return 0;
        return x.compareTo(y);
      });
    });

/// Buổi đã dạy xong nhưng chưa gửi báo cáo — quét 14 ngày gần nhất.
final AutoDisposeFutureProvider<List<TutorLessonDto>> awaitingReportProvider =
    FutureProvider.autoDispose<List<TutorLessonDto>>((ref) async {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 14));
      String ymd(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      final items = await ref
          .read(tutorLessonDatasourceProvider)
          .getCalendar(from: ymd(from), to: ymd(now));

      return items.where((l) => l.isAwaitingReport).toList()..sort(
        (a, b) =>
            (b.startDt ?? DateTime(0)).compareTo(a.startDt ?? DateTime(0)),
      );
    });

/// Khoảng tháng mà agenda Lịch dạy tải: 6 tháng trước → 12 tháng sau.
const tutorAgendaMonthsBefore = 6;
const tutorAgendaMonthsAfter = 12;

/// Tháng đầu tiên của agenda (theo hôm nay).
DateTime tutorAgendaFirstMonth([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year, n.month - tutorAgendaMonthsBefore);
}

/// Toàn bộ buổi dạy trong khoảng agenda, xếp theo giờ bắt đầu.
/// Tải theo cụm 3 tháng song song để không vượt giới hạn khoảng ngày của BE.
final AutoDisposeFutureProvider<List<TutorLessonDto>>
tutorAgendaLessonsProvider = FutureProvider.autoDispose<List<TutorLessonDto>>((
  ref,
) async {
  final ds = ref.read(tutorLessonDatasourceProvider);
  final first = tutorAgendaFirstMonth();
  const total = tutorAgendaMonthsBefore + tutorAgendaMonthsAfter + 1;
  String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  final futures = <Future<List<TutorLessonDto>>>[];
  for (var i = 0; i < total; i += 3) {
    final from = DateTime(first.year, first.month + i);
    final span = (total - i) < 3 ? total - i : 3;
    final to = DateTime(first.year, first.month + i + span, 0);
    futures.add(ds.getCalendar(from: ymd(from), to: ymd(to)));
  }
  // Buổi của học sinh ngoài nền tảng (recorder) — cùng khoảng ngày, một lần gọi.
  final lastDay = DateTime(first.year, first.month + total, 0);
  final offPlatform = ref
      .read(recorderDatasourceProvider)
      .lessons(from: first, to: lastDay.add(const Duration(days: 1)))
      .then(
        (list) => list
            .where((l) => l.studentId != null && l.when != null)
            .map(TutorLessonDto.fromRecorder)
            .toList(),
      )
      // Hỏng phần này thì lịch booking vẫn hiện bình thường.
      .catchError((Object _) => <TutorLessonDto>[]);
  futures.add(offPlatform);
  final chunks = await Future.wait(futures);

  final seen = <int>{};
  final all = <TutorLessonDto>[];
  for (final l in chunks.expand((c) => c)) {
    if (!l.countsAsSession) continue;
    if (l.lessonId != 0 && !seen.add(l.lessonId)) continue;
    all.add(l);
  }
  all.sort((a, b) {
    final x = a.startDt;
    final y = b.startDt;
    if (x == null || y == null) return 0;
    return x.compareTo(y);
  });
  return all;
});
