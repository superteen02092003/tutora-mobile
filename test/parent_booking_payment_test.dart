import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';

ParentBookingDto make({
  required String status,
  String? depositPaidAt,
  String? remainingPaidAt,
  double? remainingAmount,
  double? depositAmount,
}) => ParentBookingDto.fromJson({
  'bookingId': 1,
  'status': status,
  'depositAmount': ?depositAmount,
  'remainingAmount': ?remainingAmount,
  'depositPaidAt': ?depositPaidAt,
  'remainingPaidAt': ?remainingPaidAt,
});

void main() {
  test('đợt 1: chỉ pending_payment/accepted mới là chờ trả phí buổi đầu', () {
    expect(make(status: 'pending_payment').needsDeposit, isTrue);
    expect(make(status: 'accepted').needsDeposit, isTrue);

    // BE chỉ nhận 2 status trên cho GetDepositPaymentInfoAsync.
    expect(make(status: 'pending_tutor').needsDeposit, isFalse);
    expect(make(status: 'deposit_paid').needsDeposit, isFalse);
  });

  test('đợt 2: pending_remaining_payment là chờ trả nốt', () {
    final b = make(
      status: 'pending_remaining_payment',
      remainingAmount: 630000,
    );
    expect(b.needsRemaining, isTrue);
    expect(b.needsDeposit, isFalse);
    expect(b.amountDue, 630000);
  });

  test('đã trả nốt thì không đòi nữa', () {
    expect(
      make(
        status: 'pending_remaining_payment',
        remainingAmount: 630000,
        remainingPaidAt: '2026-08-18T02:00:00Z',
      ).needsRemaining,
      isFalse,
    );
  });

  test('deposit_paid CHƯA tới hạn đợt 2 dù còn nợ tiền', () {
    // Bug cũ: cứ remainingAmount > 0 là đòi trả nốt, nên lớp vừa được gia sư
    // nhận (chưa học buổi nào) đã bị dán nhãn "Cần trả nốt". Đợt 2 chỉ tới hạn
    // khi BE chuyển sang pending_remaining_payment — sau khi buổi đầu học xong.
    final justAccepted = make(
      status: 'deposit_paid',
      depositPaidAt: '2026-08-17T14:30:00Z',
      remainingAmount: 630000,
    );
    expect(justAccepted.needsRemaining, isFalse);
    expect(justAccepted.needsPayment, isFalse);
    expect(justAccepted.isLearning, isTrue);
  });

  test('amountDue lấy đúng số tiền của đợt đang chờ', () {
    expect(
      make(
        status: 'pending_payment',
        depositAmount: 157500,
        remainingAmount: 630000,
      ).amountDue,
      157500,
    );
  });

  test('nhóm trạng thái kết thúc: huỷ, no-show, hết hạn thanh toán', () {
    expect(make(status: 'cancelled').isClosed, isTrue);
    expect(make(status: 'cancelled_noshow').isClosed, isTrue);
    expect(make(status: 'payment_timeout').isClosed, isTrue);
    expect(make(status: 'completed').isClosed, isFalse);
    expect(make(status: 'completed').isCompleted, isTrue);
  });

  test('đếm buổi đã học từ classSessions', () {
    final b = ParentBookingDto.fromJson({
      'bookingId': 1,
      'status': 'pending_remaining_payment',
      'totalSessions': 10,
      'classSessions': [
        {'classSessionId': 748, 'sessionIndex': 1, 'status': 'completed'},
        {'classSessionId': 749, 'sessionIndex': 2, 'status': 'reserved'},
        {'classSessionId': 750, 'sessionIndex': 3, 'status': 'reserved'},
      ],
    });

    expect(b.sessions.length, 3);
    expect(b.doneSessions, 1);
    // Tổng buổi lấy từ BE, không phải số buổi đã sinh.
    expect(b.totalSessionCount, 10);
    expect(b.sessions[1].isLocked, isTrue);
  });

  test('paging giữ được metadata để cuộn tiếp', () {
    final page = ParentBookingPage.fromJson({
      'content': {
        'items': [
          {'bookingId': 271, 'status': 'pending_tutor'},
        ],
        'totalCount': 25,
        'currentPage': 1,
        'totalPages': 2,
        'pageSize': 20,
      },
    });

    expect(page.items.length, 1);
    expect(page.totalCount, 25);
    expect(page.hasMore, isTrue);

    final last = ParentBookingPage.fromJson({
      'content': {
        'items': <dynamic>[],
        'totalCount': 25,
        'currentPage': 2,
        'totalPages': 2,
      },
    });
    expect(last.hasMore, isFalse);
  });
}
