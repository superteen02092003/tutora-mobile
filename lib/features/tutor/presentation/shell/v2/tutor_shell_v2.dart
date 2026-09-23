import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/tutor/presentation/providers/lesson_recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';
import 'package:tutora/shared/widgets/auth_listener.dart';
import 'package:tutora/shared/widgets/floating_pill_nav_bar.dart';
import 'package:tutora/shared/widgets/tutor_nav_bar.dart';

/// Shell gia sư — 2 tab: Trang chủ · Lịch, cộng nút ghi âm nổi ở giữa.
///
/// v0.1 cố tình rút gọn: việc chính của gia sư trong app này là bấm ghi âm
/// buổi học, nên nút đó phải là thứ to nhất và ở chỗ ngón cái chạm tới.
/// Thông báo và Tôi (hồ sơ) là màn con vào từ header Trang chủ. Ví, tin nhắn,
/// đặt lịch... chỉ có trên web tutora.vn.
class TutorShellV2 extends ConsumerStatefulWidget {
  const TutorShellV2({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<TutorShellV2> createState() => _TutorShellV2State();
}

class _TutorShellV2State extends ConsumerState<TutorShellV2> {
  /// Đang có buổi ghi dở (đã thu nhỏ về trang chủ) → mở lại màn "Đang ghi";
  /// chưa ghi → mở màn chọn buổi.
  void _onRecordTap() {
    final recording = ref.read(lessonRecordingProvider);
    final target = ref.read(lessonRecordingProvider.notifier).target;
    if (recording.isRecording && target != null) {
      unawaited(context.push(AppRoutes.tutorRecording, extra: target));
    } else {
      unawaited(context.push(AppRoutes.tutorRecorder));
    }
  }

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
    final items = [
      const TutorNavItem(
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Trang chủ',
      ),
      const TutorNavItem(
        index: 1,
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Lịch',
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
              centerTooltip: 'Ghi âm buổi học',
              onCenterTap: _onRecordTap,
            ),
          ),
        ),
      ),
    );
  }
}
