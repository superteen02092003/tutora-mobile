import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/student/presentation/widgets/booking_draft_store.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';

void main() {
  setUp(() => BookingDraftStore.clear('t1'));

  test('giữ draft ở bước Xác nhận (bug cũ: step>2 bị xoá)', () {
    BookingDraftStore.save('t1', step: 3, form: BookingForm(subjectId: 5));
    expect(BookingDraftStore.read('t1')?.step, 3);
  });

  test('giữ draft ở bước 0 khi đã chọn môn', () {
    BookingDraftStore.save('t1', step: 0, form: BookingForm(subjectId: 5));
    expect(BookingDraftStore.read('t1'), isNotNull);
  });

  test('bước 0 chưa chọn môn thì không lưu', () {
    BookingDraftStore.save('t1', step: 0, form: BookingForm());
    expect(BookingDraftStore.read('t1'), isNull);
  });

  test('sang bước thanh toán thì bỏ draft', () {
    BookingDraftStore.save('t1', step: 2, form: BookingForm(subjectId: 5));
    BookingDraftStore.save('t1', step: 4, form: BookingForm(subjectId: 5));
    expect(BookingDraftStore.read('t1'), isNull);
  });

  test('luồng phụ huynh (6 bước): giữ draft ở bước Xác nhận = 4', () {
    // Ngưỡng của học sinh là 3, dùng chung sẽ xoá oan draft bước xác nhận.
    BookingDraftStore.save(
      't1',
      step: 4,
      form: BookingForm(subjectId: 5),
      lastResumable: 4,
    );
    expect(BookingDraftStore.read('t1')?.step, 4);
  });

  test('luồng phụ huynh: sang bước thanh toán = 5 thì bỏ draft', () {
    BookingDraftStore.save(
      't1',
      step: 4,
      form: BookingForm(subjectId: 5),
      lastResumable: 4,
    );
    BookingDraftStore.save(
      't1',
      step: 5,
      form: BookingForm(subjectId: 5),
      lastResumable: 4,
    );
    expect(BookingDraftStore.read('t1'), isNull);
  });

  test('draft tách theo từng gia sư', () {
    BookingDraftStore.save('t1', step: 2, form: BookingForm(subjectId: 5));
    expect(BookingDraftStore.read('t2'), isNull);
    BookingDraftStore.clear('t1');
  });
}
