import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';
import 'package:tutora/shared/providers/notification_provider.dart';
import 'package:tutora/shared/widgets/auth_listener.dart';
import 'package:tutora/shared/widgets/floating_pill_nav_bar.dart';
import 'package:tutora/shared/widgets/tutor_nav_bar.dart';

/// Shell gia sư — 5 tab: Trang chủ · Lịch · Ví · Tin nhắn · Tôi.
class TutorShellV2 extends ConsumerStatefulWidget {
  const TutorShellV2({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<TutorShellV2> createState() => _TutorShellV2State();
}

class _TutorShellV2State extends ConsumerState<TutorShellV2> {
  final GlobalKey _bodyKey = GlobalKey();
  final _navVisible = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _navVisible.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    _navVisible.value = true;
    final current = widget.navigationShell.currentIndex;
    if (index == current) {
      scrollVisibleTutorContentToTop(_bodyKey.currentContext);
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
    // Badge tab "Tôi": khiếu nại và việc hồ sơ cần xử lý nằm trong đó.
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    final items = [
      const TutorNavItem(
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      const TutorNavItem(
        index: 1,
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Lịch',
      ),
      const TutorNavItem(
        index: 2,
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
        label: 'Ví',
      ),
      TutorNavItem(
        index: 3,
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Chat',
        badgeCount: unread,
      ),
      const TutorNavItem(
        index: 4,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Tôi',
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final canExit = _onPopInvoked();
        if (canExit) {
          unawaited(Navigator.of(context).maybePop());
        }
      },
      child: Scaffold(
        // Thanh tab trong suốt → nội dung phải chạy xuống dưới nó.
        extendBody: true,
        body: HideOnScroll(
          visible: _navVisible,
          child: KeyedSubtree(
            key: _bodyKey,
            child: AuthListener(child: widget.navigationShell),
          ),
        ),
        bottomNavigationBar: ValueListenableBuilder<bool>(
          valueListenable: _navVisible,
          builder: (context, visible, _) => AnimatedSlide(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            offset: visible ? Offset.zero : const Offset(0, 1.6),
            child: TutorNavBar(
              items: items,
              currentIndex: widget.navigationShell.currentIndex,
              onTap: _onTap,
            ),
          ),
        ),
      ),
    );
  }
}
