/// Format giá tiền VNĐ có cộng phí dịch vụ 5%.
String formatPrice(double? price) {
  if (price == null || price == 0) return 'Thương lượng';
  final n = (price * 1.05).round();
  final s = n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
  return '$sđ';
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
