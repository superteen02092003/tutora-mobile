import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/tutor_colors.dart';

/// Kiểu chữ màn gia sư — design V5.6 (2026-11-12): font thương hiệu
/// Bricolage Grotesque (tiêu đề, Bold), Inter (chữ), Charm (chữ viết tay, chỉ
/// ở khoảng trống, một hai dòng mỗi màn).
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

  /// Tiêu đề Bricolage Grotesque (font thương hiệu, Bold).
  static TextStyle display({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = TutorColors.ink2,
    double height = 1.1,
  }) => GoogleFonts.bricolageGrotesque(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: -0.022 * size,
  );

  /// Tên lớn đầu Trang chủ ("Hà").
  static TextStyle name({Color color = TutorColors.ink}) =>
      display(size: 38, color: color, height: 1.05);

  /// Nhãn nhỏ đầu khối ("Cần bạn duyệt", "Lỗ hổng 1 · luyện ngay").
  /// V5.6 không viết hoa giãn chữ nữa; chỗ cũ còn gọi `toUpperCase()` vẫn chạy.
  static TextStyle kicker({Color color = TutorColors.ink3}) =>
      _base(size: 12.5, weight: FontWeight.w500, color: color, height: 1.3);

  /// Tiêu đề màn hình (đầu mỗi tab).
  static TextStyle screenTitle({Color color = TutorColors.ink2}) =>
      display(size: 26, color: color);

  /// Số liệu lớn.
  static TextStyle numeralLarge({Color color = TutorColors.ink}) =>
      display(size: 34, weight: FontWeight.w600, color: color, height: 1);

  /// Số liệu trong thẻ nhỏ.
  static TextStyle numeral({Color color = TutorColors.ink}) =>
      display(size: 20, weight: FontWeight.w600, color: color, height: 1.15);

  /// Tiêu đề nhóm nội dung ("Học sinh của bạn", "Việc hôm nay").
  static TextStyle sectionTitle({Color color = TutorColors.ink}) =>
      display(size: 19, color: color, height: 1.2);

  /// Chữ thân (15/500).
  static TextStyle body({Color color = TutorColors.ink}) =>
      _base(size: 15, weight: FontWeight.w500, color: color, height: 1.4);

  /// Dòng chính trong một hàng danh sách.
  static TextStyle rowTitle({Color color = TutorColors.ink}) =>
      _base(size: 15, weight: FontWeight.w500, color: color, height: 1.35);

  /// Dòng phụ dưới [rowTitle].
  static TextStyle rowSub({Color color = TutorColors.ink3}) =>
      _base(size: 13, weight: FontWeight.w500, color: color, height: 1.45);

  /// Nhãn nhỏ, chú thích.
  static TextStyle caption({Color color = TutorColors.ink4}) =>
      _base(size: 12, weight: FontWeight.w500, color: color, height: 1.3);

  /// Chữ trên nút và chip.
  static TextStyle action({Color color = TutorColors.ink}) =>
      _base(size: 14, weight: FontWeight.w500, color: color);

  /// Nhãn tab dưới cùng.
  static TextStyle navLabel({
    Color color = TutorColors.ink4,
    bool selected = false,
  }) => _base(
    size: 10.5,
    weight: FontWeight.w500,
    color: selected ? TutorColors.ink : color,
  );

  /// Chữ viết tay (Charm) — chỉ ở khoảng trống, ngắn, tiếng Việt.
  static TextStyle hand({double size = 19, Color color = TutorColors.hand}) =>
      GoogleFonts.charm(fontSize: size, color: color, height: 1.1);
}

/// Bề mặt và khoảng cách dùng chung — design V5.6.
abstract final class TutorSurface {
  /// Padding ngang thống nhất cho mọi màn.
  static const double gutter = 22;

  /// Khoảng cách giữa hai nhóm nội dung.
  static const double sectionGap = 28;

  /// Khoảng cách giữa các hàng trong cùng một nhóm.
  static const double rowGap = 10;

  /// Góc thẻ (mức 1, 2).
  static const double radius = 20;

  /// Góc ô nhỏ (icon, ô lõm, segment).
  static const double radiusSmall = 12;

  /// Đường kẻ mảnh.
  static const double ruleWidth = 1;

  /// Thẻ mức 1: nền `surface`, bóng nhẹ, không viền (viền chỉ khi truyền vào).
  static BoxDecoration card({Color? color, Color? border}) => BoxDecoration(
    color: color ?? TutorColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: border == null ? null : Border.all(color: border),
    boxShadow: TutorColors.cardShadow,
  );

  /// Khối nổi mức 2 (thẻ "tiếp theo", banner).
  static BoxDecoration lift({Color? color}) => BoxDecoration(
    color: color ?? TutorColors.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: TutorColors.raisedCardShadow,
  );

  /// Thẻ sage "việc tiếp theo / cần bạn".
  static BoxDecoration sage({bool lifted = true}) => BoxDecoration(
    color: TutorColors.sage,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: lifted ? TutorColors.raisedCardShadow : null,
  );

  /// Đường kẻ ngang phân hàng (mực 10%, 1 px).
  static BorderSide get rule => const BorderSide(color: TutorColors.line);

  /// Khối tối — dùng một lần mỗi màn.
  static BoxDecoration cardInk() => BoxDecoration(
    color: TutorColors.ink2,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: TutorColors.raisedCardShadow,
  );

  /// Ô lõm bên trong thẻ (segment, ô nhập, nền icon).
  static BoxDecoration well() => BoxDecoration(
    color: TutorColors.surfaceSunken,
    borderRadius: BorderRadius.circular(radiusSmall),
  );

  /// Nền giấy dọc (gradient của canvas).
  static const BoxDecoration paper = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [TutorColors.paperTop, TutorColors.paperBottom],
    ),
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
