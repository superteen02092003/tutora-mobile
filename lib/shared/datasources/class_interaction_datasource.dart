import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';

/// Lỗi nghiệp vụ khi gửi đánh giá / khiếu nại.
class ClassInteractionException implements Exception {
  const ClassInteractionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Gửi đánh giá gia sư + khiếu nại buổi học (HS/PH).
/// Endpoints: /feedbacks(+eligibility), /parent/class-sessions/{id}/dispute.
class ClassInteractionDatasource {
  const ClassInteractionDatasource(this._dio);

  final Dio _dio;

  /// Kiểm tra có được đánh giá buổi học này không.
  Future<bool> canLeaveFeedback(int classSessionId) async {
    try {
      final res = await _dio.get<dynamic>(
        '/feedbacks/eligibility/class-sessions/$classSessionId',
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final c = data['content'];
        if (c is bool) return c;
      }
      return false;
    } on DioException {
      return false;
    }
  }

  /// Gửi đánh giá gia sư sau buổi học.
  Future<void> submitFeedback({
    required int classSessionId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/feedbacks',
        data: {
          'classSessionId': classSessionId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          'feedbackType': 'post_lesson',
        },
      );
    } on DioException catch (e) {
      throw ClassInteractionException(
        _messageOf(e, 'Không gửi được đánh giá.'),
      );
    }
  }

  /// Gửi khiếu nại buổi học. [disputeType]: no_show | quality | payment | other.
  Future<void> submitDispute({
    required int classSessionId,
    required String disputeType,
    required String reason,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/parent/class-sessions/$classSessionId/dispute',
        data: {'disputeType': disputeType, 'reason': reason},
      );
    } on DioException catch (e) {
      throw ClassInteractionException(
        _messageOf(e, 'Không gửi được khiếu nại.'),
      );
    }
  }

  static String _messageOf(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return fallback;
  }
}

final classInteractionDatasourceProvider = Provider<ClassInteractionDatasource>(
  (ref) {
    return ClassInteractionDatasource(ref.read(apiClientProvider));
  },
);

/// Có được đánh giá buổi học (id) không — dùng để ẩn/hiện nút "Đánh giá".
final AutoDisposeFutureProviderFamily<bool, int> canLeaveFeedbackProvider =
    FutureProvider.autoDispose.family<bool, int>((ref, id) {
      return ref.read(classInteractionDatasourceProvider).canLeaveFeedback(id);
    });
