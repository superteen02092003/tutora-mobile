import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

/// Design language cho các màn gia sư trên mobile.
///
/// Khác với `AppTextStyles` (ngôn ngữ editorial: serif nghiêng + Bricolage
/// display + mono, sinh ra từ web landing), lớp này chỉ dùng **một họ chữ**
/// và phân cấp bằng weight/size — cách các app native làm. Mục tiêu là màn
/// hình đọc lướt được trong 2 giây, không phải đọc như một trang báo.
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
  static TextStyle screenTitle({Color color = AppColors.ink}) =>
      _base(size: 26, weight: FontWeight.w700, color: color, spacing: -0.5);

  /// Số liệu lớn — số dư, tổng tiền.
  static TextStyle numeralLarge({Color color = AppColors.ink}) => _base(
    size: 30,
    weight: FontWeight.w700,
    color: color,
    spacing: -0.8,
    height: 1.1,
  );

  /// Số liệu trong thẻ nhỏ.
  static TextStyle numeral({Color color = AppColors.ink}) => _base(
    size: 19,
    weight: FontWeight.w700,
    color: color,
    spacing: -0.3,
    height: 1.15,
  );

  /// Tiêu đề nhóm nội dung ("Hôm nay", "Cần xử lý").
  static TextStyle sectionTitle({Color color = AppColors.ink}) =>
      _base(size: 15, weight: FontWeight.w700, color: color, spacing: -0.1);

  /// Dòng chính trong một hàng danh sách — tên học sinh, tên giao dịch.
  static TextStyle rowTitle({Color color = AppColors.ink}) =>
      _base(size: 15, weight: FontWeight.w600, color: color, spacing: -0.1);

  /// Dòng phụ dưới [rowTitle].
  static TextStyle rowSub({Color color = AppColors.ink3}) =>
      _base(size: 13, weight: FontWeight.w400, color: color, height: 1.35);

  /// Nhãn nhỏ: caption thẻ số liệu, chú thích.
  static TextStyle caption({Color color = AppColors.ink4}) =>
      _base(size: 12, weight: FontWeight.w500, color: color, height: 1.3);

  /// Chữ trên nút và chip.
  static TextStyle action({Color color = AppColors.ink}) =>
      _base(size: 13.5, weight: FontWeight.w600, color: color);

  /// Nhãn tab dưới cùng.
  static TextStyle navLabel({
    Color color = AppColors.ink4,
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
    color: color ?? AppColors.paper,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border ?? AppColors.line),
  );

  /// Thẻ nhấn mạnh (nền mực) — dùng đúng một lần mỗi màn.
  static BoxDecoration cardInk() => BoxDecoration(
    color: AppColors.ink,
    borderRadius: BorderRadius.circular(radius),
  );

  /// Nền chìm cho ô chứa bên trong thẻ (segment, ô nhập).
  static BoxDecoration well() => BoxDecoration(
    color: AppColors.cream2,
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
  static const Color attention = AppColors.oxblood;
  static const Color attentionBg = Color(0xFFF7ECEC);
  static const Color attentionBorder = Color(0xFFEBD9D9);

  /// Đang chờ hệ thống — tiền giữ tạm, chờ duyệt.
  static const Color pending = Color(0xFF8A6D3B);
  static const Color pendingBg = Color(0xFFF7F0E1);
  static const Color pendingBorder = Color(0xFFEADFC6);

  /// Đã xong — đã trả, đã hoàn thành.
  static const Color done = AppColors.green;
  static const Color doneBg = Color(0xFFEDF3EE);
  static const Color doneBorder = Color(0xFFD9E6DC);

  /// Trung tính — sắp diễn ra, chưa có gì gấp.
  static const Color neutral = AppColors.ink3;
  static const Color neutralBg = AppColors.cream2;
  static const Color neutralBorder = AppColors.line;
}
