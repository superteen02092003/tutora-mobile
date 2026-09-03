import 'package:tutora/features/student/presentation/widgets/booking_form.dart';

/// Một lượt đặt lịch đang dở, khoá theo gia sư.
class BookingDraft {
  const BookingDraft({required this.step, required this.form});

  final int step;
  final BookingForm form;
}

/// Draft giữ trong RAM, mất khi tắt app — chỉ hỏi lại trong cùng phiên.
class BookingDraftStore {
  BookingDraftStore._();

  static final Map<String, BookingDraft> _drafts = {};

  /// Bước cuối còn khôi phục được của luồng học sinh (5 bước): bước sau nó là Thanh toán
  static const lastResumableStep = 3;

  static void save(
    String tutorId, {
    required int step,
    required BookingForm form,
    // Luồng phụ huynh có thêm bước "Hình thức" nên bước xác nhận lùi xuống 4 —
    // dùng chung hằng số của học sinh sẽ xoá oan draft ở bước xác nhận.
    int lastResumable = lastResumableStep,
  }) {
    // Đã sang bước thanh toán thì bỏ draft — booking đã nằm ở BE.
    if (step > lastResumable) {
      _drafts.remove(tutorId);
      return;
    }
    // Bước 0 vẫn lưu nếu người dùng đã chọn được môn, để không mất công chọn lại.
    if (step == 0 && form.subjectId == 0) {
      _drafts.remove(tutorId);
      return;
    }
    _drafts[tutorId] = BookingDraft(step: step, form: form);
  }

  static BookingDraft? read(String tutorId) => _drafts[tutorId];

  static void clear(String tutorId) => _drafts.remove(tutorId);
}
