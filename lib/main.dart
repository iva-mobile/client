import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/audio_capture.dart';
import 'core/services/speech_recognition.dart';
import 'features/voice_to_text/view/voice_to_text_screen.dart';

void main() {
  runApp(const VoiceToTextApp());
}

class VoiceToTextApp extends StatelessWidget {
  const VoiceToTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioCaptureService>(create: (_) => AudioCaptureServiceImpl()),
        Provider<SpeechRecognitionService>(
          create: (_) => SpeechRecognitionServiceImpl(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'IVA Voice',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black87),
          scaffoldBackgroundColor: const Color(0xFFE3E3C6),
          useMaterial3: true,
        ),
        home: const VoiceToTextScreen(),
      ),
    );
  }
}
