import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_search_models.dart';

class TutorSearchDatasource {
  const TutorSearchDatasource(this._dio);

  final Dio _dio;

  Future<TutorSearchPage> search({
    String? searchTerm,
    String? category,
    String? gradeLevel,
    String? teachingMode,
    String? teachingAreaCity,
    double? minHourlyRate,
    double? maxHourlyRate,
    double? minRating,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final params = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (searchTerm?.isNotEmpty ?? false) 'searchTerm': searchTerm,
        'category': ?category,
        'gradeLevel': ?gradeLevel,
        'teachingMode': ?teachingMode,
        'teachingAreaCity': ?teachingAreaCity,
        'minHourlyRate': ?minHourlyRate,
        'maxHourlyRate': ?maxHourlyRate,
        'minRating': ?minRating,
        'sortBy': ?sortBy,
      };

      final response = await _dio.get<dynamic>(
        '/tutor-search',
        queryParameters: params,
      );
      return TutorSearchPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final tutorSearchDatasourceProvider = Provider<TutorSearchDatasource>((ref) {
  return TutorSearchDatasource(ref.read(apiClientProvider));
});
