import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_math_text.dart';

void main() {
  group('topiMathText', () {
    // Các mẫu lấy từ kết quả Topi thật (bộ 8 buổi lớp 8).
    final cases = {
      '(x - 4)**2': '(x - 4)²',
      'x**2 - 8*x + 16': 'x² - 8x + 16',
      '(3*x - 2)*(3*x + 2)': '(3x - 2)(3x + 2)',
      'x*(y - 2) - 3*(2 - y)': 'x(y - 2) - 3(2 - y)',
      '(x + 3)*(y - 2)': '(x + 3)(y - 2)',
      '120 - 5 * (2**3 + 4)': '120 - 5(2³ + 4)',
      '48 / (16 - 2**2 * 2) + 3**2 * 5': '48 / (16 - 2² · 2) + 3² · 5',
      '(6*x**2*y + 9*x*y**2) / (3*x*y)': '(6x²y + 9xy²) / (3xy)',
      'a**3 + 3*a**2*b + 3*a*b**2 + b**3': 'a³ + 3a²b + 3ab² + b³',
      '(x**2 - 4)/(x**2 + 4*x + 4)': '(x² - 4)/(x² + 4x + 4)',
      '40*x = 30*(x + 1)': '40x = 30(x + 1)',
      '(x - 3)^2': '(x - 3)²',
      'x**12': 'x¹²',
      'x = -10': 'x = -10',
      '60': '60',
    };
    for (final MapEntry(key: input, value: expected) in cases.entries) {
      test(input, () => expect(topiMathText(input), expected));
    }
  });

  group('topiAskText', () {
    test('bỏ "Hỏi:" trùng và viết biểu thức như trong vở', () {
      expect(
        topiAskText('Hỏi: Em hãy khai triển biểu thức (x - 4)^2.'),
        'Em hãy khai triển biểu thức (x - 4)².',
      );
    });

    test('giữ nguyên câu không có "Hỏi:"', () {
      expect(
        topiAskText('Chữa những bài về nhà học sinh làm sai.'),
        'Chữa những bài về nhà học sinh làm sai.',
      );
    });

    test('đơn vị km/h không bị đổi', () {
      expect(
        topiAskText('Hỏi: xe máy đi 30 km/h, ô tô 40 km/h.'),
        'xe máy đi 30 km/h, ô tô 40 km/h.',
      );
    });
  });
}
