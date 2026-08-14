import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/material_models.dart';

export 'package:tutora/features/student/data/models/material_models.dart';

/// Tài liệu học tập của một lớp học (booking).
class MaterialDatasource {
  const MaterialDatasource(this._dio);
  final Dio _dio;

  Future<List<LearningMaterialDto>> getByBooking(int bookingId) async {
    final resp = await _dio.get<dynamic>('/bookings/$bookingId/materials');
    final data = resp.data;
    final content = data is Map<String, dynamic> ? data['content'] : null;
    final items = content is List ? content : const <dynamic>[];
    return items
        .map((e) => LearningMaterialDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final materialDatasourceProvider = Provider<MaterialDatasource>((ref) {
  return MaterialDatasource(ref.read(apiClientProvider));
});
