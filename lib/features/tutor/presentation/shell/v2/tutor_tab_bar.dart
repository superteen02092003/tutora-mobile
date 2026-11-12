import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';

/// Thanh tab của canvas: 4 nhãn chữ hoa trên nền giấy, kẻ mực phía trên, tab
/// đang mở gạch chân đồng. Không icon, không nút nổi.
class TutorTabBar extends StatelessWidget {
  const TutorTabBar({
    required this.labels,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Chiều cao phần thanh (chưa tính vùng an toàn dưới đáy).
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: TutorColors.bg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          TutorSurface.gutter,
          0,
          TutorSurface.gutter,
          bottom,
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(border: Border(top: TutorSurface.rule)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < labels.length; i++)
                _Tab(
                  label: labels[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? TutorColors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                label.toUpperCase(),
                style: TutorType.kicker(
                  color: selected ? TutorColors.ink : TutorColors.ink3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
