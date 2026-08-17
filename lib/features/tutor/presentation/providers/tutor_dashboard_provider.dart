import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_dashboard_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';

class TutorDashboardState {
  const TutorDashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  final TutorDashboardDto? data;
  final bool isLoading;
  final String? error;

  TutorDashboardState copyWith({
    TutorDashboardDto? data,
    bool? isLoading,
    String? error,
  }) => TutorDashboardState(
    data: data ?? this.data,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class TutorDashboardNotifier extends StateNotifier<TutorDashboardState> {
  TutorDashboardNotifier(this._ds) : super(const TutorDashboardState()) {
    unawaited(load());
  }

  final TutorDashboardDatasource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _ds.getDashboard();
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tutorDashboardProvider =
    StateNotifierProvider<TutorDashboardNotifier, TutorDashboardState>(
      (ref) => TutorDashboardNotifier(
        ref.read(tutorDashboardDatasourceProvider),
      ),
    );

/// Buổi học của tuần hiện tại (thứ hai → chủ nhật) — nguồn cho lịch tuần ở Home.
///
/// Tách khỏi dashboard vì dashboard chỉ trả buổi *sắp tới*: buổi đã dạy đầu
/// tuần sẽ không có, và tuần trống trơn nếu buổi kế tiếp rơi sang tuần sau.
final AutoDisposeFutureProvider<List<TutorWeekSessionDto>>
tutorWeekSessionsProvider =
    FutureProvider.autoDispose<List<TutorWeekSessionDto>>((ref) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monday = today.subtract(Duration(days: today.weekday - 1));
      return ref
          .read(tutorDashboardDatasourceProvider)
          .getCalendar(start: monday, end: monday.add(const Duration(days: 6)));
    });
