import 'dart:async';

import 'package:flutter/material.dart';

void scrollVisibleTutorContentToTop(BuildContext? root) {
  if (root == null) return;
  final positions = <ScrollPosition>{};

  void visit(Element element) {
    final widget = element.widget;
    if (widget is Offstage && widget.offstage) return;
    if (widget is TickerMode && !widget.enabled) return;
    if (element is StatefulElement && element.state is ScrollableState) {
      final position = (element.state as ScrollableState).position;
      if (position.axis == Axis.vertical &&
          position.hasContentDimensions &&
          position.pixels > position.minScrollExtent) {
        positions.add(position);
      }
    }
    element.visitChildren(visit);
  }

  root.visitChildElements(visit);
  for (final position in positions) {
    unawaited(
      position.animateTo(
        position.minScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
