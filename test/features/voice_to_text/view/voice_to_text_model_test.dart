import 'package:flutter_test/flutter_test.dart';

import 'package:iva_mobile/features/voice_to_text/view/voice_to_text_model.dart';

void main() {
  group('VoiceToTextModelState', () {
    const transcript = ['Herman', 'is', 'recording'];

    test('exposes initial state', () {
      final model = VoiceToTextModelState(
        initialTranscript: transcript,
        initialActiveWordIndex: 1,
        initialCursorVisible: false,
      );

      expect(model.transcript, transcript);
      expect(() => model.transcript.add('extra'), throwsUnsupportedError);
      expect(model.activeWordIndex, 1);
      expect(model.isCursorVisible, isFalse);
      expect(model.waveformData, isEmpty);
    });

    test('updates active word and notifies listeners', () {
      final model = VoiceToTextModelState(initialTranscript: transcript);
      var notifyCount = 0;
      model.addListener(() => notifyCount++);

      model.setActiveWord(2);

      expect(model.activeWordIndex, 2);
      expect(notifyCount, 1);

      // no-op when setting the same index
      model.setActiveWord(2);
      expect(notifyCount, 1);
    });

    test('ignores out of range indices', () {
      final model = VoiceToTextModelState(initialTranscript: transcript);
      var notifyCount = 0;
      model.addListener(() => notifyCount++);

      model.setActiveWord(-1);
      model.setActiveWord(transcript.length);

      expect(model.activeWordIndex, 0);
      expect(notifyCount, 0);
    });

    test('toggles cursor visibility and notifies once per change', () {
      final model = VoiceToTextModelState(initialTranscript: transcript);
      var notifyCount = 0;
      model.addListener(() => notifyCount++);

      model.toggleCursorVisibility(false);
      expect(model.isCursorVisible, isFalse);
      expect(notifyCount, 1);

      model.toggleCursorVisibility(false);
      expect(notifyCount, 1);

      model.toggleCursorVisibility(true);
      expect(model.isCursorVisible, isTrue);
      expect(notifyCount, 2);
    });

    test(
      'updateWaveform stores immutable data, notifies, and emits over stream',
      () async {
        final model = VoiceToTextModelState(initialTranscript: transcript);
        final events = <List<double>>[];
        final subscription = model.waveformStream.listen(events.add);

        var notifyCount = 0;
        model.addListener(() => notifyCount++);

        model.updateWaveform([0.1, 0.5, 1.2]);

        expect(model.waveformData, [0.1, 0.5, 1.2]);
        expect(() => model.waveformData.add(0.3), throwsUnsupportedError);
        await Future<void>.delayed(Duration.zero);
        expect(events, [
          [0.1, 0.5, 1.2],
        ]);
        expect(notifyCount, 1);

        await subscription.cancel();
        model.dispose();
      },
    );
  });
}
