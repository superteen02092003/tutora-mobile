import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/student/data/datasources/dashboard_datasource.dart';
import 'package:tutora/features/student/data/models/dashboard_models.dart';

class DashboardState {
  const DashboardState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  final DashboardStats? stats;
  final bool isLoading;
  final String? error;

  DashboardState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    String? error,
  }) => DashboardState(
    stats: stats ?? this.stats,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._ds) : super(const DashboardState());

  final DashboardDatasource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _ds.getLessons(),
        _ds.getPendingLessonsCount(),
        _ds.getBookings(),
      ]);

      final lessons = results[0] as List<LessonSummaryDto>;
      final pendingExtra = results[1] as int;
      final bookings = results[2] as List<BookingSummaryDto>;

      final pendingBookings = bookings
          .where(
            (b) => [
              'pending_payment',
              'deposit_paid',
              'pending_confirmation',
            ].contains(b.status.toLowerCase()),
          )
          .length;

      state = state.copyWith(
        isLoading: false,
        stats: DashboardStats(
          totalBookings: bookings.length,
          totalLessons: lessons.length,
          pendingCount: pendingExtra + pendingBookings,
          completedCount: lessons.where((l) => l.status == 'completed').length,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
      (ref) => DashboardNotifier(ref.read(dashboardDatasourceProvider)),
    );
