import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/dashboard_models.dart';

class DashboardDatasource {
  const DashboardDatasource(this._dio);

  final Dio _dio;

  Future<List<LessonSummaryDto>> getLessons() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/student/lessons',
      queryParameters: {'page': 1, 'pageSize': 50},
    );
    final content = res.data?['content'];
    final raw = content is List
        ? content
        : (content as Map<String, dynamic>?)?['items'] as List<dynamic>? ?? [];
    return raw
        .map((e) => LessonSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getPendingLessonsCount() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/student/lessons/pending',
    );
    final content = res.data?['content'];
    return content is List ? content.length : 0;
  }

  Future<List<BookingSummaryDto>> getBookings() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/bookings',
      queryParameters: {'page': 1, 'pageSize': 10},
    );
    final content = res.data?['content'];
    final raw = content is List
        ? content
        : (content as Map<String, dynamic>?)?['items'] as List<dynamic>? ?? [];
    return raw
        .map((e) => BookingSummaryDto.fromJson(e as Map<String, dynamic>))
        .where(
          (b) => ![
            'cancelled',
            'rejected',
            'expired',
          ].contains(b.status.toLowerCase()),
        )
        .toList();
  }
}

final dashboardDatasourceProvider = Provider<DashboardDatasource>(
  (ref) => DashboardDatasource(ref.read(apiClientProvider)),
);
