import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/student/data/datasources/class_datasource.dart';
import 'package:tutora/shared/models/class_models.dart';

class ClassListState {
  const ClassListState({
    this.items = const [],
    this.totalCount = 0,
    this.page = 1,
    this.isLoading = false,
    this.error,
  });

  final List<StudentClassDto> items;
  final int totalCount;
  final int page;
  final bool isLoading;
  final String? error;

  static const pageSize = 20;

  bool get hasMore => items.length < totalCount;

  /// Lớp đang học / chờ xử lý — tab "Đang học".
  List<StudentClassDto> get ongoing {
    final list = items.where((c) => c.isOngoing).toList()
      ..sort((a, b) {
        final an = a.nextSession?.startDt;
        final bn = b.nextSession?.startDt;
        if (an == null && bn == null) return b.bookingId.compareTo(a.bookingId);
        if (an == null) return 1;
        if (bn == null) return -1;
        return an.compareTo(bn);
      });
    return list;
  }

  /// Lớp đã học xong — tab "Đã xong".
  List<StudentClassDto> get finished {
    return items
        .where((c) => c.statusType == ClassStatusType.completed)
        .toList()
      ..sort((a, b) => b.bookingId.compareTo(a.bookingId));
  }

  /// Toàn bộ buổi học của mọi lớp — nguồn dữ liệu cho lịch tháng.
  List<({StudentClassDto klass, ClassSessionSlotDto session})> get allSessions {
    final out = <({StudentClassDto klass, ClassSessionSlotDto session})>[];
    for (final c in items) {
      if (c.statusType == ClassStatusType.cancelled ||
          c.statusType == ClassStatusType.expired) {
        continue;
      }
      for (final s in c.sessions) {
        // Bỏ buổi đã hủy và buổi `reserved` chờ thanh toán đợt 2 — chưa kích hoạt.
        if (!s.isCounted) continue;
        out.add((klass: c, session: s));
      }
    }
    out.sort((a, b) => a.session.startDt.compareTo(b.session.startDt));
    return out;
  }

  StudyProgressSummary get summary => StudyProgressSummary.fromClasses(items);

  ClassListState copyWith({
    List<StudentClassDto>? items,
    int? totalCount,
    int? page,
    bool? isLoading,
    String? error,
  }) => ClassListState(
    items: items ?? this.items,
    totalCount: totalCount ?? this.totalCount,
    page: page ?? this.page,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ClassListNotifier extends StateNotifier<ClassListState> {
  ClassListNotifier(this._ds) : super(const ClassListState());

  final ClassDatasource _ds;

  Future<void> load({bool reset = false}) async {
    if (state.isLoading) return;
    state = reset
        ? const ClassListState(isLoading: true)
        : state.copyWith(isLoading: true);
    try {
      final page = reset ? 1 : state.page;
      final result = await _ds.getClasses(page: page);
      state = state.copyWith(
        items: reset ? result.items : [...state.items, ...result.items],
        totalCount: result.totalCount,
        page: page,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> nextPage() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(page: state.page + 1);
    await load();
  }

  Future<void> refresh() => load(reset: true);
}

final classListProvider =
    StateNotifierProvider<ClassListNotifier, ClassListState>((ref) {
      return ClassListNotifier(ref.read(classDatasourceProvider));
    });

/// Chi tiết một lớp học (booking) — dùng ở màn danh sách buổi trong lớp.
final FutureProviderFamily<StudentClassDto, int> classDetailProvider =
    FutureProvider.family<StudentClassDto, int>((ref, bookingId) async {
      return ref.read(classDatasourceProvider).getClassDetail(bookingId);
    });

/// Buổi học sắp tới gần nhất — card "Buổi học sắp tới" ở trang chủ.
final FutureProvider<UpcomingSessionDto?> nextSessionProvider =
    FutureProvider<UpcomingSessionDto?>((ref) async {
      return ref.read(classDatasourceProvider).getNextSession();
    });
