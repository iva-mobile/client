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
  });
}
