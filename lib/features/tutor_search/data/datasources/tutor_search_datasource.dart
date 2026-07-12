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
    List<int>? subjectIds,
    // String? teachingMode, // disabled in UI, kept for future use
    String? teachingAreaCity,
    String? budgetRange,
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
        if (category?.isNotEmpty ?? false) 'category': category,
        if (gradeLevel?.isNotEmpty ?? false) 'gradeLevel': gradeLevel,
        if (subjectIds != null && subjectIds.isNotEmpty)
          'subjectIds': subjectIds.join(','),
        // if (teachingMode?.isNotEmpty ?? false) 'teachingMode': teachingMode,
        if (teachingAreaCity?.isNotEmpty ?? false)
          'teachingAreaCity': teachingAreaCity,
        if (budgetRange?.isNotEmpty ?? false) 'budgetRange': budgetRange,
        'minHourlyRate': ?minHourlyRate,
        'maxHourlyRate': ?maxHourlyRate,
        'minRating': ?minRating,
        if (sortBy?.isNotEmpty ?? false) 'sortBy': sortBy,
      };

      final response = await _dio.get<dynamic>(
        '/tutors/search',
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
