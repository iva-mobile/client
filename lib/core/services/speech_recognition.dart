import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

abstract class SpeechRecognitionService {
  Future<bool> initialize();
  Future<void> startListening({bool partialResults = true});
  Future<void> stopListening();
  Future<void> cancel();
  Stream<String> get transcriptionStream; // incremental text
  Stream<double> get levelStream; // normalized sound level 0..1
}

class SpeechRecognitionServiceImpl implements SpeechRecognitionService {
  SpeechRecognitionServiceImpl({stt.SpeechToText? engine})
    : _engine = engine ?? stt.SpeechToText();

  static const bool _log = false;
  final stt.SpeechToText _engine;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool _initialized = false;
  String? _localeId;
  bool _keepAlive = false;
  final StreamController<double> _levelController =
      StreamController<double>.broadcast();
  Timer? _restartTimer;
  int _backoffMs = 300;
  static const int _maxBackoffMs = 3000;
  Set<String> _availableLocales = const {};

  @override
  Stream<String> get transcriptionStream => _controller.stream;
  @override
  Stream<double> get levelStream => _levelController.stream;

  @override
  Future<bool> initialize() async {
    final available = await _engine.initialize(
      onStatus: (status) {
        if (_log && kDebugMode) {
          // ignore: avoid_print
          print('[STT] status: $status');
        }
        if (_keepAlive) {
          if (status == 'listening') {
            _cancelRestartTimer();
            _resetBackoff();
          } else if (status == 'notListening' ||
              status == 'done' ||
              status == 'doneNoResult') {
            _scheduleRestart('status:$status');
          }
        }
      },
      onError: (e) {
        if (_log && kDebugMode) {
          // ignore: avoid_print
          print('[STT] error: ${e.errorMsg} permanent=${e.permanent}');
        }
        if (!_keepAlive) return;
        if (e.errorMsg == 'error_language_unavailable') {
          _chooseSupportedLocale(fallback: true);
          _increaseBackoff();
          _scheduleRestart('language_unavailable');
        } else if (e.errorMsg == 'error_busy' || e.errorMsg == 'error_client') {
          _increaseBackoff();
          _scheduleRestart(e.errorMsg);
        }
      },
      debugLogging: false,
    );
    _initialized = available;
    if (available) {
      try {
        final sys = await _engine.systemLocale();
        _localeId = sys?.localeId;
        final locales = await _engine.locales();
        _availableLocales = locales.map((l) => l.localeId).toSet();
        _chooseSupportedLocale();
      } catch (_) {
        _localeId = null;
      }
      if (_log && kDebugMode) {
        // ignore: avoid_print
        print('[STT] initialized. locale=$_localeId available=$available');
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
    _keepAlive = true;
    if (_log && kDebugMode) {
      // ignore: avoid_print
      print('[STT] startListening partial=$partialResults locale=$_localeId');
    }
    _startEngineListen(partialResults: partialResults);
  }

  @override
  Future<void> stopListening() async {
    _keepAlive = false;
    _cancelRestartTimer();
    _resetBackoff();
    if (_engine.isListening) {
      await _engine.stop();
    }
  }

  @override
  Future<void> cancel() async {
    _keepAlive = false;
    _cancelRestartTimer();
    _resetBackoff();
    if (_engine.isListening) {
      await _engine.cancel();
    }
  }

  void _startEngineListen({required bool partialResults}) {
    if (_engine.isListening) return;
    _engine.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        if (text.isEmpty) return;
        if (kDebugMode) {
          // ignore: avoid_print
          print('[STT] onResult final=${result.finalResult} text="$text"');
        }
        if (!_controller.isClosed) _controller.add(text);
      },
      onSoundLevelChange: (level) {
        // Typical Android range observed: [-2.0, 10.0]. Map to [0,1].
        const minDb = -2.0;
        const maxDb = 10.0;
        final normalized = ((level - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
        if (!_levelController.isClosed) {
          _levelController.add(normalized.toDouble());
        }
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

  void _scheduleRestart(String reason) {
    if (!_keepAlive) return;
    if (_restartTimer != null) return;
    if (_engine.isListening) return;
    final delay = Duration(milliseconds: _backoffMs);
    if (_log && kDebugMode) {
      // ignore: avoid_print
      print('[STT] schedule restart in ${delay.inMilliseconds}ms ($reason)');
    }
    _restartTimer = Timer(delay, () {
      _restartTimer = null;
      if (!_keepAlive || _engine.isListening) return;
      _startEngineListen(partialResults: true);
    });
  }

  void _cancelRestartTimer() {
    _restartTimer?.cancel();
    _restartTimer = null;
  }

  void _resetBackoff() {
    _backoffMs = 300;
  }

  void _increaseBackoff() {
    _backoffMs = _backoffMs * 2;
    if (_backoffMs > _maxBackoffMs) _backoffMs = _maxBackoffMs;
  }

  void _chooseSupportedLocale({bool fallback = false}) {
    if (_availableLocales.isEmpty) return;
    if (_localeId != null && _availableLocales.contains(_localeId)) return;
    // Prefer en_US when present, else first available.
    if (_availableLocales.contains('en_US')) {
      _localeId = 'en_US';
    } else {
      _localeId = _availableLocales.first;
    }
    if (_log && kDebugMode) {
      // ignore: avoid_print
      print('[STT] using supported locale=$_localeId (fallback=$fallback)');
    }
  }

  void dispose() {
    _controller.close();
  }
}
