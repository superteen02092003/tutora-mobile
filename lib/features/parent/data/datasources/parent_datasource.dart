import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/shared/models/class_models.dart';

export 'package:tutora/features/parent/data/models/parent_models.dart';
export 'package:tutora/shared/models/class_models.dart';

class ParentActionException implements Exception {
  const ParentActionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ParentDatasource {
  const ParentDatasource(this._dio);
  final Dio _dio;

  Future<List<ParentStudentDto>> getStudents() async {
    final res = await _dio.get<dynamic>('/parent/students');
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ParentStudentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ParentStudentDto> getStudent(String studentId) async {
    final res = await _dio.get<dynamic>('/parent/students/$studentId');
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as Map<String, dynamic>? ?? data;
    return ParentStudentDto.fromJson(content);
  }

  Future<List<ParentLessonDto>> getPendingLessons() async {
    final res = await _dio.get<dynamic>('/parent/class-sessions/pending');
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ParentLessonDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lịch chung của mọi con
  Future<List<ParentLessonDto>> getCalendarLessons({
    required String startDate,
    required String endDate,
  }) async {
    final res = await _dio.get<dynamic>(
      '/parent/class-sessions/calendar',
      queryParameters: {'startDate': startDate, 'endDate': endDate},
    );
    final data = res.data as Map<String, dynamic>;
    final days = data['content'] as List<dynamic>? ?? [];
    return days
        .expand(
          (d) =>
              ((d as Map<String, dynamic>)['classSessions'] as List<dynamic>? ??
                      [])
                  .map(
                    (e) => ParentLessonDto.fromJson(e as Map<String, dynamic>),
                  ),
        )
        .toList();
  }

  /// Buổi kế tiếp
  Future<ParentLessonDto?> getNextLesson({String? studentId}) async {
    final res = await _dio.get<dynamic>(
      '/parent/class-sessions/next',
      queryParameters: {'studentId': ?studentId},
    );
    final content = (res.data as Map<String, dynamic>)['content'];
    if (content is! Map<String, dynamic>) return null;
    return ParentLessonDto.fromJson(content);
  }

  /// Đề xuất dời buổi học sang giờ khác. Buổi chỉ đổi khi gia sư đồng ý.
  Future<void> proposeReschedule({
    required int lessonId,
    required DateTime proposedStart,
    String? reason,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/parent/class-sessions/$lessonId/reschedule-proposal',
        data: {
          'proposedScheduledStart': proposedStart.toUtc().toIso8601String(),
          'reason': ?reason,
        },
      );
    } on DioException catch (e) {
      // BE trả lý do cụ thể (sát giờ, đã có đề xuất chờ...) — hiện nguyên văn.
      final data = e.response?.data;
      final msg = data is Map<String, dynamic> ? data['message'] : null;
      throw ParentActionException(
        msg is String && msg.isNotEmpty
            ? msg
            : 'Không gửi được đề xuất đổi lịch',
      );
    }
  }

  Future<ParentHomeStatsDto> getHomeStats({String? studentId}) async {
    final res = await _dio.get<dynamic>(
      '/parent/home-stats',
      queryParameters: {'studentId': ?studentId},
    );
    final data = res.data as Map<String, dynamic>;
    return ParentHomeStatsDto.fromJson(
      data['content'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Lớp học (booking) của một con.
  Future<StudentClassPagedResult> getChildClasses({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    String? status,
    bool excludeClosed = false,
  }) async {
    final res = await _dio.get<dynamic>(
      '/parent/students/$studentId/bookings',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'status': ?status,
        if (excludeClosed) 'excludeClosed': true,
      },
    );
    return StudentClassPagedResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Buổi học của một con, list phẳng có `studentId`.
  Future<List<ParentLessonDto>> getChildLessons({
    required String studentId,
    String? startDate,
    String? endDate,
  }) async {
    final res = await _dio.get<dynamic>(
      '/parent/students/$studentId/class-sessions',
      queryParameters: {'startDate': ?startDate, 'endDate': ?endDate},
    );
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ParentLessonDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Xác nhận buổi học hoàn tất. Trả về message kết quả settlement từ backend
  /// (giải ngân/hoàn tiền/số buổi còn lại) nếu có, để hiển thị cho phụ huynh.
  Future<String?> confirmLesson(int lessonId) async {
    final res = await _dio.put<dynamic>(
      '/parent/class-sessions/$lessonId/confirm',
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final content = data['content'];
      if (content is Map<String, dynamic>) {
        final msg = content['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    }
    return null;
  }

  Future<ParentLessonDto> getLessonDetail(int lessonId) async {
    final res = await _dio.get<dynamic>('/parent/class-sessions/$lessonId');
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as Map<String, dynamic>? ?? data;
    return ParentLessonDto.fromJson(content);
  }

  Future<List<GradeLevelDto>> getGradeLevels() async {
    final res = await _dio.get<dynamic>('/grade-levels');
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => GradeLevelDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AddStudentResult> addStudent({
    required String fullname,
    required String birthdate,
    required String school,
    required int gradeLevelId,
    String? learninggoals,
  }) async {
    final res = await _dio.post<dynamic>(
      '/parent/students',
      data: {
        'fullname': fullname,
        'birthdate': birthdate,
        'school': school,
        'gradeLevelId': gradeLevelId,
        if (learninggoals != null && learninggoals.isNotEmpty)
          'learninggoals': learninggoals,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as Map<String, dynamic>;
    return AddStudentResult.fromJson(content);
  }

  /// Đơn đặt lịch của mọi con. `status` nhận nhiều giá trị cách nhau bằng dấu
  /// phẩy.
  Future<ParentBookingPage> getBookings({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final res = await _dio.get<dynamic>(
      '/parent/bookings',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'status': ?(status?.isEmpty ?? true) ? null : status,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return ParentBookingPage.fromJson(data);
  }

  /// Chi tiết một đơn — có đủ classSessions, mốc thanh toán, lý do huỷ.
  Future<ParentBookingDto> getBookingDetail(int bookingId) async {
    final res = await _dio.get<dynamic>('/bookings/$bookingId');
    final data = res.data as Map<String, dynamic>;
    return ParentBookingDto.fromJson(data['content'] as Map<String, dynamic>);
  }

  /// Thông tin chuyển khoản cho đợt đang chờ trả.
  Future<ParentPaymentInfo> getPaymentInfo(int bookingId) async {
    try {
      final res = await _dio.get<dynamic>('/bookings/$bookingId/payment');
      final data = res.data as Map<String, dynamic>;
      return ParentPaymentInfo.fromJson(
        data['content'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ParentActionException(
        _message(e, 'Không lấy được thông tin thanh toán'),
      );
    }
  }

  /// Đối soát sau khi phụ huynh bảo đã chuyển khoản.
  Future<ParentPaymentStatus> getPaymentStatus(int bookingId) async {
    final res = await _dio.get<dynamic>('/bookings/$bookingId/payment/status');
    final data = res.data as Map<String, dynamic>;
    return ParentPaymentStatus.fromJson(
      data['content'] as Map<String, dynamic>,
    );
  }

  static String _message(DioException e, String fallback) {
    final data = e.response?.data;
    final msg = data is Map<String, dynamic> ? data['message'] : null;
    return msg is String && msg.isNotEmpty ? msg : fallback;
  }
}

final parentDatasourceProvider = Provider<ParentDatasource>((ref) {
  return ParentDatasource(ref.watch(apiClientProvider));
});
