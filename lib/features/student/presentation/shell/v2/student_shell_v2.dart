import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:tutora/features/student/presentation/shell/student_shell.dart';
import 'package:tutora/shared/widgets/auth_listener.dart';
import 'package:tutora/shared/widgets/floating_pill_nav_bar.dart';

/// Student shell v2 — floating glassmorphism pill bar.
class StudentShellV2 extends StatefulWidget {
  const StudentShellV2({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<StudentShellV2> createState() => _StudentShellV2State();
}

class _StudentShellV2State extends State<StudentShellV2> {
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
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Gia sư',
    ),
    PillNavItem(
      index: 3,
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Lịch học',
    ),
    PillNavItem(
      index: 4,
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Hồ sơ',
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
      child: ShellScrollNotifier(
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
              actionChild: Lottie.asset(
                'assets/icons/button-scan.json',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                repeat: true,
              ),
              onActionTap: () => context.push('/student/capture'),
            ),
          ),
        ),
      ),
    );
  }
}
