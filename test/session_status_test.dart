import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';

TutorLessonDto make(String status, {String? checkOut}) => TutorLessonDto(
  lessonId: 1,
  bookingId: 1,
  studentName: 'A',
  subjectName: 'Toán',
  scheduledStart: '2026-08-17T05:00:00Z',
  scheduledEnd: '2026-08-17T06:00:00Z',
  status: status,
  checkOutTime: checkOut,
);

void main() {
  test('in_progress + checkOut = chờ báo cáo, không phải đang dạy', () {
    final s = make('in_progress', checkOut: '2026-08-17T06:00:00Z');
    expect(s.isAwaitingReport, isTrue);
    expect(s.isLive, isFalse);
  });

  test('in_progress chưa checkOut = đang dạy', () {
    final s = make('in_progress');
    expect(s.isLive, isTrue);
    expect(s.isAwaitingReport, isFalse);
  });

  test('countsAsSession loại cancelled, cancelled_noshow, reserved', () {
    expect(make('cancelled').countsAsSession, isFalse);
    expect(make('cancelled_noshow').countsAsSession, isFalse);
    expect(make('reserved').countsAsSession, isFalse);
    expect(make('scheduled').countsAsSession, isTrue);
    expect(make('completed').countsAsSession, isTrue);
    expect(make('disputed').countsAsSession, isTrue);
    expect(make('pending_confirmation').countsAsSession, isTrue);
  });

  test('no_show vẫn là buổi thật — đã tới giờ, chỉ một bên vắng', () {
    expect(make('no_show').countsAsSession, isTrue);
    expect(make('no_show').isNoShow, isTrue);
  });

  test('pending_confirmation là đã gửi báo cáo, khác completed', () {
    expect(make('pending_confirmation').isPendingConfirmation, isTrue);
    expect(make('pending_confirmation').isCompleted, isFalse);
    expect(make('pending_confirmation').isFinished, isTrue);
  });

  test('disputed không bị nhầm sang huỷ', () {
    expect(make('disputed').isDisputed, isTrue);
    expect(make('disputed').isCancelled, isFalse);
  });

  test('lessonChip phủ đủ 9 trạng thái, không gộp bừa vào "Đã huỷ"', () {
    expect(lessonChip('scheduled').$1, 'Sắp diễn ra');
    expect(lessonChip('reserved').$1, 'Giữ chỗ');
    expect(lessonChip('in_progress').$1, 'Đang dạy');
    expect(lessonChip('pending_confirmation').$1, 'Chờ xác nhận');
    expect(lessonChip('completed').$1, 'Hoàn thành');
    expect(lessonChip('disputed').$1, 'Đang tranh chấp');
    expect(lessonChip('no_show').$1, 'Vắng mặt');
    expect(lessonChip('cancelled_noshow').$1, 'Vắng mặt');
    expect(lessonChip('cancelled').$1, 'Đã huỷ');
  });
}
