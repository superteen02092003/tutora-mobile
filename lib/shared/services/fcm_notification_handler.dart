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

const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Thông báo quan trọng',
  description:
      'Kênh hiển thị thông báo realtime (booking, buổi học, tin nhắn...)',
  importance: Importance.max,
);

class FcmNotificationHandler {
  FcmNotificationHandler(this._storage, this._navigatorKey);

  final SecureStorageService _storage;
  final GlobalKey<NavigatorState> _navigatorKey;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
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

    switch (type) {
      case 'booking_new':
      case 'booking_accepted':
      case 'booking_declined':
        return switch (role) {
          UserRole.student => '/student/bookings/$referenceId',
          UserRole.tutor => '/tutor/schedule/booking/$referenceId',
          UserRole.parent => AppRoutes.parentBookings,
          _ => null,
        };

      case 'lesson_checkin':
      case 'lesson_report':
      case 'lesson_confirmed':
      case 'lesson_no_show':
      case 'lesson_reminder':
        return switch (role) {
          UserRole.parent => '/parent/lesson/$referenceId/confirm',
          UserRole.student => AppRoutes.studentLessons,
          _ => null,
        };

      case 'payment_success':
        return switch (role) {
          UserRole.student => '/student/bookings/$referenceId',
          UserRole.parent => AppRoutes.parentBookings,
          _ => null,
        };

      case 'message':
        return switch (role) {
          UserRole.student => AppRoutes.studentMessages,
          UserRole.tutor => AppRoutes.tutorMessages,
          UserRole.parent => AppRoutes.parentHome,
          _ => null,
        };

      case 'warning':
        return switch (role) {
          UserRole.student => AppRoutes.studentProfile,
          UserRole.tutor => AppRoutes.tutorProfile,
          UserRole.parent => AppRoutes.parentProfile,
          _ => null,
        };

      default:
        return null;
    }
  }
}

final fcmNotificationHandlerProvider = Provider<FcmNotificationHandler>((ref) {
  return FcmNotificationHandler(
    ref.read(secureStorageProvider),
    ref.read(navigatorKeyProvider),
  );
});
