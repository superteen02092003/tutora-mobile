import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/tutor_dispute_models.dart';

/// Lỗi nghiệp vụ khi thao tác khiếu nại — mang message tiếng Việt từ backend.
class TutorDisputeException implements Exception {
  const TutorDisputeException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Endpoint khiếu nại phía gia sư.
///
/// - `GET  /tutor/disputes` — danh sách (envelope `content` là **mảng**, do
///   backend trả `PagedList<T>` kế thừa `List<T>`).
/// - `GET  /tutor/class-sessions/{id}/dispute` — chi tiết theo buổi học.
/// - `POST /tutor/class-sessions/{id}/dispute/response` — gửi phản hồi.
/// - `GET/POST .../dispute/thread[/messages]` — trao đổi riêng với admin.
class TutorDisputeDatasource {
  const TutorDisputeDatasource(this._dio);

  final Dio _dio;

  static List<dynamic> _contentList(Response<dynamic> res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final c = data['content'];
      if (c is List) return c;
      // Phòng khi backend đổi sang bọc { items: [...] }.
      if (c is Map<String, dynamic>) {
        final items = c['items'];
        if (items is List) return items;
      }
    }
    if (data is List) return data;
    return const [];
  }

  static Map<String, dynamic> _contentMap(Response<dynamic> res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final c = data['content'];
      if (c is Map<String, dynamic>) return c;
    }
    return const {};
  }

  static Never _rethrowAsBusiness(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) throw TutorDisputeException(msg);
    }
    throw const TutorDisputeException('Không thực hiện được. Thử lại sau.');
  }

  Future<List<TutorDisputeDto>> getDisputes({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      '/tutor/disputes',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return _contentList(
      res,
    ).whereType<Map<String, dynamic>>().map(TutorDisputeDto.fromJson).toList();
  }

  /// Chi tiết khiếu nại của một buổi học. Trả null khi buổi đó không có
  /// khiếu nại (backend trả 404 cho trường hợp này).
  Future<TutorDisputeDetailDto?> getDisputeBySession(int classSessionId) async {
    try {
      final res = await _dio.get<dynamic>(
        '/tutor/class-sessions/$classSessionId/dispute',
      );
      return TutorDisputeDetailDto.fromJson(_contentMap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _rethrowAsBusiness(e);
    }
  }

  Future<TutorDisputeDetailDto> submitResponse({
    required int classSessionId,
    required String response,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        '/tutor/class-sessions/$classSessionId/dispute/response',
        data: {'response': response},
      );
      return TutorDisputeDetailDto.fromJson(_contentMap(res));
    } on DioException catch (e) {
      _rethrowAsBusiness(e);
    }
  }

  /// Nộp thêm ảnh/tệp bằng chứng cho khiếu nại của một buổi học.
  ///
  /// Backend nhận `IFormFile file` (multipart) và chỉ cho nộp khi khiếu nại
  /// còn ở trạng thái `pending`. Trả về URL tệp đã lưu.
  Future<String> uploadEvidence({
    required int classSessionId,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post<dynamic>(
        '/tutor/class-sessions/$classSessionId/dispute/evidence',
        data: formData,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final content = data['content'];
        if (content is String) return content;
      }
      return '';
    } on DioException catch (e) {
      _rethrowAsBusiness(e);
    }
  }

  Future<List<DisputeMessageDto>> getThread(int classSessionId) async {
    final res = await _dio.get<dynamic>(
      '/tutor/class-sessions/$classSessionId/dispute/thread',
    );
    return _contentList(res)
        .whereType<Map<String, dynamic>>()
        .map(DisputeMessageDto.fromJson)
        .toList();
  }

  Future<DisputeMessageDto> sendThreadMessage({
    required int classSessionId,
    required String message,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        '/tutor/class-sessions/$classSessionId/dispute/thread/messages',
        data: {'message': message},
      );
      return DisputeMessageDto.fromJson(_contentMap(res));
    } on DioException catch (e) {
      _rethrowAsBusiness(e);
    }
  }
}

final Provider<TutorDisputeDatasource> tutorDisputeDatasourceProvider =
    Provider<TutorDisputeDatasource>(
      (ref) => TutorDisputeDatasource(ref.read(apiClientProvider)),
    );
