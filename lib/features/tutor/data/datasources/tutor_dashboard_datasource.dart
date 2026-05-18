import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';

class TutorDashboardDatasource {
  const TutorDashboardDatasource(this._dio);

  final Dio _dio;

  Future<TutorDashboardDto> getDashboard() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutor/lessons/dashboard',
    );
    return TutorDashboardDto.fromJson(res.data!);
  }
}

final tutorDashboardDatasourceProvider = Provider<TutorDashboardDatasource>(
  (ref) => TutorDashboardDatasource(ref.read(apiClientProvider)),
);
