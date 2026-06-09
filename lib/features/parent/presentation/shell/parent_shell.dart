import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/shared/widgets/auth_listener.dart';

class ParentShellScrollNotifier extends InheritedNotifier<ValueNotifier<int>> {
  const ParentShellScrollNotifier({
    required ValueNotifier<int> notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);

  static ValueNotifier<int>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ParentShellScrollNotifier>()
      ?.notifier;
}

// Tab order: Home(0) · Search(1) · Info(2) · Messages(3) · Profile(4)
class ParentShell extends StatefulWidget {
  const ParentShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  static const double _barFlatHeight = 64;

  final _scrollNotifier = ValueNotifier<int>(-1);

  @override
  void dispose() {
    _scrollNotifier.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    final current = widget.navigationShell.currentIndex;
    if (index == current) {
      _scrollNotifier.value = index;
      _scrollNotifier.value = -1;
      widget.navigationShell.goBranch(index, initialLocation: true);
    } else {
      widget.navigationShell.goBranch(index);
    }
  }

  bool _onPopInvoked() {
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.navigationShell.currentIndex;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final totalHeight = _barFlatHeight + bottomPad;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final canExit = _onPopInvoked();
        if (canExit) {
          unawaited(Navigator.of(context).maybePop());
        }
      },
      child: ParentShellScrollNotifier(
        notifier: _scrollNotifier,
        child: Scaffold(
          extendBody: true,
          body: AuthListener(child: widget.navigationShell),
          bottomNavigationBar: SizedBox(
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FlatBarPainter(
                      color: AppColors.paper,
                      shadowColor: Colors.black.withValues(alpha: 0.8),
                      borderColor: Colors.black.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: _barFlatHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const tabCount = 5;
                      final tabWidth = constraints.maxWidth / tabCount;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // sliding track indicator
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            left: tabWidth * current,
                            top: 0,
                            width: tabWidth,
                            height: 3,
                            child: Center(
                              child: Container(
                                width: 44,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _NavTab(
                                index: 0,
                                current: current,
                                onTap: _onTap,
                                icon: Icons.home_outlined,
                                activeIcon: Icons.home_rounded,
                                label: 'Trang chủ',
                              ),
                              _NavTab(
                                index: 1,
                                current: current,
                                onTap: _onTap,
                                icon: Icons.search_outlined,
                                activeIcon: Icons.search_rounded,
                                label: 'Tìm gia sư',
                              ),
                              _NavTab(
                                index: 2,
                                current: current,
                                onTap: _onTap,
                                icon: Icons.menu_book_outlined,
                                activeIcon: Icons.menu_book_rounded,
                                label: 'Thông tin',
                              ),
                              _NavTab(
                                index: 3,
                                current: current,
                                onTap: _onTap,
                                icon: Icons.chat_bubble_outline_rounded,
                                activeIcon: Icons.chat_bubble_rounded,
                                label: 'Tin nhắn',
                              ),
                              _NavTab(
                                index: 4,
                                current: current,
                                onTap: _onTap,
                                icon: Icons.person_outline_rounded,
                                activeIcon: Icons.person_rounded,
                                label: 'Tài khoản',
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

mixin ParentScrollToTopMixin<T extends StatefulWidget> on State<T> {
  void listenScrollToTop(
    BuildContext context,
    int branchIndex,
    ScrollController controller,
  ) {
    final notifier = ParentShellScrollNotifier.of(context);
    if (notifier == null) return;
    notifier.addListener(() {
      if (notifier.value == branchIndex && controller.hasClients) {
        unawaited(
          controller.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }
}

class _FlatBarPainter extends CustomPainter {
  _FlatBarPainter({
    required this.color,
    required this.shadowColor,
    required this.borderColor,
  });

  final Color color;
  final Color shadowColor;
  final Color borderColor;

  static const double _cornerR = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, _cornerR)
      ..quadraticBezierTo(0, 0, _cornerR, 0)
      ..lineTo(size.width - _cornerR, 0)
      ..quadraticBezierTo(size.width, 0, size.width, _cornerR)
      ..lineTo(size.width, size.height)
      ..close();

    canvas
      ..drawShadow(path, shadowColor, 8, false)
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
  }

  @override
  bool shouldRepaint(covariant _FlatBarPainter old) =>
      old.color != color ||
      old.shadowColor != shadowColor ||
      old.borderColor != borderColor;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.index,
    required this.current,
    required this.onTap,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    const accent = AppColors.oxblood;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  selected ? activeIcon : icon,
                  key: ValueKey(selected),
                  size: 28,
                  color: selected ? accent : AppColors.ink4,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? accent : AppColors.ink4,
                  letterSpacing: 0.04,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
