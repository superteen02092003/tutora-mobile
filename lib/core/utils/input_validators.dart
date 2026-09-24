/// Kiểm tra định dạng dữ liệu nhập — dùng chung cho mọi form của app để một
/// loại ô (họ tên, SĐT, ngày sinh…) luôn theo cùng một quy tắc.
///
/// Mỗi hàm trả về câu báo lỗi tiếng Việt, hoặc `null` khi hợp lệ, nên cắm
/// thẳng được vào `validator:` của `TextFormField`. Giới hạn độ dài khớp với
/// DTO ở backend (UpdateUserRequest, RecorderStudentRequest).
library;

/// Số điện thoại Việt Nam: 0xxxxxxxxx, 84xxxxxxxxx hoặc +84xxxxxxxxx.
final RegExp vnPhoneRegExp = RegExp(r'^(\+?84|0)\d{9,10}$');

/// Chữ cái (kể cả tiếng Việt có dấu), cách nhau bởi một dấu cách hoặc
/// `.` `'` `-` — vd. "Nguyễn Văn A", "Chị Hương", "Lê Thị Ngọc-Anh".
final RegExp _personNameRegExp = RegExp(
  r"^[\p{L}\p{M}]+(?:[ .'\-]+[\p{L}\p{M}]+)*\.?$",
  unicode: true,
);

/// Môn học cho phép thêm số và vài ký hiệu hay gặp: "Toán 7", "Lý/Hoá",
/// "Tiếng Anh (IELTS)".
final RegExp _subjectRegExp = RegExp(
  r"^[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N} .,'/&()+\-]*$",
  unicode: true,
);

final RegExp _isoDateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Mật khẩu tối thiểu — dùng cho MỌI màn: đăng ký, đặt lại (quên mật khẩu), đổi mật khẩu.
/// Cùng quy định với web và backend.
const int passwordMinLength = 8;

const int nameMaxLength = 100;
const int subjectMaxLength = 100;
const int addressMaxLength = 255;
const int noteMaxLength = 1000;

/// Gia sư phải từ 18 tuổi (cùng quy định với web và backend — AgeHelper.MinTutorAge).
const int tutorMinAge = 18;

/// Bỏ dấu cách, dấu chấm, gạch ngang người dùng hay gõ khi nhập SĐT.
String normalizePhone(String? value) =>
    (value ?? '').replaceAll(RegExp(r'[\s.\-]'), '');

/// Gộp nhiều dấu cách liền nhau thành một và cắt hai đầu.
String collapseSpaces(String? value) =>
    (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

String? validatePhone(String? value, {String field = 'số điện thoại'}) {
  final p = normalizePhone(value);
  if (p.isEmpty) return 'Nhập $field';
  return vnPhoneRegExp.hasMatch(p) ? null : 'Số điện thoại không hợp lệ';
}

/// Họ tên người: 2–100 ký tự, chỉ gồm chữ cái; không số, không ký tự đặc biệt.
String? validatePersonName(String? value, {String field = 'họ tên'}) {
  final v = collapseSpaces(value);
  if (v.isEmpty) return 'Nhập $field';
  if (v.runes.length < 2) return '${_cap(field)} phải có ít nhất 2 ký tự';
  if (v.runes.length > nameMaxLength) {
    return '${_cap(field)} tối đa $nameMaxLength ký tự';
  }
  if (!_personNameRegExp.hasMatch(v)) {
    return '${_cap(field)} chỉ gồm chữ cái, không chứa số hay ký tự đặc biệt';
  }
  return null;
}

String? validateSubject(String? value) {
  final v = collapseSpaces(value);
  if (v.isEmpty) return 'Nhập môn học';
  if (v.runes.length < 2) return 'Môn học phải có ít nhất 2 ký tự';
  if (v.runes.length > subjectMaxLength) {
    return 'Môn học tối đa $subjectMaxLength ký tự';
  }
  if (!_subjectRegExp.hasMatch(v)) return 'Môn học chứa ký tự không hợp lệ';
  return null;
}

/// Ngày sinh dạng yyyy-MM-dd (cùng định dạng với web và backend): phải là
/// ngày có thật, không ở tương lai, không trước năm 1900. [minAge] (vd.
/// [tutorMinAge]) chặn người chưa đủ tuổi.
String? validateBirthdate(String? value, {DateTime? now, int? minAge}) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Chọn ngày sinh';
  final d = parseIsoDate(v);
  if (d == null) return 'Ngày sinh không hợp lệ (định dạng yyyy-MM-dd)';
  final today = now ?? DateTime.now();
  if (d.isAfter(DateTime(today.year, today.month, today.day))) {
    return 'Ngày sinh không được ở tương lai';
  }
  if (d.year < 1900) return 'Ngày sinh không hợp lệ';
  if (minAge != null && ageOn(d, today) < minAge) {
    return 'Phải từ $minAge tuổi trở lên';
  }
  return null;
}

/// Số tuổi tròn tính tới [today] (chưa tới sinh nhật năm nay thì chưa tính).
int ageOn(DateTime birth, DateTime today) {
  var age = today.year - birth.year;
  if (today.month < birth.month ||
      (today.month == birth.month && today.day < birth.day)) {
    age--;
  }
  return age;
}

/// Ngày sinh muộn nhất vẫn đủ [minAge] tuổi tính tới [today] — dùng làm
/// `lastDate` cho date picker.
DateTime latestBirthdateForAge(int minAge, DateTime today) {
  final d = DateTime(today.year - minAge, today.month, today.day);
  // 29/02 năm nhuận → năm thường DateTime tự nhảy sang 01/03; lùi về 28/02.
  return d.month == today.month ? d : DateTime(d.year, today.month + 1, 0);
}

/// Đọc chuỗi yyyy-MM-dd; trả null nếu sai định dạng hoặc ngày không có thật
/// (vd. 2024-02-30). Chuỗi ISO có giờ phía sau thì chỉ lấy phần ngày.
DateTime? parseIsoDate(String? value) {
  final v = (value ?? '').trim();
  final head = v.length >= 10 ? v.substring(0, 10) : v;
  if (!_isoDateRegExp.hasMatch(head)) return null;
  final parts = head.split('-').map(int.parse).toList();
  final d = DateTime(parts[0], parts[1], parts[2]);
  if (d.year != parts[0] || d.month != parts[1] || d.day != parts[2]) {
    return null;
  }
  return d;
}

String formatIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String? validateAddress(String? value) {
  final v = collapseSpaces(value);
  if (v.isEmpty) return 'Nhập địa chỉ';
  if (v.runes.length < 5) return 'Địa chỉ quá ngắn';
  if (v.runes.length > addressMaxLength) {
    return 'Địa chỉ tối đa $addressMaxLength ký tự';
  }
  return null;
}

/// Ô tự do không bắt buộc (ghi chú…): chỉ giới hạn độ dài.
String? validateOptionalMaxLength(String? value, int max) {
  final v = (value ?? '').trim();
  return v.runes.length > max ? 'Tối đa $max ký tự' : null;
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
