import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widget/text_display.dart';
import '../widget/waveform.dart';
import 'voice_to_text_model.dart';

class VoiceToTextScreen extends StatelessWidget {
  const VoiceToTextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VoiceToTextModelState>(
      create: (_) => VoiceToTextModelState(
        initialTranscript: const [
          'Herman',
          'is',
          'just',
          'like',
          'the',
          'rest',
          'of',
          'us.',
          'Everyday',
          'he',
          'has',
          'to',
          'make',
          'all',
          'kin',
        ],
        initialActiveWordIndex: 14,
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
  static const int _waveformSampleCount = 48;
  static const Duration _waveformTick = Duration(milliseconds: 100);

  final math.Random _random = math.Random();
  Timer? _waveformTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = context.read<VoiceToTextModelState>();
      _pushWaveformSample(model);
      _waveformTimer = Timer.periodic(
        _waveformTick,
        (_) => _pushWaveformSample(model),
      );
    });
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    super.dispose();
  }

  void _pushWaveformSample(VoiceToTextModel model) {
    final sample = List<double>.generate(_waveformSampleCount, (index) {
      final variance = math.sin(index / 4) * 0.3 + 0.5;
      final noise = (_random.nextDouble() - 0.5) * 0.2;
      return (variance + noise).clamp(0.0, 1.0);
    });
    model.updateWaveform(sample);
  }

  @override
  Widget build(BuildContext context) {
    final VoiceToTextModelState model = context.watch<VoiceToTextModelState>();

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
                child: WaveformStream(
                  stream: model.waveformStream,
                  initialAmplitudes: model.waveformData,
                  height: 220,
                  barColor: Colors.black87,
                  barWidth: 3,
                  spacing: 6,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
