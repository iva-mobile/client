import 'package:fake_async/fake_async.dart';
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

      expect(model.transcript, equals(transcript));
      expect(() => model.transcript.add('extra'), throwsUnsupportedError);
      expect(model.activeWordIndex, 1);
      expect(model.isCursorVisible, isFalse);
      expect(model.waveformData, isNotEmpty);
      expect(model.waveformData.every((v) => v == 0.0), isTrue);
      expect(model.transcribedText, 'Herman is recording');
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

    test('clamps out of range indices', () {
      final model = VoiceToTextModelState(initialTranscript: transcript);
      var notifyCount = 0;
      model.addListener(() => notifyCount++);

      model.setActiveWord(-1);
      model.setActiveWord(transcript.length);

      expect(model.activeWordIndex, transcript.length - 1);
      expect(notifyCount, 1);
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

        expect(model.waveformData, equals([0.1, 0.5, 1.0]));
        expect(() => model.waveformData.add(0.3), throwsUnsupportedError);
        await Future<void>.delayed(Duration.zero);
        expect(events, [
          [0.1, 0.5, 1.0],
        ]);
        expect(notifyCount, 1);

        await subscription.cancel();
        model.dispose();
      },
    );

    test('timer increments while running and pauses correctly', () {
      fakeAsync((async) {
        final model = VoiceToTextModelState(initialTranscript: transcript);

        model.startTimer();
        expect(model.isTimerRunning, isTrue);

        async.elapse(const Duration(seconds: 2));
        expect(model.elapsedDuration, const Duration(seconds: 2));

        model.pauseTimer();
        expect(model.isTimerRunning, isFalse);

        async.elapse(const Duration(seconds: 3));
        expect(model.elapsedDuration, const Duration(seconds: 2));

        model.startTimer();
        async.elapse(const Duration(seconds: 1));
        expect(model.elapsedDuration, const Duration(seconds: 3));

        model.dispose();
      });
    });

    test('resetTimer clears elapsed duration and stops the timer', () {
      fakeAsync((async) {
        final model = VoiceToTextModelState(initialTranscript: transcript);

        model.startTimer();
        async.elapse(const Duration(seconds: 5));
        expect(model.elapsedDuration, const Duration(seconds: 5));

        model.resetTimer();
        expect(model.elapsedDuration, Duration.zero);
        expect(model.isTimerRunning, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(model.elapsedDuration, Duration.zero);

        model.dispose();
      });
    });

    test('updateTranscription replaces transcript and active word', () {
      final model = VoiceToTextModelState(initialTranscript: transcript);
      var notifyCount = 0;
      model.addListener(() => notifyCount++);

      model.updateTranscription('Hello world from iva', activeWordIndex: 1);

      expect(model.transcript, equals(['Hello', 'world', 'from', 'iva']));
      expect(model.transcribedText, 'Hello world from iva');
      expect(model.activeWordIndex, 1);
      expect(notifyCount, 1);

      model.updateTranscription('Hello world from iva', activeWordIndex: 1);
      expect(notifyCount, 1, reason: 'no change, no notification');

      model.updateTranscription('Hello world from iva');
      expect(model.activeWordIndex, 3);
    });

    test('recording state transitions control timer lifecycle', () {
      fakeAsync((async) {
        final model = VoiceToTextModelState(initialTranscript: transcript);

        expect(model.recordingState, RecordingState.idle);

        model.startRecording();
        expect(model.recordingState, RecordingState.recording);
        async.elapse(const Duration(seconds: 2));
        expect(model.elapsedDuration, const Duration(seconds: 2));

        model.pauseRecording();
        expect(model.recordingState, RecordingState.paused);
        async.elapse(const Duration(seconds: 1));
        expect(model.elapsedDuration, const Duration(seconds: 2));

        model.resumeRecording();
        expect(model.recordingState, RecordingState.recording);
        async.elapse(const Duration(seconds: 1));
        expect(model.elapsedDuration, const Duration(seconds: 3));

        model.stopRecording();
        expect(model.recordingState, RecordingState.stopped);
        expect(model.elapsedDuration, Duration.zero);

        model.restartRecording();
        expect(model.recordingState, RecordingState.recording);
        expect(model.elapsedDuration, Duration.zero);
        expect(model.transcript, isEmpty);

        async.elapse(const Duration(seconds: 1));
        expect(model.elapsedDuration, const Duration(seconds: 1));

        model.updateTranscription('partial text');
        model.updateWaveform([0.2, 0.4]);
        model.discardRecording();
        expect(model.recordingState, RecordingState.idle);
        expect(model.elapsedDuration, Duration.zero);
        expect(model.waveformData, isNotEmpty);
        expect(model.waveformData.every((v) => v == 0.0), isTrue);
        expect(model.transcript, isEmpty);

        model.dispose();
      });
    });
  });
}
