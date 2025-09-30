import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iva_mobile/features/voice_to_text/view/voice_to_text_model.dart';
import 'package:iva_mobile/features/voice_to_text/widget/control_buttons.dart';

void main() {
  testWidgets('shows only microphone button when idle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en', 'US')],
        home: Scaffold(
          body: ControlButtonsRow(
            state: RecordingState.idle,
            onMicTap: _noop,
            onPause: _noop,
            onResume: _noop,
            onDiscard: _noop,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('shows pause and discard while recording', (tester) async {
    RecordingState currentState = RecordingState.recording;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en', 'US')],
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ControlButtonsRow(
                state: currentState,
                onMicTap: () {},
                onPause: () => setState(() {
                  currentState = RecordingState.paused;
                }),
                onResume: () => setState(() {
                  currentState = RecordingState.recording;
                }),
                onDiscard: () => setState(() {
                  currentState = RecordingState.idle;
                }),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(currentState, RecordingState.idle);
  });
}

void _noop() {}
