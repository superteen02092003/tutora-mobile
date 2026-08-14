import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/student/data/models/class_models.dart';

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
}
