import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/shared/live_session/live_session_models.dart';

const _kSessionActiveOnAnotherDevice = 'SESSION_ACTIVE_ON_ANOTHER_DEVICE';
const _kSessionLeaseRevoked = 'SESSION_LEASE_REVOKED';

/// Phiên đang mở trên thiết bị khác — cho phép takeover.
class SessionActiveOnAnotherDeviceException implements Exception {
  const SessionActiveOnAnotherDeviceException(this.conflict);
  final ActiveSessionConflict conflict;
}

/// Lease bị thu hồi (thiết bị khác đã takeover).
class SessionLeaseRevokedException implements Exception {
  const SessionLeaseRevokedException();
}

/// Lỗi nghiệp vụ vào phòng (payment gating, buổi đã kết thúc, phòng không khả dụng…).
class LiveSessionException implements Exception {
  const LiveSessionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Gọi các endpoint phòng học Agora theo hợp đồng lease.
class LiveSessionDatasource {
  const LiveSessionDatasource(this._dio);

  final Dio _dio;

  Future<LiveSessionRoom> join(
    int classSessionId,
    LiveSessionIdentity identity,
  ) async {
    return _joinLike(
      '/agora/room/$classSessionId/join',
      identity.toJson(),
    );
  }

  Future<LiveSessionRoom> takeover(
    int classSessionId,
    LiveSessionIdentity identity,
    String expectedActiveLeaseId,
  ) async {
    return _joinLike('/agora/room/$classSessionId/takeover', {
      ...identity.toJson(),
      'expectedActiveLeaseId': expectedActiveLeaseId,
    });
  }

  Future<LiveSessionRoom> _joinLike(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post<dynamic>(path, data: body);
      return LiveSessionRoom.fromJson(_content(res));
    } on DioException catch (e) {
      _throwMapped(e);
    }
  }

  /// Heartbeat ~20s/lần. Trả presence để caller tự rời khi phòng đóng.
  Future<LiveSessionPresence> heartbeat(
    int classSessionId,
    LiveSessionRoom room,
  ) async {
    final res = await _dio.post<dynamic>(
      '/agora/room/$classSessionId/heartbeat',
      data: room.leaseJson,
    );
    return LiveSessionPresence.fromJson(_content(res));
  }

  /// Best-effort — nuốt lỗi để việc rời phòng không bao giờ bị chặn.
  Future<void> leave(int classSessionId, LiveSessionRoom room) async {
    try {
      await _dio.post<dynamic>(
        '/agora/room/$classSessionId/leave',
        data: room.leaseJson,
      );
    } catch (_) {
      // ignore
    }
  }

  static Map<String, dynamic> _content(Response<dynamic> res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final c = data['content'];
      if (c is Map<String, dynamic>) return c;
    }
    return const {};
  }

  /// Ánh xạ lỗi HTTP sang exception nghiệp vụ. Không bao giờ trả về (luôn ném).
  static Never _throwMapped(DioException e) {
    final status = e.response?.statusCode;
    final code = _errorCode(e);

    if (status == 409 && code == _kSessionActiveOnAnotherDevice) {
      final conflict = _conflictOf(e);
      if (conflict != null) {
        throw SessionActiveOnAnotherDeviceException(conflict);
      }
    }
    if (code == _kSessionLeaseRevoked) {
      throw const SessionLeaseRevokedException();
    }
    throw LiveSessionException(_messageOf(e));
  }

  /// Đọc code lỗi từ cả `error.code`, `code`, `content.code`, hoặc `error` là chuỗi.
  static String? _errorCode(DioException e) {
    final data = e.response?.data;
    if (data is! Map<String, dynamic>) return null;
    final err = data['error'];
    if (err is Map<String, dynamic>) {
      final c = err['code'];
      if (c is String && c.isNotEmpty) return c;
    }
    if (err is String && err.isNotEmpty) return err;
    final topCode = data['code'];
    if (topCode is String && topCode.isNotEmpty) return topCode;
    final content = data['content'];
    if (content is Map<String, dynamic>) {
      final c = content['code'];
      if (c is String && c.isNotEmpty) return c;
    }
    return null;
  }

  static ActiveSessionConflict? _conflictOf(DioException e) {
    final data = e.response?.data;
    if (data is! Map<String, dynamic>) return null;
    String? activeLeaseId;
    String? activeDeviceLabel;
    for (final node in [data['error'], data, data['content']]) {
      if (node is Map<String, dynamic>) {
        activeLeaseId ??= node['activeLeaseId'] as String?;
        activeDeviceLabel ??= node['activeDeviceLabel'] as String?;
      }
    }
    if (activeLeaseId == null || activeLeaseId.isEmpty) return null;
    return ActiveSessionConflict(
      activeLeaseId: activeLeaseId,
      activeDeviceLabel: activeDeviceLabel,
    );
  }

  static String _messageOf(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Không vào được phòng học. Vui lòng thử lại.';
  }
}

final liveSessionDatasourceProvider = Provider<LiveSessionDatasource>((ref) {
  return LiveSessionDatasource(ref.read(apiClientProvider));
});
