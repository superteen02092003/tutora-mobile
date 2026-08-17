import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/core/utils/format_utils.dart';

void main() {
  test('ngăn nhóm 3 chữ số bằng dấu phẩy', () {
    expect(fmtVnd(1140000), '1,140,000');
    expect(fmtVnd(500000), '500,000');
    expect(fmtVnd(47500), '47,500');
  });

  test('giữ nguyên phần lẻ dưới 1000 (bug cũ: 1.140.500 -> "1.140")', () {
    expect(fmtVnd(1140500), '1,140,500');
    expect(fmtVnd(1234), '1,234');
  });

  test('số nhỏ và 0 không có dấu ngăn', () {
    expect(fmtVnd(0), '0');
    expect(fmtVnd(999), '999');
  });

  test('số âm giữ dấu trừ — giao dịch hoàn escrow', () {
    expect(fmtVnd(-47500), '-47,500');
  });
}
