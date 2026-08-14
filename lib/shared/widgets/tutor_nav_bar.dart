import 'package:flutter/material.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';

/// Chiều cao thanh tab (chưa tính safe area dưới).
const double kTutorNavHeight = 58;

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

/// Thanh tab dưới cùng cho gia sư.
///
/// Cố ý phẳng: nền giấy đặc, một viền trên mảnh, không blur, không đổ bóng,
/// không nút nổi. Thanh tab là hạ tầng điều hướng — nó phải biến mất khỏi
/// sự chú ý để nội dung nổi lên.
class TutorNavBar extends StatelessWidget {
  const TutorNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<TutorNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: kTutorNavHeight,
          child: Row(
            children: [
              for (final item in items)
                _NavTab(
                  item: item,
                  selected: item.index == currentIndex,
                  onTap: () => onTap(item.index),
                ),
            ],
          ),
        ),
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
    final color = selected ? AppColors.ink : AppColors.ink4;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 42,
        highlightShape: BoxShape.rectangle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IconWithBadge(
              icon: selected ? item.activeIcon : item.icon,
              color: color,
              count: item.badgeCount,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TutorType.navLabel(color: color, selected: selected),
              maxLines: 1,
            ),
          ],
        ),
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
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 23, color: color),
          if (count > 0)
            Positioned(
              top: -3,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.5),
                constraints: const BoxConstraints(minWidth: 17),
                height: 17,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TutorStatusTone.attention,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.paper, width: 1.5),
                ),
                child: Text(
                  badge,
                  style: TutorType.caption(color: AppColors.paper).copyWith(
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
