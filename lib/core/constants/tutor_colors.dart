import 'package:flutter/material.dart';

/// Bảng màu role gia sư — ngôn ngữ editorial (cream + oxblood), khớp với
/// UI prototype đã chốt.
///
/// Giữ NGUYÊN toàn bộ tên hằng số của bản trước để không widget nào phải sửa:
/// chỉ giá trị màu thay đổi. Nguồn giá trị là hệ token có sẵn trong repo —
/// `AppColors`, `TutorStatusTone` và `ChipTone` — nên bảng này không phải màu
/// mới phát minh, mà là đưa role gia sư về đúng hệ màu chung của sản phẩm.
///
/// Khác biệt về nguyên tắc so với bản SaaS xanh dương trước đó:
///   • Phân cấp bằng sắc độ và weight, KHÔNG bằng đổ bóng. Card mặc định phẳng
///     (`cardShadow` rỗng) — xem `TutorSurface` trong tutor_design.dart:
///     "Cố ý phẳng: nền giấy đặc, một viền trên mảnh, không blur, không đổ bóng".
///   • Chỉ có MỘT sắc đỏ. `primary` và `danger` cùng là oxblood: nút chính là
///     oxblood tô đặc, hành động phá huỷ là oxblood dạng chữ — phân biệt bằng
///     fill/weight chứ không bằng hue. Nếu về sau cần một sắc đỏ gắt hơn cho
///     lỗi hệ thống thì đã có sẵn `AppColors.error` (#B00020).
abstract final class TutorColors {
  /// Nền màn hình — cream (AppColors.cream).
  static const Color bg = Color(0xFFFAF9F6);

  /// Mặt card — giấy trắng đặc (AppColors.paper).
  static const Color surface = Color(0xFFFFFFFF);

  /// Vùng lõm / nền phụ — cream đậm hơn một bậc (AppColors.cream2).
  static const Color surfaceSunken = Color(0xFFF2F0E4);

  static const Color ink = Color(0xFF1A2238); // deep navy — chữ chính
  static const Color ink2 = Color(0xFF3E2F28); // warm bistre
  static const Color ink3 = Color(0xFF525252);
  static const Color ink4 = Color(0xFF737373);

  /// Viền — ấm, cùng họ với cream (AppColors.line).
  static const Color line = Color(0xFFE5E0D5);

  /// Oxblood — màu nhấn chính của sản phẩm.
  /// Nền/viền lấy từ TutorStatusTone.attention.
  static const Color primary = Color(0xFF631B1B);
  static const Color primaryBg = Color(0xFFF7ECEC);
  static const Color primaryBorder = Color(0xFFEBD9D9);

  /// Gold — màu nhấn phụ (AppColors.gold); nền/viền từ TutorStatusTone.pending.
  static const Color accent = Color(0xFFD4B483);
  static const Color accentBg = Color(0xFFF7F0E1);
  static const Color accentBorder = Color(0xFFEADFC6);

  /// Hoàn thành — TutorStatusTone.done.
  static const Color success = Color(0xFF2F6B3D);
  static const Color successBg = Color(0xFFEDF3EE);
  static const Color successBorder = Color(0xFFD9E6DC);

  /// Chờ xử lý — TutorStatusTone.pending (chữ nâu vàng; không dùng gold làm màu
  /// chữ vì gold quá nhạt để đạt tương phản trên nền sáng).
  static const Color warning = Color(0xFF8A6D3B);
  static const Color warningBg = Color(0xFFF7F0E1);
  static const Color warningBorder = Color(0xFFEADFC6);

  /// Cảnh báo / phá huỷ — cùng oxblood với primary, có chủ đích (xem doc ở trên).
  static const Color danger = Color(0xFF631B1B);
  static const Color dangerBg = Color(0xFFF7ECEC);
  static const Color dangerBorder = Color(0xFFEBD9D9);

  /// Hero card tối — dùng đúng MỘT lần mỗi màn (quy ước `TutorSurface.cardInk`).
  static const Color heroInk = Color(0xFF1A2238);
  static const Color heroInkBg = Color(0xFFF2F0E4);

  /// Hero card phụ — moss (AppColors.moss), nền từ ChipTone.moss.
  static const Color heroTeal = Color(0xFF3D4A3E);
  static const Color heroTealBg = Color(0xFFE0E7DF);

  /// Card mặc định KHÔNG đổ bóng — phân tách bằng viền `line`.
  /// Giữ getter để không widget nào phải sửa; trả về danh sách rỗng.
  static List<BoxShadow> get cardShadow => const [];

  /// Chỉ dành cho phần tử thật sự nổi trên nền: thanh nav pill và nút mic.
  /// Giá trị khớp `FloatingPillNavBar` (đen 8%, blur 20, spread −4, offset 0,6).
  static List<BoxShadow> get raisedCardShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.08),
      blurRadius: 20,
      spreadRadius: -4,
      offset: const Offset(0, 6),
    ),
  ];

  /// Quầng màu quanh nút nổi (nút mic ở giữa nav).
  static List<BoxShadow> heroShadow(Color tint) => [
    BoxShadow(color: tint.withValues(alpha: 0.10), spreadRadius: 6),
    BoxShadow(
      color: tint.withValues(alpha: 0.38),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  /// Avatar — sắc độ trong cùng hệ màu, không dùng dải màu rực.
  static const List<Color> avatarPalette = [
    Color(0xFF631B1B), // oxblood
    Color(0xFF3D4A3E), // moss
    Color(0xFF3E2F28), // bistre
    Color(0xFF1A2238), // ink
    Color(0xFF2F6B3D), // green
    Color(0xFF8A6D3B), // pending brown
  ];
}
