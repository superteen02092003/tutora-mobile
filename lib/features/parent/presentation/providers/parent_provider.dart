import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/parent/data/datasources/parent_datasource.dart';

class ParentStudentsState {
  const ParentStudentsState({
    this.students = const [],
    this.isLoading = false,
    this.error,
  });
  final List<ParentStudentDto> students;
  final bool isLoading;
  final String? error;
  ParentStudentsState copyWith({
    List<ParentStudentDto>? students,
    bool? isLoading,
    String? error,
  }) => ParentStudentsState(
    students: students ?? this.students,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ParentStudentsNotifier extends StateNotifier<ParentStudentsState> {
  ParentStudentsNotifier(this._ds) : super(const ParentStudentsState());

  final ParentDatasource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _ds.getStudents();
      state = state.copyWith(students: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<AddStudentResult> addStudent({
    required String fullname,
    required String birthdate,
    required String school,
    required int gradeLevelId,
    String? learninggoals,
  }) async {
    final result = await _ds.addStudent(
      fullname: fullname,
      birthdate: birthdate,
      school: school,
      gradeLevelId: gradeLevelId,
      learninggoals: learninggoals,
    );
    await load();
    return result;
  }
}

// Grade levels
final gradeLevelsProvider = FutureProvider<List<GradeLevelDto>>((ref) async {
  return ref.watch(parentDatasourceProvider).getGradeLevels();
});

final parentStudentsProvider =
    StateNotifierProvider<ParentStudentsNotifier, ParentStudentsState>((ref) {
      // read, không watch: watch làm notifier dựng lại và mất state đã load.
      return ParentStudentsNotifier(ref.read(parentDatasourceProvider));
    });

class ParentDashboardState {
  const ParentDashboardState({
    this.pendingLessons = const [],
    this.todayLessons = const [],
    this.weekLessons = const [],
    this.isLoading = false,
    this.error,
  });
  final List<ParentLessonDto> pendingLessons;
  final List<ParentLessonDto> todayLessons;
  final List<ParentLessonDto> weekLessons;
  final bool isLoading;
  final String? error;

  ParentDashboardState copyWith({
    List<ParentLessonDto>? pendingLessons,
    List<ParentLessonDto>? todayLessons,
    List<ParentLessonDto>? weekLessons,
    bool? isLoading,
    String? error,
  }) => ParentDashboardState(
    pendingLessons: pendingLessons ?? this.pendingLessons,
    todayLessons: todayLessons ?? this.todayLessons,
    weekLessons: weekLessons ?? this.weekLessons,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ParentDashboardNotifier extends StateNotifier<ParentDashboardState> {
  ParentDashboardNotifier(this._ds) : super(const ParentDashboardState());

  final ParentDatasource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        _ds.getPendingLessons(),
        _ds.getCalendarLessons(
          startDate: fmt(weekStart),
          endDate: fmt(weekEnd),
        ),
      ]);

      final pending = results[0];
      final week = results[1];
      final todayStr = fmt(now);
      final today = week
          .where((l) => l.scheduledStart.startsWith(todayStr))
          .toList();

      state = state.copyWith(
        pendingLessons: pending,
        todayLessons: today,
        weekLessons: week,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> confirmLesson(int lessonId) async {
    await _ds.confirmLesson(lessonId);
    await load();
  }
}

final parentDashboardProvider =
    StateNotifierProvider<ParentDashboardNotifier, ParentDashboardState>((ref) {
      return ParentDashboardNotifier(ref.read(parentDatasourceProvider));
    });

/// Buổi kế tiếp
final FutureProviderFamily<ParentLessonDto?, String> parentNextLessonProvider =
    FutureProvider.family<ParentLessonDto?, String>((
      ref,
      studentId,
    ) async {
      return ref
          .watch(parentDatasourceProvider)
          .getNextLesson(
            studentId: studentId.isEmpty ? null : studentId,
          );
    });

/// Số liệu Home theo con đang chọn (chuỗi rỗng = mọi con).
final FutureProviderFamily<ParentHomeStatsDto, String> parentHomeStatsProvider =
    FutureProvider.family<ParentHomeStatsDto, String>((
      ref,
      studentId,
    ) async {
      return ref
          .watch(parentDatasourceProvider)
          .getHomeStats(
            studentId: studentId.isEmpty ? null : studentId,
          );
    });

/// Lớp học còn hiệu lực của con đang chọn
final FutureProviderFamily<List<StudentClassDto>, String>
parentChildClassesProvider =
    FutureProvider.family<List<StudentClassDto>, String>((
      ref,
      studentId,
    ) async {
      final res = await ref
          .watch(parentDatasourceProvider)
          .getChildClasses(studentId: studentId, excludeClosed: true);
      return res.items;
    });

/// Buổi học của con đang chọn
final FutureProviderFamily<List<ParentLessonDto>, String>
parentChildLessonsProvider = FutureProvider.family<List<ParentLessonDto>, String>((
  ref,
  studentId,
) async {
  final now = DateTime.now();
  final weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  String fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  return ref
      .watch(parentDatasourceProvider)
      .getChildLessons(
        studentId: studentId,
        startDate: fmt(weekStart),
        endDate: fmt(weekStart.add(const Duration(days: 6))),
      );
});

class ParentStudentBookingsState {
  const ParentStudentBookingsState({
    this.bookings = const [],
    this.isLoading = false,
  });
  final List<ParentBookingDto> bookings;
  final bool isLoading;
  ParentStudentBookingsState copyWith({
    List<ParentBookingDto>? bookings,
    bool? isLoading,
  }) => ParentStudentBookingsState(
    bookings: bookings ?? this.bookings,
    isLoading: isLoading ?? this.isLoading,
  );
}

class ParentStudentBookingsNotifier
    extends StateNotifier<ParentStudentBookingsState> {
  ParentStudentBookingsNotifier(this._ds, this.studentId)
    : super(const ParentStudentBookingsState());

  final ParentDatasource _ds;
  final String studentId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      // BE bỏ qua studentId ở /parent/bookings nên phải lọc ở client. Trước đây
      // lọc status 'active' — giá trị BE không có nên danh sách luôn rỗng.
      final page = await _ds.getBookings(pageSize: 50);
      state = state.copyWith(
        bookings: page.items
            .where((b) => b.studentId == studentId && !b.isClosed)
            .toList(),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final StateNotifierProviderFamily<
  ParentStudentBookingsNotifier,
  ParentStudentBookingsState,
  String
>
parentStudentBookingsProvider =
    StateNotifierProvider.family<
      ParentStudentBookingsNotifier,
      ParentStudentBookingsState,
      String
    >((ref, studentId) {
      return ParentStudentBookingsNotifier(
        ref.read(parentDatasourceProvider),
        studentId,
      );
    });

// All bookings (for bookings list page)

/// Chi tiết một đơn đặt lịch.
final AutoDisposeFutureProviderFamily<ParentBookingDto, int>
parentBookingDetailProvider = FutureProvider.autoDispose
    .family<ParentBookingDto, int>((ref, bookingId) {
      return ref.watch(parentDatasourceProvider).getBookingDetail(bookingId);
    });

class ParentAllBookingsState {
  const ParentAllBookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.page = 1,
    this.totalPages = 1,
    this.error,
  });
  final List<ParentBookingDto> bookings;
  final bool isLoading;
  final int page;
  final int totalPages;
  final String? error;

  bool get hasMore => page < totalPages;

  ParentAllBookingsState copyWith({
    List<ParentBookingDto>? bookings,
    bool? isLoading,
    int? page,
    int? totalPages,
    String? error,
    bool clearError = false,
  }) => ParentAllBookingsState(
    bookings: bookings ?? this.bookings,
    isLoading: isLoading ?? this.isLoading,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    error: clearError ? null : (error ?? this.error),
  );
}

class ParentAllBookingsNotifier extends StateNotifier<ParentAllBookingsState> {
  ParentAllBookingsNotifier(this._ds, this.status)
    : super(const ParentAllBookingsState());

  final ParentDatasource _ds;
  final String? status;

  Future<void> load({bool reset = true}) async {
    if (state.isLoading) return;
    final nextPage = reset ? 1 : state.page + 1;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _ds.getBookings(page: nextPage, status: status);
      state = state.copyWith(
        bookings: reset ? res.items : [...state.bookings, ...res.items],
        page: res.currentPage,
        totalPages: res.totalPages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() =>
      state.hasMore ? load(reset: false) : Future.value();
}

final StateNotifierProviderFamily<
  ParentAllBookingsNotifier,
  ParentAllBookingsState,
  String?
>
parentAllBookingsProvider =
    StateNotifierProvider.family<
      ParentAllBookingsNotifier,
      ParentAllBookingsState,
      String?
    >((ref, status) {
      return ParentAllBookingsNotifier(
        ref.read(parentDatasourceProvider),
        status,
      );
    });
