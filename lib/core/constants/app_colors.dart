import 'package:flutter/material.dart';

/// Bảng màu chung của app (theme Material, toast, hộp thoại, màn đăng nhập) —
/// design V5.6 (2026-11-12): giấy + xanh rêu đậm, không còn navy / đỏ đô /
/// vàng đồng. Giữ nguyên tên hằng số; giá trị khớp `TutorColors`.
abstract final class AppColors {
  // Backgrounds
  static const Color cream = Color(0xFFEFEEE9); // nền giấy
  static const Color cream2 = Color(0xFFECEBE6); // vùng lõm
  static const Color paper = Color(0xFFF5F4F0); // mặt thẻ / ô nhập

  // Text / brand
  static const Color ink = Color(0xFF1F2A24); // xanh rêu đậm — chữ chính, nút
  static const Color ink2 = Color(0xFF1F2A24);
  static const Color ink3 = Color(0xFF62686A);
  static const Color ink4 = Color(0xFF6B716C);

  // Dividers (mực 10% / 8%)
  static const Color line = Color(0x1A1F2A24);
  static const Color line2 = Color(0x141F2A24);

  // Accents — V5.6 chỉ có hai màu; tên cũ giữ cho code cũ.
  static const Color oxblood = Color(0xFF2E4A3A); // trước: đỏ đô
  static const Color gold = Color(0xFFD5DBD1); // trước: vàng đồng
  static const Color moss = Color(0xFF2E4A3A);
  static const Color green = Color(0xFF2E4A3A);
  static const Color sage = Color(0xFFE6EAE2);

  // Semantic
  static const Color error = Color(0xFF9B2C2C);
  static const Color success = Color(0xFF2E4A3A);
  static const Color warning = Color(0xFF7A5B1E);
}
