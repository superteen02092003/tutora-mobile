import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';

void main() {
  testWidgets('child header always shows back, title and optional action', (
    tester,
  ) async {
    var actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TutorChildHeader(
            title: 'Tài khoản ngân hàng',
            onBack: () {},
            action: IconButton(
              onPressed: () => actionTapped = true,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tài khoản ngân hàng'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(TutorChildHeader)), const Size(800, 56));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    expect(actionTapped, isTrue);
  });
}
