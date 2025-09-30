import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iva_mobile/features/voice_to_text/widget/waveform.dart';

void main() {
  group('WaveformPainter', () {
    test('normalizes values into 0-1 range and handles NaN', () {
      final result = WaveformPainter.normalize([1.5, -0.1, double.nan]);
      expect(result, [1.0, 0.0, 0.0]);
    });
  });

  group('WaveformWidget', () {
    testWidgets('renders CustomPaint with provided amplitudes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WaveformWidget(amplitudes: [0.2, 0.8])),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(WaveformWidget),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is WaveformPainter,
        ),
      );
      expect(customPaintFinder, findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaint.painter as WaveformPainter;
      expect(painter.amplitudes, [0.2, 0.8]);
    });

    testWidgets('animates to updated amplitudes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _WaveformHost())),
      );

      final state = tester.state<_WaveformHostState>(
        find.byType(_WaveformHost),
      );
      state.update([0.9, 0.7]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final customPaintFinder = find.descendant(
        of: find.byType(WaveformWidget),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is WaveformPainter,
        ),
      );
      final painter =
          tester.widget<CustomPaint>(customPaintFinder).painter
              as WaveformPainter;
      expect(painter.amplitudes, [0.9, 0.7]);
    });
  });
}

class _WaveformHost extends StatefulWidget {
  const _WaveformHost();

  @override
  State<_WaveformHost> createState() => _WaveformHostState();
}

class _WaveformHostState extends State<_WaveformHost> {
  List<double> _amplitudes = const [0.1, 0.3];

  void update(List<double> amplitudes) {
    setState(() {
      _amplitudes = amplitudes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WaveformWidget(
      amplitudes: _amplitudes,
      animationDuration: const Duration(milliseconds: 40),
    );
  }
}
