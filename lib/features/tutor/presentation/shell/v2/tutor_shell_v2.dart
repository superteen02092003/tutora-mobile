import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';
import 'package:tutora/features/tutor/presentation/shell/v2/tutor_tab_bar.dart';
import 'package:tutora/shared/widgets/auth_listener.dart';

/// Shell gia sư theo design canvas (11/2026) — 4 tab chữ:
/// Trang chủ · Lộ trình · Bài học · Ghi âm.
///
/// Không còn nút mic nổi ở giữa: ghi âm bắt đầu từ màn "Trước buổi học", hồ sơ
/// học sinh, thẻ buổi hôm nay, hoặc nút "Ghi âm buổi học" đầu tab Ghi âm. Thông
/// báo và Tôi (cài đặt) vẫn là màn con mở từ header Trang chủ.
class TutorShellV2 extends ConsumerStatefulWidget {
  const TutorShellV2({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<TutorShellV2> createState() => _TutorShellV2State();
}

class _TutorShellV2State extends ConsumerState<TutorShellV2> {
  static const _labels = ['Trang chủ', 'Lộ trình', 'Bài học', 'Ghi âm'];

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
          labels: _labels,
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}
