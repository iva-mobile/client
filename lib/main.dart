import 'package:flutter/material.dart';

import 'features/voice_to_text/view/voice_to_text_screen.dart';

void main() {
  runApp(const VoiceToTextApp());
}

class VoiceToTextApp extends StatelessWidget {
  const VoiceToTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IVA Voice',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black87),
        scaffoldBackgroundColor: const Color(0xFFE3E3C6),
        useMaterial3: true,
      ),
      home: const VoiceToTextScreen(),
    );
  }
}
