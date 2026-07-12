import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

const double kFloatingNavHeight = 64 + 16;

class PillNavItem {
  const PillNavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// A glassmorphism floating bottom navigation bar:
/// a frosted pill holding [items], plus a separate floating round
/// action button on the far right (the "action" slot).
///
/// Layout-only widget — it owns no routing. The host shell wires
/// [currentIndex], [onTap] and [onActionTap].
class FloatingPillNavBar extends StatelessWidget {
  const FloatingPillNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.onActionTap,
    this.actionIcon,
    this.actionActiveIcon,
    this.actionChild,
    this.actionIsActive = false,
    this.visible = true,
    super.key,
  }) : assert(
         actionChild != null || actionIcon != null,
         'Provide actionChild or actionIcon',
       );

  final List<PillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Custom content for the round action button (e.g. an animated Lottie).
  /// Takes precedence over [actionIcon]/[actionActiveIcon] when non-null.
  final Widget? actionChild;
  final IconData? actionIcon;
  final IconData? actionActiveIcon;
  final VoidCallback onActionTap;
  final bool actionIsActive;

  /// When false, the bar slides down off-screen (used for hide-on-scroll).
  final bool visible;

  static const double _barHeight = 64;
  static const double _actionSize = 60;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1.6),
      child: Stack(
        children: [
          // Solid background behind the pill so content scrolling underneath
          // is covered by the app background instead of leaving a gap.
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: AppColors.cream),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad > 0 ? 8 : 16),
              child: SizedBox(
                height: _barHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_barHeight / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 28,
                              spreadRadius: -2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_barHeight / 2),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                            child: Container(
                              height: _barHeight,
                              decoration: BoxDecoration(
                                // Vertical sheen: brighter at the top edge, like glass.
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.88),
                                    AppColors.paper.withValues(alpha: 0.70),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  _barHeight / 2,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  width: 1.2,
                                ),
                              ),
                              child: _PillContent(
                                items: items,
                                currentIndex: currentIndex,
                                onTap: onTap,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    // Separate floating round action button (far right).
                    _ActionButton(
                      size: _actionSize,
                      onTap: onActionTap,
                      fill: actionChild == null
                          ? (actionIsActive ? AppColors.oxblood : AppColors.ink)
                          : null,
                      child:
                          actionChild ??
                          Icon(
                            actionIsActive
                                ? (actionActiveIcon ?? actionIcon!)
                                : actionIcon!,
                            size: 24,
                            color: actionIsActive
                                ? const Color(0xFFFFF1E6)
                                : AppColors.cream,
                          ),
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

class _PillContent extends StatelessWidget {
  const _PillContent({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<PillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final count = items.length;
    final slot = items.indexWhere((e) => e.index == currentIndex);
    final hasSlot = slot >= 0;

    final alignX = (count <= 1 || !hasSlot)
        ? 0.0
        : (slot / (count - 1)) * 2 - 1;

    return Stack(
      children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment(alignX, 0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: hasSlot ? 1 : 0,
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              child: const _TabIndicator(),
            ),
          ),
        ),
        // Tab buttons on top (transparent — the indicator shows through).
        Row(
          children: [
            for (final item in items)
              _PillTab(
                item: item,
                selected: item.index == currentIndex,
                onTap: () => onTap(item.index),
              ),
          ],
        ),
      ],
    );
  }
}

/// The moving highlight: white raised ring + brand radial glow.
class _TabIndicator extends StatelessWidget {
  const _TabIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.oxblood.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.oxblood.withValues(alpha: 0.45),
                  AppColors.oxblood.withValues(alpha: 0.16),
                  AppColors.oxblood.withValues(alpha: 0),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onColor = selected ? AppColors.oxblood : AppColors.ink4;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animate icon/label color as the indicator slides over.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                key: ValueKey(selected),
                size: 22,
                color: onColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: onColor,
                letterSpacing: 0.04,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.size,
    required this.child,
    required this.onTap,
    this.fill,
  });

  final double size;
  final Widget child;
  final VoidCallback onTap;

  /// Optional circle fill. Null means transparent (for self-contained icons).
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        // The child is a complete icon (its own background/colors), so this
        // only adds a raised ring: border + shadow, no fill.
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(child: Center(child: child)),
        ),
      ),
    );
  }
}

class HideOnScroll extends StatefulWidget {
  const HideOnScroll({
    required this.visible,
    required this.child,
    this.threshold = 12,
    super.key,
  });

  final ValueNotifier<bool> visible;
  final Widget child;

  /// Minimum scroll delta (px) before toggling, to avoid jitter.
  final double threshold;

  @override
  State<HideOnScroll> createState() => _HideOnScrollState();
}

class _HideOnScrollState extends State<HideOnScroll> {
  double _lastOffset = 0;

  bool _onNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final offset = n.metrics.pixels;

    // Always reveal near the very top.
    if (offset <= 0) {
      widget.visible.value = true;
      _lastOffset = offset;
      return false;
    }

    final delta = offset - _lastOffset;
    if (delta.abs() < widget.threshold) return false;

    widget.visible.value = delta < 0; // scrolling up → show
    _lastOffset = offset;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}
