import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';

void main() {
  testWidgets('scrolls only the visible page without changing routes', (
    tester,
  ) async {
    final rootKey = GlobalKey();
    final visibleController = ScrollController();
    final hiddenController = ScrollController();
    addTearDown(visibleController.dispose);
    addTearDown(hiddenController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: rootKey,
            child: Stack(
              children: [
                ListView(
                  controller: visibleController,
                  children: const [SizedBox(height: 2000)],
                ),
                Offstage(
                  child: ListView(
                    controller: hiddenController,
                    children: const [SizedBox(height: 2000)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    visibleController.jumpTo(500);
    hiddenController.jumpTo(600);
    scrollVisibleTutorContentToTop(rootKey.currentContext);
    await tester.pumpAndSettle();

    expect(visibleController.offset, 0);
    expect(hiddenController.offset, 600);
  });
}
