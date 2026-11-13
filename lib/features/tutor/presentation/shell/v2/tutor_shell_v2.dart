import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';
import 'package:tutora/features/tutor/presentation/shell/v2/tutor_tab_bar.dart';
import 'package:tutora/shared/widgets/auth_listener.dart';

/// Shell gia sư V5.6 (canvas "TopTutor tutor app V5.6", 2026-11-12):
/// 4 tab Trang chủ · Lộ trình · Bài học · Học sinh trong viên thuốc nổi, và nút
/// tròn bên phải để ghi âm (mở sheet chọn học sinh / buổi). Danh sách bản ghi
/// âm là màn con mở từ Lộ trình. Thông báo và Cài đặt mở từ header Trang chủ.
class TutorShellV2 extends ConsumerStatefulWidget {
  const TutorShellV2({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<TutorShellV2> createState() => _TutorShellV2State();
}

class _TutorShellV2State extends ConsumerState<TutorShellV2> {
  static const _items = [
    TutorTabItem(label: 'Trang chủ', icon: Icons.home_outlined),
    TutorTabItem(label: 'Lộ trình', icon: Icons.route_outlined),
    TutorTabItem(label: 'Bài học', icon: Icons.calendar_today_outlined),
    TutorTabItem(label: 'Học sinh', icon: Icons.people_outline_rounded),
  ];

  final GlobalKey _bodyKey = GlobalKey();

  void _onTap(int index) {
    if (index == widget.navigationShell.currentIndex) {
      scrollVisibleTutorContentToTop(_bodyKey.currentContext);
    } else {
      widget.navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
        } else {
          unawaited(Navigator.of(context).maybePop());
        }
      },
      child: Scaffold(
        body: KeyedSubtree(
          key: _bodyKey,
          child: AuthListener(child: widget.navigationShell),
        ),
        bottomNavigationBar: TutorTabBar(
          items: _items,
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTap,
          onRecord: () => unawaited(context.push(AppRoutes.tutorRecorder)),
        ),
      ),
    );
  }
}
