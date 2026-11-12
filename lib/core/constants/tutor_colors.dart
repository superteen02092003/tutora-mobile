import 'package:flutter/material.dart';

/// Bảng màu role gia sư — theo design canvas "TopTutor: tutor app and parent Mini App"
/// (2026-11): nền giấy #F6F4EE, mực xanh rêu #1B352D, nút chính đồng #D9A15B.
/// Trước đó là bản cream + oxblood.
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
///   • `primary` là xanh rêu đậm (nút tô đặc, chữ trắng); nút chính kiểu canvas
///     dùng `accent` đồng với chữ mực. `danger` là đỏ gạch riêng cho phá huỷ/lỗi.
abstract final class TutorColors {
  /// Nền màn hình — cream (AppColors.cream).
  static const Color bg = Color(0xFFF6F4EE);

  /// Mặt card — giấy trắng đặc (AppColors.paper).
  static const Color surface = Color(0xFFFFFFFF);

  /// Vùng lõm / nền phụ — cream đậm hơn một bậc (AppColors.cream2).
  static const Color surfaceSunken = Color(0xFFEDEAE0);

  static const Color ink = Color(0xFF1B352D); // mực xanh rêu — chữ chính
  static const Color ink2 = Color(
    0xFF24443A,
  ); // xanh rêu đậm — tiêu đề, khối nhấn tối
  static const Color ink3 = Color(0xFF566860);
  static const Color ink4 = Color(0xFF66766D);

  /// Viền — ấm, cùng họ với cream (AppColors.line).
  static const Color line = Color(0xFFCFCBBE);

  /// Xanh rêu đậm — màu nhấn chính (khối tối, nút tô đặc chữ trắng).
  /// Nền/viền lấy từ TutorStatusTone.attention.
  static const Color primary = Color(0xFF24443A);
  static const Color primaryBg = Color(0xFFE3EBE6);
  static const Color primaryBorder = Color(0xFFC9D6CE);

  /// Đồng — nút hành động chính trên canvas (chữ mực `ink`, không chữ trắng: thiếu tương phản).
  static const Color accent = Color(0xFFD9A15B);
  static const Color accentBg = Color(0xFFF6E8D3);
  static const Color accentBorder = Color(0xFFE9CFA4);

  /// Hoàn thành — TutorStatusTone.done.
  static const Color success = Color(0xFF1F6B43);
  static const Color successBg = Color(0xFFE6F0E9);
  static const Color successBorder = Color(0xFFC8DDCF);

  /// Chờ xử lý — TutorStatusTone.pending (chữ nâu vàng; không dùng gold làm màu
  /// chữ vì gold quá nhạt để đạt tương phản trên nền sáng).
  static const Color warning = Color(0xFF8A5A12);
  static const Color warningBg = Color(0xFFF6E8D3);
  static const Color warningBorder = Color(0xFFE9CFA4);

  /// Cảnh báo / phá huỷ — đỏ gạch, khác hẳn primary.
  static const Color danger = Color(0xFF9B2C2C);
  static const Color dangerBg = Color(0xFFF7E6E3);
  static const Color dangerBorder = Color(0xFFEBC9C4);

  /// Hero card tối — dùng đúng MỘT lần mỗi màn (quy ước `TutorSurface.cardInk`).
  static const Color heroInk = Color(0xFF24443A);
  static const Color heroInkBg = Color(0xFFEDEAE0);

  /// Hero card phụ — moss (AppColors.moss), nền từ ChipTone.moss.
  static const Color heroTeal = Color(0xFF3F6B57);
  static const Color heroTealBg = Color(0xFFE3EBE6);

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
    Color(0xFF24443A), // xanh rêu đậm
    Color(0xFF3F6B57), // xanh rêu
    Color(0xFF8A5A12), // nâu đồng
    Color(0xFF1B352D), // mực
    Color(0xFF1F6B43), // xanh lá
    Color(0xFF566860), // xám xanh
  ];
}
