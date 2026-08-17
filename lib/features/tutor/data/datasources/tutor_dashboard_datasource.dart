import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';

class TutorDashboardDatasource {
  const TutorDashboardDatasource(this._dio);

  final Dio _dio;

  Future<TutorDashboardDto> getDashboard() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutor/class-sessions/dashboard',
    );
    return TutorDashboardDto.fromJson(res.data!);
  }

  /// Buổi học trong một khoảng ngày — BE trả theo ngày, ở đây trải phẳng.
  ///
  /// Gửi `yyyy-MM-dd` thuần: BE tự lấy mốc đầu/cuối ngày, không cần UTC.
  Future<List<TutorWeekSessionDto>> getCalendar({
    required DateTime start,
    required DateTime end,
  }) async {
    final res = await _dio.get<dynamic>(
      '/tutor/class-sessions/calendar',
      queryParameters: {'startDate': _ymd(start), 'endDate': _ymd(end)},
    );

    final data = res.data;
    final days = data is Map<String, dynamic>
        ? data['content'] as List<dynamic>? ?? const []
        : (data as List<dynamic>? ?? const []);

    return days
        .whereType<Map<String, dynamic>>()
        .expand(
          (day) => (day['classSessions'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>(),
        )
        .map(TutorWeekSessionDto.fromJson)
        .toList();
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

final tutorDashboardDatasourceProvider = Provider<TutorDashboardDatasource>(
  (ref) => TutorDashboardDatasource(ref.read(apiClientProvider)),
);
