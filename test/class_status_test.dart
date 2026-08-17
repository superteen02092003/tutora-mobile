import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/shared/models/class_models.dart';

StudentClassDto make(String status) => StudentClassDto.fromJson({
  'bookingId': 1,
  'status': status,
  'paymentStatus': '',
  'classSessions': <dynamic>[],
});

void main() {
  test('deposit_paid KHÔNG còn là "Chờ thanh toán"', () {
    expect(make('deposit_paid').statusType, ClassStatusType.depositPaid);
  });

  test('chỉ pending_payment/accepted mới là chưa trả phí', () {
    expect(make('pending_payment').statusType, ClassStatusType.unpaid);
    expect(make('accepted').statusType, ClassStatusType.unpaid);
  });

  test('chưa trả phí buổi đầu thì chưa phải lớp đang học', () {
    for (final s in ['pending_payment', 'accepted', 'pending_tutor']) {
      expect(make(s).isOngoing, isFalse, reason: s);
    }
  });

  test('đã trả phí buổi đầu thì là lớp đang học', () {
    for (final s in ['deposit_paid', 'ongoing', 'pending_remaining_payment']) {
      expect(make(s).isOngoing, isTrue, reason: s);
    }
  });

  test('no_show vẫn tính vào mẫu số tiến độ, cancelled_noshow thì không', () {
    StudentClassDto withSessions(List<String> statuses) =>
        StudentClassDto.fromJson({
          'bookingId': 1,
          'status': 'ongoing',
          'paymentStatus': 'paid',
          'totalSessions': statuses.length,
          'classSessions': [
            for (var i = 0; i < statuses.length; i++)
              {
                'classSessionId': i + 1,
                'sessionIndex': i + 1,
                'scheduledStart': '2026-08-${20 + i}T01:30:00Z',
                'scheduledEnd': '2026-08-${20 + i}T02:30:00Z',
                'status': statuses[i],
              },
          ],
        });

    // Bug cũ: no_show bị loại -> lớp 5 buổi hiện "1/4".
    final k = withSessions([
      'completed',
      'no_show',
      'scheduled',
      'scheduled',
      'scheduled',
    ]);
    expect(k.countedSessions, 5);
    expect(k.doneSessions, 1);

    // cancelled_noshow là huỷ, không đếm — trước rơi vào default 'scheduled'.
    expect(
      withSessions([
        'completed',
        'cancelled_noshow',
        'scheduled',
      ]).countedSessions,
      2,
    );
    expect(withSessions(['completed', 'cancelled']).countedSessions, 1);
  });
}
