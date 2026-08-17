import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';
import 'package:tutora/shared/providers/notification_provider.dart';
import 'package:tutora/shared/widgets/auth_listener.dart';
import 'package:tutora/shared/widgets/tutor_nav_bar.dart';

/// Shell gia sư — 5 tab: Trang chủ · Lịch · Ví · Tin nhắn · Tôi.
///
/// Thanh tab cố định (không ẩn khi cuộn): trên mobile gia sư chủ yếu liếc
/// nhanh rồi nhảy tab, nên thanh biến mất lúc cuộn gây hụt tay.
class TutorShellV2 extends ConsumerStatefulWidget {
  const TutorShellV2({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<TutorShellV2> createState() => _TutorShellV2State();
}

class _TutorShellV2State extends ConsumerState<TutorShellV2> {
  final _scrollNotifier = ValueNotifier<int>(-1);

  @override
  void dispose() {
    _scrollNotifier.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    final current = widget.navigationShell.currentIndex;
    if (index == current) {
      // Chạm lại tab đang mở → cuộn nội dung lên đầu.
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
      child: TutorShellScrollNotifier(
        notifier: _scrollNotifier,
        child: Scaffold(
          // Thanh tab trong suốt → nội dung phải chạy xuống dưới nó.
          extendBody: true,
          body: AuthListener(child: widget.navigationShell),
          bottomNavigationBar: TutorNavBar(
            items: items,
            currentIndex: widget.navigationShell.currentIndex,
            onTap: _onTap,
          ),
        ),
      ),
    );
  }
}
