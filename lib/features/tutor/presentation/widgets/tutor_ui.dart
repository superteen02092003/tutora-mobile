import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';

/// Bộ widget nền cho màn gia sư — spacing, bo góc, cỡ chữ không lệch nhau.

/// Tiêu đề đầu màn — to và căn trái, khác AppBar 17px căn giữa của Material.
class TutorScreenHeader extends StatelessWidget {
  const TutorScreenHeader({
    required this.title,
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        8,
        TutorSurface.gutter,
        16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TutorType.screenTitle()),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: TutorType.rowSub()),
                ],
              ],
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: 8),
            action,
          ],
        ],
      ),
    );
  }
}

/// Header dùng cho màn con: quay lại bên trái, tiêu đề giữa, action tùy chọn.
class TutorChildHeader extends StatelessWidget {
  const TutorChildHeader({
    required this.title,
    this.onBack,
    this.action,
    this.backgroundColor = Colors.transparent,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? action;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      color: backgroundColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TutorType.rowTitle().copyWith(fontSize: 17),
              ),
            ),
          ),
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: TutorColors.ink,
            ),
          ),
          Positioned(
            right: 4,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: action),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút tròn viền mảnh ở header (chuông, cài đặt).
class TutorHeaderButton extends StatelessWidget {
  const TutorHeaderButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Chấm đỏ nhỏ ở góc — có việc chưa xem.
  final bool badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: TutorColors.surface,
          border: Border.fromBorderSide(BorderSide(color: TutorColors.line)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 19, color: TutorColors.ink),
            if (badge)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TutorStatusTone.attention,
                    border: Border.all(color: TutorColors.surface, width: 1.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: tooltip == null
          ? button
          : Tooltip(message: tooltip, child: button),
    );
  }
}

/// Tiêu đề một nhóm nội dung, kèm hành động phụ tuỳ chọn ở mép phải.
class TutorSectionHeader extends StatelessWidget {
  const TutorSectionHeader({
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
    this.padding,
    super.key,
  });

  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            0,
            TutorSurface.gutter,
            10,
          ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TutorType.sectionTitle())),
          if (trailingLabel != null)
            InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Text(
                        trailingLabel!,
                        style: TutorType.action(color: TutorColors.ink3),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: TutorColors.ink4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thẻ trắng bo góc, viền mảnh — bề mặt mặc định.
class TutorCard extends StatelessWidget {
  const TutorCard({
    required this.child,
    this.onTap,
    this.padding = TutorSurface.cardPadding,
    this.color,
    this.borderColor,
    this.shadow,
    this.backgroundImage,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final DecorationImage? backgroundImage;

  /// Bóng đổ tuỳ chọn — mặc định thẻ phẳng.
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: TutorSurface.card(
        color: color,
        border: borderColor,
      ).copyWith(boxShadow: shadow, image: backgroundImage),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TutorSurface.radius),
        child: content,
      ),
    );
  }
}

/// Chip trạng thái nhỏ: nền nhạt + chữ cùng tông, không đổ bóng.
class TutorStatusChip extends StatelessWidget {
  const TutorStatusChip({
    required this.label,
    required this.fg,
    required this.bg,
    this.border,
    this.icon,
    super.key,
  });

  /// Cần gia sư xử lý.
  factory TutorStatusChip.attention(String label, {IconData? icon}) =>
      TutorStatusChip(
        label: label,
        fg: TutorStatusTone.attention,
        bg: TutorStatusTone.attentionBg,
        border: TutorStatusTone.attentionBorder,
        icon: icon,
      );

  /// Đang chờ hệ thống xử lý.
  factory TutorStatusChip.pending(String label, {IconData? icon}) =>
      TutorStatusChip(
        label: label,
        fg: TutorStatusTone.pending,
        bg: TutorStatusTone.pendingBg,
        border: TutorStatusTone.pendingBorder,
        icon: icon,
      );

  /// Đã hoàn tất.
  factory TutorStatusChip.done(String label, {IconData? icon}) =>
      TutorStatusChip(
        label: label,
        fg: TutorStatusTone.done,
        bg: TutorStatusTone.doneBg,
        border: TutorStatusTone.doneBorder,
        icon: icon,
      );

  /// Không cần chú ý.
  factory TutorStatusChip.neutral(String label, {IconData? icon}) =>
      TutorStatusChip(
        label: label,
        fg: TutorStatusTone.neutral,
        bg: TutorStatusTone.neutralBg,
        border: TutorStatusTone.neutralBorder,
        icon: icon,
      );

  final String label;
  final Color fg;
  final Color bg;
  final Color? border;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TutorType.caption(color: fg).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút chính (nền mực) và nút phụ (viền) dùng trong nội dung màn.
class TutorButton extends StatelessWidget {
  const TutorButton({
    required this.label,
    required this.onTap,
    this.filled = true,
    this.icon,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final IconData? icon;

  /// Nút nhỏ nằm trong hàng danh sách.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = filled
        ? TutorColors.bg
        : (enabled ? TutorColors.ink : TutorColors.ink4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          compact ? 999 : TutorSurface.radius,
        ),
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled
                ? (enabled ? TutorColors.ink : TutorColors.ink4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              compact ? 999 : TutorSurface.radius,
            ),
            border: filled ? null : Border.all(color: TutorColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: TutorType.action(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hàng danh sách chuẩn: avatar/icon · tiêu đề + phụ đề · phần đuôi.
class TutorListRow extends StatelessWidget {
  const TutorListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: dense ? 11 : 14,
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TutorType.rowTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TutorType.rowSub(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar chữ cái đầu — dùng khi chưa có ảnh.
class TutorAvatar extends StatelessWidget {
  const TutorAvatar({
    required this.name,
    this.size = 40,
    this.imageUrl,
    super.key,
  });

  final String name;
  final double size;
  final String? imageUrl;

  static const List<Color> _palette = TutorColors.avatarPalette;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final color = _palette[name.hashCode.abs() % _palette.length];

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialCircle(initial, color),
        ),
      );
    }
    return _initialCircle(initial, color);
  }

  Widget _initialCircle(String initial, Color color) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: Text(
      initial,
      style: TutorType.rowTitle(
        color: TutorColors.bg,
      ).copyWith(fontSize: size * 0.4),
    ),
  );
}

/// Trạng thái rỗng: một icon mờ, một câu giải thích, hành động tuỳ chọn.
class TutorEmptyState extends StatelessWidget {
  const TutorEmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 30, color: TutorColors.ink4),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TutorType.rowSub(),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TutorButton(
              label: actionLabel!,
              onTap: onAction,
              filled: false,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton xám khi tải — bố cục không nhảy khi dữ liệu về.
class TutorSkeleton extends StatelessWidget {
  const TutorSkeleton({
    required this.height,
    this.width = double.infinity,
    this.radius = 8,
    super.key,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: TutorColors.surfaceSunken,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
