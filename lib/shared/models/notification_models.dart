import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';

class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['notificationid'] as int,
      userId: json['userid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isread'] as bool? ?? false,
      createdAt: json['createdat'] != null
          ? DateTime.tryParse(json['createdat'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  final int id;
  final String userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationDto copyWith({bool? isRead}) => NotificationDto(
    id: id,
    userId: userId,
    title: title,
    message: message,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('d/M/y').format(createdAt);
  }

  NotificationCategory get category {
    final t = title.toLowerCase();
    final m = message.toLowerCase();
    if (t.contains('booking') ||
        t.contains('đặt lịch') ||
        m.contains('booking')) {
      return NotificationCategory.booking;
    }
    if (t.contains('bài học') ||
        t.contains('buổi học') ||
        t.contains('lesson') ||
        m.contains('buổi học') ||
        m.contains('lesson')) {
      return NotificationCategory.lesson;
    }
    if (t.contains('thanh toán') ||
        t.contains('tiền') ||
        t.contains('ví') ||
        t.contains('payment') ||
        t.contains('giải ngân')) {
      return NotificationCategory.payment;
    }
    return NotificationCategory.system;
  }

  IconData get icon => switch (category) {
    NotificationCategory.booking => Icons.event_available_outlined,
    NotificationCategory.lesson => Icons.menu_book_outlined,
    NotificationCategory.payment => Icons.payments_outlined,
    NotificationCategory.system => Icons.info_outline,
  };

  Color get iconBg => switch (category) {
    NotificationCategory.booking => const Color(0xFFE8F0FE),
    NotificationCategory.lesson => const Color(0xFFD5EDD9),
    NotificationCategory.payment => const Color(0xFFFFF3CD),
    NotificationCategory.system => AppColors.cream2,
  };

  Color get iconColor => switch (category) {
    NotificationCategory.booking => const Color(0xFF3D6EEA),
    NotificationCategory.lesson => AppColors.moss,
    NotificationCategory.payment => const Color(0xFF7A5900),
    NotificationCategory.system => AppColors.ink3,
  };
}

enum NotificationCategory { booking, lesson, payment, system }
