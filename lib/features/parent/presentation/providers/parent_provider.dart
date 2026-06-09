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
      return ParentStudentsNotifier(ref.watch(parentDatasourceProvider));
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
      return ParentDashboardNotifier(ref.watch(parentDatasourceProvider));
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
      final list = await _ds.getBookings(
        studentId: studentId,
        status: 'active',
      );
      state = state.copyWith(bookings: list, isLoading: false);
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
        ref.watch(parentDatasourceProvider),
        studentId,
      );
    });

// All bookings (for bookings list page)

class ParentAllBookingsState {
  const ParentAllBookingsState({
    this.bookings = const [],
    this.isLoading = false,
  });
  final List<ParentBookingDto> bookings;
  final bool isLoading;

  ParentAllBookingsState copyWith({
    List<ParentBookingDto>? bookings,
    bool? isLoading,
  }) => ParentAllBookingsState(
    bookings: bookings ?? this.bookings,
    isLoading: isLoading ?? this.isLoading,
  );
}

class ParentAllBookingsNotifier extends StateNotifier<ParentAllBookingsState> {
  ParentAllBookingsNotifier(this._ds, this.status)
    : super(const ParentAllBookingsState());

  final ParentDatasource _ds;
  final String? status;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _ds.getBookings(status: status);
      state = state.copyWith(bookings: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
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
        ref.watch(parentDatasourceProvider),
        status,
      );
    });
