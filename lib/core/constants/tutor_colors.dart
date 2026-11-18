import 'package:flutter/material.dart';

/// Bảng màu role gia sư — design V5.6 (canvas "TopTutor tutor app V5.6",
/// 2026-11-12): hai màu, giấy + xanh rêu đậm `#1F2A24`, thẻ xanh xám (sage)
/// `#E6EAE2` cho "việc tiếp theo / cần bạn". Không còn màu đồng.
///
/// Giữ NGUYÊN toàn bộ tên hằng số của bản trước để widget cũ vẫn chạy; chỉ giá
/// trị đổi. Màn nào chưa vẽ lại vẫn tự sang tông V5.6.
///
/// Nguyên tắc V5.6:
///   • Ba mức bề mặt: 0 phẳng trên nền giấy; 1 thẻ (`surface` + `cardShadow`);
///     2 khối nổi (`raisedCardShadow`: banner, thanh tab, thẻ "tiếp theo").
///   • `accent` (trước là đồng) nay là sage: nút phụ / thẻ "tiếp theo", chữ mực.
///   • Màu trạng thái (success/warning/danger) chỉ dùng khi cần cảnh báo thật.
abstract final class TutorColors {
  /// Nền màn hình — giữa dải giấy #F2F0EA → #EDEDE8 của canvas.
  static const Color bg = Color(0xFFEFEEE9);

  /// Hai đầu dải nền giấy (dùng khi màn tự vẽ gradient).
  static const Color paperTop = Color(0xFFF2F0EA);
  static const Color paperBottom = Color(0xFFEDEDE8);

  /// Mặt thẻ (mức 1).
  static const Color surface = Color(0xFFF5F4F0);

  /// Vùng lõm / nền icon / chip trung tính.
  static const Color surfaceSunken = Color(0xFFECEBE6);

  /// Sage — thẻ "tiếp theo / cần bạn".
  static const Color sage = Color(0xFFE6EAE2);

  static const Color ink = Color(0xFF1F2A24); // mực xanh rêu — chữ chính
  static const Color ink2 = Color(0xFF1F2A24); // tiêu đề, khối tối
  static const Color ink3 = Color(0xFF62686A); // chữ phụ
  static const Color ink4 = Color(0xFF6B716C); // chú thích (≥ 4.5:1 trên bg)

  /// Chữ viết tay (Charm) — xám ấm.
  static const Color hand = Color(0xFF7A807A);

  /// Đường kẻ mảnh — mực 10%.
  static const Color line = Color(0x1A1F2A24);

  /// Xanh rêu đậm — nút chính (chữ trắng), khối tối.
  static const Color primary = Color(0xFF1F2A24);
  static const Color primaryBg = Color(0xFFE6EAE2);
  static const Color primaryBorder = Color(0xFFD5DBD1);

  /// Trước là đồng; V5.6 bỏ đồng → sage (nút phụ, chữ mực).
  static const Color accent = Color(0xFFE6EAE2);
  static const Color accentBg = Color(0xFFEEF1EB);
  static const Color accentBorder = Color(0xFFD5DBD1);

  /// Hoàn thành — xanh rêu, nền sage.
  static const Color success = Color(0xFF2E4A3A);
  static const Color successBg = Color(0xFFE6EAE2);
  static const Color successBorder = Color(0xFFD5DBD1);

  /// Chờ xử lý — nâu trầm (chữ), nền giấy ấm.
  static const Color warning = Color(0xFF7A5B1E);
  static const Color warningBg = Color(0xFFF1ECE0);
  static const Color warningBorder = Color(0xFFE3D9C3);

  /// Phá huỷ / lỗi — đỏ gạch.
  static const Color danger = Color(0xFF9B2C2C);
  static const Color dangerBg = Color(0xFFF7E6E3);
  static const Color dangerBorder = Color(0xFFEBC9C4);

  /// Khối tối — một lần mỗi màn.
  static const Color heroInk = Color(0xFF1F2A24);
  static const Color heroInkBg = Color(0xFFECEBE6);

  /// Khối phụ — xanh rêu vừa.
  static const Color heroTeal = Color(0xFF2E4A3A);
  static const Color heroTealBg = Color(0xFFE6EAE2);

  /// Bóng thẻ mức 1 (canvas `.card`).
  static List<BoxShadow> get cardShadow => const [
    BoxShadow(color: Color(0x081F2A24), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0B1F2A24), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Bóng khối nổi mức 2 (canvas `.lift`, thanh tab, banner).
  static List<BoxShadow> get raisedCardShadow => const [
    BoxShadow(color: Color(0x0A1F2A24), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1C1F2A24), blurRadius: 36, offset: Offset(0, 16)),
  ];

  /// Bóng nút tròn ghi âm.
  static List<BoxShadow> heroShadow(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  /// Avatar — sắc độ xanh rêu, không dải màu rực.
  static const List<Color> avatarPalette = [
    Color(0xFF1F2A24),
    Color(0xFF2E4A3A),
    Color(0xFF4A5E52),
    Color(0xFF62686A),
    Color(0xFF3C5446),
    Color(0xFF55675C),
  ];
}
