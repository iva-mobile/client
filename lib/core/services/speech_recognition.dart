import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

abstract class SpeechRecognitionService {
  Future<bool> initialize();
  Future<void> startListening({bool partialResults = true});
  Future<void> stopListening();
  Future<void> cancel();
  Stream<String> get transcriptionStream; // incremental text
}

class SpeechRecognitionServiceImpl implements SpeechRecognitionService {
  SpeechRecognitionServiceImpl({stt.SpeechToText? engine})
    : _engine = engine ?? stt.SpeechToText();

  final stt.SpeechToText _engine;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool _initialized = false;
  String? _localeId;

  @override
  Stream<String> get transcriptionStream => _controller.stream;

  @override
  Future<bool> initialize() async {
    final available = await _engine.initialize(
      onStatus: (_) {},
      onError: (e) {},
    );
    _initialized = available;
    if (available) {
      try {
        final sys = await _engine.systemLocale();
        _localeId = sys?.localeId;
      } catch (_) {
        _localeId = null;
      }
    }
    return available;
  }

  @override
  Future<void> startListening({bool partialResults = true}) async {
    if (!_engine.isAvailable || !_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }
    await _engine.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        if (text.isEmpty) return;
        if (!_controller.isClosed) _controller.add(text);
      },
      localeId: _localeId,
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: partialResults,
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    if (_engine.isListening) {
      await _engine.stop();
    }
  }

  @override
  Future<void> cancel() async {
    if (_engine.isListening) {
      await _engine.cancel();
    }
  }

  void dispose() {
    _controller.close();
  }
}
