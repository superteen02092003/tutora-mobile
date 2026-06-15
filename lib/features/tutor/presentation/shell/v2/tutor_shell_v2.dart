import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';
import 'package:tutora/shared/widgets/auth_listener.dart';
import 'package:tutora/shared/widgets/floating_pill_nav_bar.dart';

/// Tutor shell v2 — floating glassmorphism pill bar.
class TutorShellV2 extends StatefulWidget {
  const TutorShellV2({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<TutorShellV2> createState() => _TutorShellV2State();
}

class _TutorShellV2State extends State<TutorShellV2> {
  final _scrollNotifier = ValueNotifier<int>(-1);
  final _navVisible = ValueNotifier<bool>(true);

  static const _items = [
    PillNavItem(
      index: 0,
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Trang chủ',
    ),
    PillNavItem(
      index: 1,
      icon: Icons.add_box_outlined,
      activeIcon: Icons.add_box_rounded,
      label: 'Diễn đàn',
    ),
    PillNavItem(
      index: 3,
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Tin nhắn',
    ),
    PillNavItem(
      index: 4,
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Tôi',
    ),
  ];

  @override
  void dispose() {
    _scrollNotifier.dispose();
    _navVisible.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    _navVisible.value = true;
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final canExit = _onPopInvoked();
        if (canExit) {
          unawaited(Navigator.of(context).maybePop());
        }
      },
      child: TutorShellScrollNotifier(
        notifier: _scrollNotifier,
        child: Scaffold(
          extendBody: true,
          body: HideOnScroll(
            visible: _navVisible,
            child: AuthListener(child: widget.navigationShell),
          ),
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: _navVisible,
            builder: (context, visible, _) => FloatingPillNavBar(
              items: _items,
              currentIndex: current,
              onTap: _onTap,
              visible: visible,
              actionChild: Transform.scale(
                scale: 2,
                child: Lottie.asset(
                  'assets/icons/calendar-red.json',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              actionIsActive: current == 2,
              onActionTap: () => _onTap(2),
            ),
          ),
        ),
      ),
    );
  }
}
