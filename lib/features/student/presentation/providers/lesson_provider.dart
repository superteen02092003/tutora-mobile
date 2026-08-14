import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/student/data/datasources/lesson_datasource.dart';
import 'package:tutora/features/student/data/models/lesson_models.dart';

// List

class LessonListState {
  const LessonListState({
    this.items = const [],
    this.totalCount = 0,
    this.page = 1,
    this.isLoading = false,
    this.error,
  });

  final List<StudentLessonDto> items;
  final int totalCount;
  final int page;
  final bool isLoading;
  final String? error;

  static const pageSize = 20;

  int get totalPages => (totalCount / pageSize).ceil().clamp(1, 9999);
  bool get hasMore => page < totalPages;

  LessonListState copyWith({
    List<StudentLessonDto>? items,
    int? totalCount,
    int? page,
    bool? isLoading,
    String? error,
  }) => LessonListState(
    items: items ?? this.items,
    totalCount: totalCount ?? this.totalCount,
    page: page ?? this.page,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class LessonListNotifier extends StateNotifier<LessonListState> {
  LessonListNotifier(this._datasource) : super(const LessonListState());

  final LessonDatasource _datasource;
  String? _activeStatus;

  Future<void> load({String? status, bool reset = false}) async {
    if (reset || status != _activeStatus) {
      _activeStatus = status;
      state = const LessonListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }
    try {
      final result = await _datasource.getStudentLessons(
        page: reset ? 1 : state.page,
        status: status,
      );
      state = state.copyWith(
        items: reset ? result.items : [...state.items, ...result.items],
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> nextPage() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(page: state.page + 1);
    await load(status: _activeStatus);
  }

  Future<void> refresh() => load(status: _activeStatus, reset: true);
}

final lessonListProvider =
    StateNotifierProvider<LessonListNotifier, LessonListState>((ref) {
      return LessonListNotifier(ref.read(lessonDatasourceProvider));
    });

// Calendar (flat list by date range)

final FutureProviderFamily<
  StudentLessonPagedResult,
  ({String startDate, String endDate})
>
lessonCalendarProvider =
    FutureProvider.family<
      StudentLessonPagedResult,
      ({String startDate, String endDate})
    >((ref, args) async {
      final ds = ref.read(lessonDatasourceProvider);
      return ds.getStudentCalendarLessons(
        startDate: args.startDate,
        endDate: args.endDate,
      );
    });

// Detail

final FutureProviderFamily<StudentLessonDetailDto, int> lessonDetailProvider =
    FutureProvider.family<StudentLessonDetailDto, int>((ref, lessonId) async {
      final ds = ref.read(lessonDatasourceProvider);
      return ds.getStudentLessonDetail(lessonId);
    });

// Recording

/// Trạng thái video xem lại của buổi học. Trả null khi buổi chưa có bản ghi.
final FutureProviderFamily<LessonRecordingDto?, int> lessonRecordingProvider =
    FutureProvider.family<LessonRecordingDto?, int>((ref, lessonId) async {
      final ds = ref.read(lessonDatasourceProvider);
      return ds.getRecording(lessonId);
    });
