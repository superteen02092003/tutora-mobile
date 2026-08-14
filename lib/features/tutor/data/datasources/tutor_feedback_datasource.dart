import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/tutor_feedback_models.dart';

/// Đánh giá phụ huynh dành cho gia sư — `GET /api/tutors/me/feedbacks`.
class TutorFeedbackDatasource {
  const TutorFeedbackDatasource(this._dio);

  final Dio _dio;

  Future<List<TutorFeedbackDto>> getMyFeedbacks({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      '/tutors/me/feedbacks',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    final data = res.data;
    var list = const <dynamic>[];
    if (data is Map<String, dynamic>) {
      final content = data['content'];
      if (content is List) {
        list = content;
      } else if (content is Map<String, dynamic> && content['items'] is List) {
        // Phòng khi backend đổi sang bọc { items: [...] }.
        list = content['items'] as List<dynamic>;
      }
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(TutorFeedbackDto.fromJson)
        .toList();
  }
}

final Provider<TutorFeedbackDatasource> tutorFeedbackDatasourceProvider =
    Provider<TutorFeedbackDatasource>(
      (ref) => TutorFeedbackDatasource(ref.read(apiClientProvider)),
    );

/// Danh sách đánh giá của gia sư đang đăng nhập.
final AutoDisposeFutureProvider<List<TutorFeedbackDto>> tutorFeedbacksProvider =
    FutureProvider.autoDispose<List<TutorFeedbackDto>>((ref) {
      return ref.read(tutorFeedbackDatasourceProvider).getMyFeedbacks();
    });
