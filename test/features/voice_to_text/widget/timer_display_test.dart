import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iva_mobile/features/voice_to_text/widget/timer_display.dart';

void main() {
  testWidgets('TimerDisplay formats duration as MM:SS', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TimerDisplay(duration: Duration(minutes: 5, seconds: 9)),
        ),
      ),
    );

    expect(find.text('05:09'), findsOneWidget);
  });
}
