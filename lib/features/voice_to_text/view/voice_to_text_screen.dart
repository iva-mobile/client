import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widget/text_display.dart';
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

class _VoiceToTextView extends StatelessWidget {
  const _VoiceToTextView();

  @override
  Widget build(BuildContext context) {
    final VoiceToTextModel model = context.watch<VoiceToTextModelState>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 227, 227, 198),
      body: SafeArea(
        child: TextDisplayWidget(
          transcript: model.transcript,
          activeWordIndex: model.activeWordIndex,
          isCursorVisible: model.isCursorVisible,
        ),
      ),
    );
  }
}
