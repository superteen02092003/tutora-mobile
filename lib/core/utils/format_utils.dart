/// Tiền VND: nhóm 3 chữ số, ngăn bằng dấu phẩy.
String fmtVnd(int n) {
  final negative = n < 0;
  final digits = n.abs().toString();
  final buf = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }

  return negative ? '-$buf' : buf.toString();
}

/// Format giá tiền VNĐ có cộng phí dịch vụ 5%.
String formatPrice(double? price) {
  if (price == null || price == 0) return 'Thương lượng';
  final n = (price * 1.05).round();
  return '${fmtVnd(n)}đ';
}

List<String> formatGradeLevels(List<String> raw) {
  int gradeOrder(String g) {
    final n = int.tryParse(g.replaceAll(RegExp('[^0-9]'), ''));
    return n ?? 99;
  }

  final sorted = List.of(raw)
    ..sort((a, b) => gradeOrder(a).compareTo(gradeOrder(b)));
  return sorted.map((g) {
    final n = int.tryParse(g.replaceAll(RegExp('[^0-9]'), ''));
    return n != null ? 'Lớp $n' : g;
  }).toList();
}
