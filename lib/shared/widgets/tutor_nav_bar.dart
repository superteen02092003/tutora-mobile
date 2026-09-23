import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';

/// Chiều cao ruột thanh tab (chưa tính safe area và lề ngoài).
const double kTutorNavHeight = 62;

/// Lề bao quanh viên thuốc — cộng vào chiều cao thật mà thanh tab chiếm.
const double _kNavMargin = 12;

/// Đường kính nút hành động nổi ở giữa (ghi âm).
const double _kCenterSize = 64;

/// Khoảng trống chừa giữa hai nửa tab để nút ghi âm rơi vào, không đè lên chữ.
const double _kCenterGap = 84;

/// Tổng chiều cao thanh tab chiếm chỗ, cho màn con chừa đáy khi cần.
const double kTutorNavTotalHeight = kTutorNavHeight + _kNavMargin * 2;

class TutorNavItem {
  const TutorNavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Số việc chưa xử lý; 0 = không hiện badge.
  final int badgeCount;
}

/// Thanh tab dưới cùng cho gia sư — viên thuốc nổi, tab đang mở có nền riêng.
///
/// Vẫn phẳng: nền giấy đặc, một viền mảnh, không blur. Tab đang mở được đánh
/// dấu bằng viên thuốc nền nhạt thay vì chỉ đổi màu chữ — liếc một cái là thấy
/// mình đang ở đâu, kể cả khi cầm máy một tay ngoài đường.
///
/// Khi truyền [onCenterTap], thanh chừa một khoảng ở giữa và đặt một nút tròn
/// nổi lên trên — dành cho hành động chính của role (ghi âm buổi học). Nút nằm
/// ngoài hệ tab: nó không phải một trang, nên không bao giờ được tô "đang chọn".
class TutorNavBar extends StatelessWidget {
  const TutorNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.onCenterTap,
    this.centerIcon = Icons.mic_rounded,
    this.centerTooltip,
    super.key,
  });

  final List<TutorNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Null = không có nút giữa, thanh tab chạy như cũ.
  final VoidCallback? onCenterTap;
  final IconData centerIcon;
  final String? centerTooltip;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasCenter = onCenterTap != null;

    // Không có nền đặc phía sau: nội dung trôi thẳng dưới viên thuốc, chỉ bị
    // lớp kính làm mờ. Đó là phần "liquid" — dải nền đặc sẽ cắt ngang màn hình.
    return SafeArea(
      top: false,
      // Máy có thanh gesture đã chừa sẵn khoảng dưới, khỏi cộng thêm lề đầy.
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _kNavMargin,
          0,
          _kNavMargin,
          bottomPad > 0 ? 4 : _kNavMargin,
        ),
        // Clip.none: nút giữa được phép nhô lên khỏi viên thuốc.
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(kTutorNavHeight / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: kTutorNavHeight,
                  decoration: BoxDecoration(
                    color: TutorColors.surface.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(kTutorNavHeight / 2),
                    border: Border.all(
                      color: TutorColors.surface.withValues(alpha: 0.7),
                    ),
                    // Thanh tab là một trong hai thứ duy nhất được phép nổi
                    // trong hệ này (thứ còn lại là nút giữa) — xem TutorColors.
                    boxShadow: TutorColors.raisedCardShadow,
                  ),
                  child: _NavContent(
                    items: items,
                    currentIndex: currentIndex,
                    onTap: onTap,
                    centerGap: hasCenter ? _kCenterGap : 0,
                  ),
                ),
              ),
            ),
            if (hasCenter)
              Positioned(
                bottom: (kTutorNavHeight - _kCenterSize) / 2 + 12,
                child: _CenterAction(
                  icon: centerIcon,
                  tooltip: centerTooltip,
                  onTap: onCenterTap!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Nút hành động chính, nổi lên khỏi thanh tab.
class _CenterAction extends StatelessWidget {
  const _CenterAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: TutorColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: _kCenterSize,
            height: _kCenterSize,
            child: Icon(icon, size: 27, color: TutorColors.bg),
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: TutorColors.heroShadow(TutorColors.primary),
      ),
      child: tooltip == null
          ? button
          : Tooltip(message: tooltip, child: button),
    );
  }
}

/// Ruột thanh tab: một viên thuốc nền trượt phía dưới, các tab nằm trên.
///
/// Viên thuốc trượt (thay vì mỗi tab tự bật/tắt nền) để mắt bám được đường đi
/// khi đổi tab, và để nó luôn rộng đúng một ô tab — không co theo độ dài chữ.
///
/// [centerGap] > 0 thì chừa khoảng đó ở giữa hai nửa tab; ô tab và viên thuốc
/// được tính theo bề rộng còn lại, nên nút giữa không bao giờ đè lên nhãn.
class _NavContent extends StatelessWidget {
  const _NavContent({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerGap = 0,
  });

  final List<TutorNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double centerGap;

  @override
  Widget build(BuildContext context) {
    final count = items.length;
    if (count == 0) return const SizedBox.shrink();

    final slot = items.indexWhere((e) => e.index == currentIndex);
    final hasSlot = slot >= 0;
    final leftCount = count ~/ 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = (constraints.maxWidth - centerGap) / count;
        double xOf(int i) => i * tabWidth + (i >= leftCount ? centerGap : 0);

        return Stack(
          children: [
            // easeOutBack: viên thuốc vượt đích một chút rồi lùi về — cảm giác
            // vật lý của spring, khác kiểu trượt đều rồi phanh gấp.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              left: xOf(hasSlot ? slot : 0),
              width: tabWidth,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: hasSlot ? 1 : 0,
                child: const _TabIndicator(),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i == leftCount && centerGap > 0)
                    SizedBox(width: centerGap),
                  SizedBox(
                    width: tabWidth,
                    child: _NavTab(
                      item: items[i],
                      selected: items[i].index == currentIndex,
                      onTap: () => onTap(items[i].index),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Viên thuốc nền trượt theo tab đang mở — phẳng, không đổ bóng.
class _TabIndicator extends StatelessWidget {
  const _TabIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: TutorColors.ink.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final TutorNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? TutorColors.ink : TutorColors.ink4;

    return InkResponse(
      onTap: onTap,
      radius: 42,
      highlightShape: BoxShape.rectangle,
      // Nền trong suốt: viên thuốc ở lớp dưới hiện xuyên qua.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon nhún nhẹ lúc được chọn, hưởng ứng viên thuốc vừa trôi tới.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: selected ? 1.12 : 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: _IconWithBadge(
              icon: selected ? item.activeIcon : item.icon,
              color: color,
              count: item.badgeCount,
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TutorType.navLabel(color: color, selected: selected),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.color,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final badge = count > 99 ? '99+' : '$count';

    return SizedBox(
      height: 23,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          if (count > 0)
            Positioned(
              top: -5,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TutorStatusTone.attention,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: TutorColors.surface, width: 1.5),
                ),
                child: Text(
                  badge,
                  style: TutorType.caption(color: TutorColors.surface).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
