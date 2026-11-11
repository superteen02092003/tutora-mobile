import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/tutor_colors.dart';

/// Design language cho các màn gia sư trên mobile.
abstract final class TutorType {
  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? spacing,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );

  /// Font tiêu đề/số của canvas: Bricolage Grotesque (có tiếng Việt), chữ khít.
  static TextStyle display({
    double size = 46,
    FontWeight weight = FontWeight.w800,
    Color color = TutorColors.ink2,
    double height = 1.0,
  }) => GoogleFonts.bricolageGrotesque(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: -0.045 * size,
  );

  /// Nhãn nhỏ viết hoa giãn chữ của canvas ("BUỔI TỚI", "CẦN DUYỆT"). Tự viết hoa
  /// chuỗi khi dùng: `Text(s.toUpperCase(), style: TutorType.kicker())`.
  static TextStyle kicker({Color color = TutorColors.ink3}) => _base(
    size: 12,
    weight: FontWeight.w700,
    color: color,
    spacing: 1.7,
    height: 1.3,
  );

  /// Tiêu đề màn hình (đầu mỗi tab) — Bricolage đậm, xanh rêu đậm như canvas.
  static TextStyle screenTitle({Color color = TutorColors.ink2}) =>
      display(size: 34, color: color, height: 1.05);

  /// Số liệu lớn — Bricolage mảnh như hàng số liệu trên canvas.
  static TextStyle numeralLarge({Color color = TutorColors.ink}) =>
      display(size: 36, weight: FontWeight.w300, color: color)
          .copyWith(letterSpacing: -1.4);

  /// Số liệu trong thẻ nhỏ.
  static TextStyle numeral({Color color = TutorColors.ink}) =>
      display(size: 22, weight: FontWeight.w700, color: color, height: 1.15)
          .copyWith(letterSpacing: -0.5);

  /// Tiêu đề nhóm nội dung ("Hôm nay", "Cần xử lý").
  static TextStyle sectionTitle({Color color = TutorColors.ink}) =>
      _base(size: 15, weight: FontWeight.w700, color: color, spacing: -0.1);

  /// Dòng chính trong một hàng danh sách — tên học sinh, tên giao dịch.
  static TextStyle rowTitle({Color color = TutorColors.ink}) =>
      _base(size: 15, weight: FontWeight.w600, color: color, spacing: -0.1);

  /// Dòng phụ dưới [rowTitle].
  static TextStyle rowSub({Color color = TutorColors.ink3}) =>
      _base(size: 13, weight: FontWeight.w400, color: color, height: 1.35);

  /// Nhãn nhỏ: caption thẻ số liệu, chú thích.
  static TextStyle caption({Color color = TutorColors.ink4}) =>
      _base(size: 12, weight: FontWeight.w500, color: color, height: 1.3);

  /// Chữ trên nút và chip.
  static TextStyle action({Color color = TutorColors.ink}) =>
      _base(size: 13.5, weight: FontWeight.w600, color: color);

  /// Nhãn tab dưới cùng.
  static TextStyle navLabel({
    Color color = TutorColors.ink4,
    bool selected = false,
  }) => _base(
    size: 11,
    weight: selected ? FontWeight.w600 : FontWeight.w500,
    color: color,
  );
}

/// Bề mặt và khoảng cách dùng chung cho màn gia sư.
///
/// Phân tách khối bằng nền + viền mảnh, không đổ bóng.
abstract final class TutorSurface {
  /// Padding ngang thống nhất cho mọi màn — mọi thứ thẳng một mép trái.
  static const double gutter = 24;

  /// Khoảng cách giữa hai nhóm nội dung.
  static const double sectionGap = 28;

  /// Khoảng cách giữa các hàng trong cùng một nhóm.
  static const double rowGap = 10;

  // Canvas: góc gần vuông (6 px), viền mực 1,5 px thay cho thẻ trắng bo tròn.
  static const double radius = 6;
  static const double radiusSmall = 6;
  static const double ruleWidth = 1.5;

  /// Thẻ mặc định của canvas: cùng nền giấy, viền mực 1,5 px, góc 6 px.
  static BoxDecoration card({Color? color, Color? border}) => BoxDecoration(
    color: color ?? TutorColors.bg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border ?? TutorColors.ink, width: ruleWidth),
  );

  /// Đường kẻ ngang phân hàng của canvas (mực 1,5 px).
  static BorderSide get rule =>
      const BorderSide(color: TutorColors.ink, width: ruleWidth);

  /// Thẻ nhấn mạnh (nền mực) — dùng đúng một lần mỗi màn.
  static BoxDecoration cardInk() => BoxDecoration(
    color: TutorColors.ink2,
    borderRadius: BorderRadius.circular(radius),
  );

  /// Nền chìm cho ô chứa bên trong thẻ (segment, ô nhập).
  static BoxDecoration well() => BoxDecoration(
    color: TutorColors.surfaceSunken,
    borderRadius: BorderRadius.circular(radiusSmall),
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: gutter,
  );
}

/// Màu ngữ nghĩa cho trạng thái tiền / buổi học của gia sư.
abstract final class TutorStatusTone {
  /// Cần gia sư làm gì đó — quá hạn, chờ phản hồi.
  static const Color attention = TutorColors.danger;
  static const Color attentionBg = TutorColors.dangerBg;
  static const Color attentionBorder = TutorColors.dangerBorder;

  /// Đang chờ hệ thống — tiền giữ tạm, chờ duyệt.
  static const Color pending = TutorColors.warning;
  static const Color pendingBg = TutorColors.warningBg;
  static const Color pendingBorder = TutorColors.warningBorder;

  /// Đã xong — đã trả, đã hoàn thành.
  static const Color done = TutorColors.success;
  static const Color doneBg = TutorColors.successBg;
  static const Color doneBorder = TutorColors.successBorder;

  /// Trung tính — sắp diễn ra, chưa có gì gấp.
  static const Color neutral = TutorColors.ink3;
  static const Color neutralBg = TutorColors.surfaceSunken;
  static const Color neutralBorder = TutorColors.line;
}
