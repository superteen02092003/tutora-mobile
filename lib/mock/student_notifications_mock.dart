import 'package:flutter/material.dart';

enum NotificationType { lesson, review, system }

class MockNotification {
  const MockNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  IconData get icon => switch (type) {
    NotificationType.lesson => Icons.event_note_outlined,
    NotificationType.review => Icons.rate_review_outlined,
    NotificationType.system => Icons.info_outline,
  };

  MockNotification copyWith({bool? isRead}) => MockNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    time: time,
    isRead: isRead ?? this.isRead,
  );
}

final List<MockNotification> kMockNotifications = [
  const MockNotification(
    id: 'n1',
    type: NotificationType.lesson,
    title: 'Buổi học được xác nhận',
    body: 'Gia sư Minh Tuấn xác nhận buổi học Toán lúc 19:00 hôm nay.',
    time: '5p trước',
  ),
  const MockNotification(
    id: 'n2',
    type: NotificationType.review,
    title: 'Nhắc đánh giá gia sư',
    body:
        'Buổi học Vật Lý với Thầy Đức Huy hôm qua đã kết thúc. Hãy để lại đánh giá!',
    time: '1 giờ trước',
  ),
  const MockNotification(
    id: 'n3',
    type: NotificationType.lesson,
    title: 'Lịch học sắp tới',
    body:
        'Buổi học Tiếng Anh với Cô Linh Chi sẽ bắt đầu vào T7, 4/5 lúc 10:00.',
    time: '3 giờ trước',
    isRead: true,
  ),
  const MockNotification(
    id: 'n4',
    type: NotificationType.system,
    title: 'Cập nhật ứng dụng',
    body:
        'Phiên bản mới đã sẵn sàng. Cập nhật để trải nghiệm tính năng mới nhất.',
    time: 'Hôm qua',
    isRead: true,
  ),
  const MockNotification(
    id: 'n5',
    type: NotificationType.lesson,
    title: 'Buổi học bị huỷ',
    body:
        'Gia sư Mai Anh đã huỷ buổi học Toán ngày 28/4. Vui lòng đặt lịch lại.',
    time: '28/4',
    isRead: true,
  ),
  const MockNotification(
    id: 'n6',
    type: NotificationType.review,
    title: 'Gia sư phản hồi đánh giá',
    body: 'Thầy Quang đã phản hồi đánh giá của bạn về buổi Vật Lý ngày 25/4.',
    time: '26/4',
    isRead: true,
  ),
];
