import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/core/utils/input_validators.dart';

void main() {
  group('Họ tên (gia sư, học sinh, phụ huynh)', () {
    for (final ok in [
      'Nguyễn Văn A',
      'Chị Hương',
      'Lê Thị Ngọc-Anh',
      "O'Neil",
      'Trần  Thị   B', // nhiều dấu cách được gộp lại
      'Ân',
    ]) {
      test('hợp lệ: "$ok"', () => expect(validatePersonName(ok), isNull));
    }

    test('bỏ trống', () {
      expect(validatePersonName('  '), 'Nhập họ tên');
      expect(
        validatePersonName('', field: 'tên phụ huynh'),
        'Nhập tên phụ huynh',
      );
    });

    test('1 ký tự', () {
      expect(validatePersonName('A'), 'Họ tên phải có ít nhất 2 ký tự');
    });

    test('quá 100 ký tự', () {
      expect(validatePersonName('A' * 101), 'Họ tên tối đa 100 ký tự');
    });

    for (final bad in [
      'Nguyễn Văn 2',
      'An123',
      'An@',
      'Bình!',
      '<script>',
      '---',
      'An_Bình',
      '😀 An',
    ]) {
      test('không hợp lệ: "$bad"', () {
        expect(
          validatePersonName(bad),
          'Họ tên chỉ gồm chữ cái, không chứa số hay ký tự đặc biệt',
        );
      });
    }
  });

  group('Số điện thoại', () {
    for (final ok in [
      '0901234567',
      '+84901234567',
      '84901234567',
      '090 123 4567',
      '090.123.4567',
      '090-123-4567',
    ]) {
      test('hợp lệ: "$ok"', () => expect(validatePhone(ok), isNull));
    }

    for (final bad in ['12345', '090123', '1901234567', '09012345678901']) {
      test('không hợp lệ: "$bad"', () {
        expect(validatePhone(bad), 'Số điện thoại không hợp lệ');
      });
    }

    test('bỏ trống', () => expect(validatePhone(' '), 'Nhập số điện thoại'));

    test('chuẩn hoá bỏ dấu cách, chấm, gạch', () {
      expect(normalizePhone(' 090.123-45 67 '), '0901234567');
    });
  });

  group('Môn học', () {
    for (final ok in ['Toán', 'Toán 7', 'Lý/Hoá', 'Tiếng Anh (IELTS)']) {
      test('hợp lệ: "$ok"', () => expect(validateSubject(ok), isNull));
    }

    test('bỏ trống', () => expect(validateSubject(''), 'Nhập môn học'));
    test('1 ký tự', () {
      expect(validateSubject('T'), 'Môn học phải có ít nhất 2 ký tự');
    });
    for (final bad in ['@Toán', 'Toán#', 'Toán<b>']) {
      test('không hợp lệ: "$bad"', () {
        expect(validateSubject(bad), 'Môn học chứa ký tự không hợp lệ');
      });
    }
  });

  group('Ngày sinh', () {
    final now = DateTime(2026, 9, 24);

    test('hợp lệ', () {
      expect(validateBirthdate('1995-05-20', now: now), isNull);
      expect(validateBirthdate('2026-09-24', now: now), isNull);
    });

    test('bỏ trống', () {
      expect(validateBirthdate('', now: now), 'Chọn ngày sinh');
    });

    for (final bad in ['abc', '20/05/1995', '1995-5-20', '1995-02-30']) {
      test('sai định dạng / ngày không có thật: "$bad"', () {
        expect(
          validateBirthdate(bad, now: now),
          'Ngày sinh không hợp lệ (định dạng yyyy-MM-dd)',
        );
      });
    }

    test('ngày ở tương lai', () {
      expect(
        validateBirthdate('2026-09-25', now: now),
        'Ngày sinh không được ở tương lai',
      );
    });

    test('trước năm 1900', () {
      expect(
        validateBirthdate('1899-12-31', now: now),
        'Ngày sinh không hợp lệ',
      );
    });

    test('gia sư: đúng sinh nhật 18 tuổi thì hợp lệ', () {
      expect(
        validateBirthdate('2008-09-24', now: now, minAge: tutorMinAge),
        isNull,
      );
    });

    test('gia sư: thiếu 1 ngày nữa mới đủ 18 bị chặn', () {
      expect(
        validateBirthdate('2008-09-25', now: now, minAge: tutorMinAge),
        'Phải từ 18 tuổi trở lên',
      );
    });

    test('lịch chọn ngày sinh chỉ cho tới ngày vừa đủ 18', () {
      expect(latestBirthdateForAge(18, now), DateTime(2008, 9, 24));
      // 29/02 năm nhuận → 28/02 của năm (không nhuận) 18 năm trước.
      expect(
        latestBirthdateForAge(18, DateTime(2028, 2, 29)),
        DateTime(2010, 2, 28),
      );
    });

    test('đọc được ISO datetime từ backend', () {
      expect(parseIsoDate('1995-05-20T00:00:00'), DateTime(1995, 5, 20));
      expect(formatIsoDate(DateTime(1995, 5, 2)), '1995-05-02');
    });
  });

  group('Địa chỉ', () {
    test('hợp lệ', () {
      expect(validateAddress('12 Lê Lợi, Q.1, TP.HCM'), isNull);
    });
    test('bỏ trống', () => expect(validateAddress(' '), 'Nhập địa chỉ'));
    test('quá ngắn', () => expect(validateAddress('Q1'), 'Địa chỉ quá ngắn'));
    test('quá 255 ký tự', () {
      expect(validateAddress('a' * 256), 'Địa chỉ tối đa 255 ký tự');
    });
  });

  group('Ghi chú (không bắt buộc)', () {
    test('bỏ trống hợp lệ', () {
      expect(validateOptionalMaxLength('', noteMaxLength), isNull);
    });
    test('quá 1000 ký tự', () {
      expect(
        validateOptionalMaxLength('a' * 1001, noteMaxLength),
        'Tối đa 1000 ký tự',
      );
    });
  });
}
