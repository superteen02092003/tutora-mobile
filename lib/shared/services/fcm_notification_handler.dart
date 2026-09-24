import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/network/interceptors/auth_interceptor.dart'
    show navigatorKeyProvider;
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/shared/providers/notification_provider.dart';

const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Thông báo quan trọng',
  description:
      'Kênh hiển thị thông báo realtime (lịch dạy, buổi học, báo cáo...)',
  importance: Importance.max,
);

class FcmNotificationHandler {
  FcmNotificationHandler(this._storage, this._navigatorKey, this._onPush);

  final SecureStorageService _storage;
  final GlobalKey<NavigatorState> _navigatorKey;

  /// Gọi mỗi khi có push tới lúc app đang mở.
  final void Function(String type, String? referenceId) _onPush;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    // Không có Firebase (thiếu google-services.json) → không có push để xử lý.
    if (Firebase.apps.isEmpty) return;
    _initialized = true;

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null) return;
        final parts = payload.split('|');
        if (parts.length == 2) {
          await _navigateFromData({'type': parts[0], 'referenceId': parts[1]});
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _navigateFromData(message.data),
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _navigateFromData(initialMessage.data);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String?;
    final referenceId = message.data['referenceId'] as String?;

    if (type != null) _onPush(type, referenceId);
    final payload = (type != null && referenceId != null)
        ? '$type|$referenceId'
        : null;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_name',
          largeIcon: const DrawableResourceAndroidBitmap(
            'ic_notification_logo',
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> _navigateFromData(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final referenceId = data['referenceId'] as String?;
    if (type == null || referenceId == null || referenceId.isEmpty) return;

    final path = await _resolvePath(type, referenceId);
    if (path == null) return;

    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    GoRouter.of(context).go(path);
  }

  Future<String?> _resolvePath(String type, String referenceId) async {
    final accessToken = await _storage.getAccessToken();
    final claims = accessToken == null ? null : parseJwt(accessToken);
    final role = claims?.role ?? UserRole.unknown;

    // App chỉ dành cho gia sư — vai trò khác không điều hướng.
    if (role != UserRole.tutor) return null;

    switch (type) {
      case 'booking_new':
      case 'booking_accepted':
      case 'booking_declined':
        return AppRoutes.tutorSchedule;

      case 'warning':
        return AppRoutes.tutorProfile;

      default:
        return null;
    }
  }
}

final fcmNotificationHandlerProvider = Provider<FcmNotificationHandler>((ref) {
  return FcmNotificationHandler(
    ref.read(secureStorageProvider),
    ref.read(navigatorKeyProvider),
    (type, referenceId) => refreshOnPush(ref, type),
  );
});

/// Nạp lại dữ liệu liên quan tới loại push vừa nhận.
void refreshOnPush(Ref ref, String type) {
  ref.invalidate(unreadCountProvider);
}
