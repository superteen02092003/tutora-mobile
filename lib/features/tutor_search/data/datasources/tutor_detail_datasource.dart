import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';

class TutorDetailDatasource {
  const TutorDetailDatasource(this._dio);
  final Dio _dio;

  Future<TutorFullProfileDto> getFullProfile(String tutorId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/Tutor/$tutorId/full-profile-landing-page',
      );
      return TutorFullProfileDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final tutorDetailDatasourceProvider = Provider<TutorDetailDatasource>((ref) {
  return TutorDetailDatasource(ref.read(apiClientProvider));
});
