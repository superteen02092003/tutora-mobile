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

  /// Tiêu đề màn hình (một dòng, đầu mỗi tab).
  static TextStyle screenTitle({Color color = TutorColors.ink}) =>
      _base(size: 26, weight: FontWeight.w700, color: color, spacing: -0.5);

  /// Số liệu lớn — số dư, tổng tiền.
  static TextStyle numeralLarge({Color color = TutorColors.ink}) => _base(
    size: 30,
    weight: FontWeight.w700,
    color: color,
    spacing: -0.8,
    height: 1.1,
  );

  /// Số liệu trong thẻ nhỏ.
  static TextStyle numeral({Color color = TutorColors.ink}) => _base(
    size: 19,
    weight: FontWeight.w700,
    color: color,
    spacing: -0.3,
    height: 1.15,
  );

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
  static const double gutter = 20;

  /// Khoảng cách giữa hai nhóm nội dung.
  static const double sectionGap = 28;

  /// Khoảng cách giữa các hàng trong cùng một nhóm.
  static const double rowGap = 10;

  static const double radius = 14;
  static const double radiusSmall = 10;

  /// Thẻ trắng trên nền kem — bề mặt mặc định.
  static BoxDecoration card({Color? color, Color? border}) => BoxDecoration(
    color: color ?? TutorColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border ?? TutorColors.line),
  );

  /// Thẻ nhấn mạnh (nền mực) — dùng đúng một lần mỗi màn.
  static BoxDecoration cardInk() => BoxDecoration(
    color: TutorColors.ink,
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
