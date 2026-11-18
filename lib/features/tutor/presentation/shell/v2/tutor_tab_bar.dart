import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';

/// Một tab: icon nét mảnh + nhãn.
class TutorTabItem {
  const TutorTabItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Thanh tab V5.6: viên thuốc nổi (4 tab icon + nhãn, tab đang mở gạch chân
/// mực) và nút tròn ghi âm bên phải. Nền giấy phía sau, không kẻ.
class TutorTabBar extends StatelessWidget {
  const TutorTabBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.onRecord,
    super.key,
  });

  final List<TutorTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Nút tròn bên phải: bắt đầu ghi âm.
  final VoidCallback onRecord;

  /// Chiều cao viên thuốc và nút tròn.
  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: TutorColors.paperBottom,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, 14 + bottom),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: TutorColors.surface,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: TutorColors.raisedCardShadow,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _Tab(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            _RecordButton(onTap: onRecord),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});

  final TutorTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? TutorColors.ink : const Color(0xFF8A8F89);
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: TutorTabBar.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 21, color: color),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TutorType.navLabel(color: color, selected: selected),
              ),
              const SizedBox(height: 2),
              Container(
                width: 18,
                height: 2,
                decoration: BoxDecoration(
                  color: selected ? TutorColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Bắt đầu ghi âm',
    excludeSemantics: true,
    child: Container(
      width: TutorTabBar.height,
      height: TutorTabBar.height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: TutorColors.heroShadow(TutorColors.ink),
      ),
      child: Material(
        color: TutorColors.ink,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Icon(
            Icons.mic_none_rounded,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

/// Khoảng cách tối thiểu phía dưới nội dung để không bị che (giữ cho màn cũ).
const double kTutorTabBarReserve = TutorTabBar.height + 22;

/// Gutter dùng chung (tiện cho màn cần canh mép với thanh tab).
const double kTutorTabGutter = TutorSurface.gutter;
