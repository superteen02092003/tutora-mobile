import 'dart:async';

import 'package:flutter/material.dart';

/// Hạ tầng dùng chung cho shell gia sư.
///
/// Shell thật nằm ở `shell/v2/tutor_shell_v2.dart`. File này chỉ giữ kênh
/// "chạm lại tab đang mở → cuộn nội dung lên đầu": shell phát tín hiệu qua
/// [TutorShellScrollNotifier], màn con nhận qua [TutorScrollToTopMixin].
class TutorShellScrollNotifier extends InheritedNotifier<ValueNotifier<int>> {
  const TutorShellScrollNotifier({
    required ValueNotifier<int> notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);

  static ValueNotifier<int>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TutorShellScrollNotifier>()
      ?.notifier;
}

mixin TutorScrollToTopMixin<T extends StatefulWidget> on State<T> {
  void listenScrollToTop(
    BuildContext context,
    int branchIndex,
    ScrollController controller,
  ) {
    final notifier = TutorShellScrollNotifier.of(context);
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
