// no-op

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iva_mobile/core/services/audio_capture.dart';
import 'package:iva_mobile/core/services/speech_recognition.dart';

import '../widget/control_buttons.dart';
import '../widget/text_display.dart';
import '../widget/timer_display.dart';
import '../widget/waveform.dart';
import 'voice_to_text_model.dart';

class VoiceToTextScreen extends StatelessWidget {
  const VoiceToTextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VoiceToTextModelState>(
      create: (context) => VoiceToTextModelState(
        initialTranscript: const [
          'Tap',
          'the',
          'microphone',
          'and',
          'tell',
          'your',
          'AI',
          'Chief',
          'of',
          'Staff',
          'what',
          'to',
          'do',
          '—',
          'send',
          'a',
          'Slack',
          'message,',
          'draft',
          'an',
          'email,',
          'check',
          'the',
          'calendar,',
          'or',
          'follow',
          'up',
          'for',
          'you.',
        ],
        initialActiveWordIndex: 0,
        initialCursorVisible: false,
        audio: context.read<AudioCaptureService>(),
        speech: context.read<SpeechRecognitionService>(),
      ),
      child: const _VoiceToTextView(),
    );
  }
}

class _VoiceToTextView extends StatefulWidget {
  const _VoiceToTextView();

  @override
  State<_VoiceToTextView> createState() => _VoiceToTextViewState();
}

class _VoiceToTextViewState extends State<_VoiceToTextView> {
  String? _shownError;

  @override
  void initState() {
    super.initState();
    // No-op: Real waveform is driven by audio amplitude when recording (issue #7)
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VoiceToTextModelState model = context.watch<VoiceToTextModelState>();

    // Report new errors softly via SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final err = model.lastError;
      if (err != null && err != _shownError && mounted) {
        _shownError = err;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    });

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 227, 227, 198),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: TextDisplayWidget(
                transcript: model.transcript,
                activeWordIndex: model.activeWordIndex,
                isCursorVisible: model.isCursorVisible,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: WaveformStream(
                      stream: model.waveformStream,
                      initialAmplitudes: model.waveformData,
                      height: 220,
                      barColor: Colors.black87,
                      barWidth: 3,
                      spacing: 6,
                      backgroundColor: Colors.transparent,
                      minBarHeight: 2,
                    ),
                  ),
                ),
              ),
            ),
            TimerDisplay(duration: model.elapsedDuration),
            ControlButtonsRow(
              state: model.recordingState,
              onMicTap: () => _handleMicTap(model),
              onPause: model.pauseRecording,
              onResume: model.resumeRecording,
              onDiscard: model.discardRecording,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _handleMicTap(VoiceToTextModelState model) {
    switch (model.recordingState) {
      case RecordingState.idle:
      case RecordingState.stopped:
        model.startRecording();
        break;
      case RecordingState.recording:
        model.stopRecording();
        break;
      case RecordingState.paused:
        model.stopRecording();
        break;
    }
  }
}
