import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:iva_mobile/core/services/audio_capture.dart';
import 'package:iva_mobile/core/services/speech_recognition.dart';

abstract class VoiceToTextModel extends Listenable {
  List<String> get transcript; // tokenized words/segments for display
  String get transcribedText;
  int get activeWordIndex;
  bool get isCursorVisible;
  List<double> get waveformData;
  Stream<List<double>> get waveformStream;
  Duration get elapsedDuration;
  bool get isTimerRunning;
  RecordingState get recordingState;

  void setActiveWord(int index);
  void toggleCursorVisibility(bool visible);
  void updateTranscription(String text, {int? activeWordIndex});
  void updateWaveform(List<double> amplitudes);
  void startTimer();
  void pauseTimer();
  void resetTimer();
  void startRecording();
  void pauseRecording();
  void resumeRecording();
  void stopRecording();
  void restartRecording();
  void discardRecording();
}

enum RecordingState { idle, recording, paused, stopped }

class VoiceToTextModelState extends ChangeNotifier implements VoiceToTextModel {
  VoiceToTextModelState({
    List<String> initialTranscript = const [],
    int initialActiveWordIndex = 0,
    bool initialCursorVisible = true,
    RecordingState initialRecordingState = RecordingState.idle,
    this.audio,
    this.speech,
    int waveformWindow = 48,
  }) : _transcriptWords = List<String>.from(initialTranscript),
       _activeWordIndex = 0,
       _isCursorVisible = initialCursorVisible,
       _recordingState = initialRecordingState,
       _waveformWindowSize = waveformWindow {
    _activeWordIndex = _normalizeActiveIndex(initialActiveWordIndex);
    _seedAmplitudeWindow();
  }

  final AudioCaptureService? audio;
  final SpeechRecognitionService? speech;
  List<String> _transcriptWords;
  int _activeWordIndex;
  bool _isCursorVisible;
  List<double> _waveformData = const [];
  final StreamController<List<double>> _waveformController =
      StreamController<List<double>>.broadcast();
  Duration _elapsedDuration = Duration.zero;
  bool _isTimerRunning = false;
  Timer? _timer;
  RecordingState _recordingState;
  StreamSubscription<double>? _ampSub;
  StreamSubscription<String>? _sttSub;
  final List<double> _amplitudeWindow = <double>[];
  final int _waveformWindowSize;
  String? _lastError;
  static const bool _logTranscription = false;
  // No mock fallback: live amplitude must be provided by platform service

  @override
  List<String> get transcript => UnmodifiableListView(_transcriptWords);

  @override
  String get transcribedText => _transcriptWords.join(' ');

  @override
  int get activeWordIndex => _activeWordIndex;

  @override
  bool get isCursorVisible => _isCursorVisible;

  @override
  List<double> get waveformData => UnmodifiableListView(_waveformData);

  @override
  Stream<List<double>> get waveformStream => _waveformController.stream;

  @override
  Duration get elapsedDuration => _elapsedDuration;

  @override
  bool get isTimerRunning => _isTimerRunning;

  @override
  RecordingState get recordingState => _recordingState;

  String? get lastError => _lastError;

  @override
  void setActiveWord(int index) {
    final normalized = _normalizeActiveIndex(index);
    if (normalized == _activeWordIndex) return;
    _activeWordIndex = normalized;
    notifyListeners();
  }

  @override
  void toggleCursorVisibility(bool visible) {
    if (_isCursorVisible == visible) return;
    _isCursorVisible = visible;
    notifyListeners();
  }

  @override
  void updateTranscription(String text, {int? activeWordIndex}) {
    final words = _normalizeTranscript(text);
    final changed = _applyTranscription(words, activeWordIndex);
    if (_logTranscription && kDebugMode) {
      final preview = text.length > 120 ? '${text.substring(0, 120)}…' : text;
      // ignore: avoid_print
      print('[VM] transcription update: "$preview" (words=${words.length})');
    }
    if (changed) {
      notifyListeners();
    }
  }

  @override
  void updateWaveform(List<double> amplitudes) {
    final normalized = amplitudes
        .map((value) => value.isNaN ? 0.0 : value.clamp(0.0, 1.0))
        .toList(growable: false);
    final changed = !listEquals(normalized, _waveformData);
    _waveformData = List.unmodifiable(normalized);
    if (!_waveformController.isClosed) {
      _waveformController.add(_waveformData);
    }
    if (changed) {
      notifyListeners();
    }
  }

  @override
  void startTimer() {
    _startTimer();
  }

  @override
  void pauseTimer() {
    _pauseTimer();
  }

  @override
  void resetTimer() {
    _resetTimer();
  }

  @override
  void startRecording() {
    // Clear onboarding text so the transcript area streams fresh speech
    _applyTranscription(const [], 0);
    toggleCursorVisibility(true);
    _beginRecording();
  }

  @override
  void pauseRecording() {
    if (_recordingState != RecordingState.recording) return;
    _recordingState = RecordingState.paused;
    _pauseTimer(notify: false);
    audio?.pause();
    speech?.stopListening();
    toggleCursorVisibility(false);
    notifyListeners();
  }

  @override
  void resumeRecording() {
    if (_recordingState != RecordingState.paused) return;
    _recordingState = RecordingState.recording;
    _startTimer(notify: false);
    // Avoid mic contention: rely on speech sound levels while recording
    speech?.startListening(partialResults: true);
    toggleCursorVisibility(true);
    notifyListeners();
  }

  @override
  void stopRecording() {
    if (_recordingState == RecordingState.stopped) return;
    _recordingState = RecordingState.stopped;
    _resetTimer(notify: false);
    _teardownStreams();
    speech?.stopListening();
    toggleCursorVisibility(false);
    notifyListeners();
  }

  @override
  void restartRecording() {
    _applyTranscription(const [], 0);
    _seedAmplitudeWindow();
    _resetTimer(notify: false);
    _recordingState = RecordingState.recording;
    _startTimer(notify: false);
    _setupStreams();
    speech?.startListening(partialResults: true);
    toggleCursorVisibility(true);
    notifyListeners();
  }

  @override
  void discardRecording() {
    final transcriptChanged = _applyTranscription(const [], 0);
    _seedAmplitudeWindow();
    final timerChanged = _resetTimer(notify: false);
    _teardownStreams();
    speech?.cancel();
    final previousState = _recordingState;
    _recordingState = RecordingState.idle;
    toggleCursorVisibility(false);
    if (transcriptChanged ||
        timerChanged ||
        previousState != RecordingState.idle) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformController.close();
    _teardownStreams();
    super.dispose();
  }

  Future<void> _beginRecording() async {
    if (_recordingState == RecordingState.recording) {
      _startTimer(notify: false);
      return;
    }
    if (audio != null) {
      final status = await audio!.ensurePermission();
      if (status != AudioPermissionStatus.granted) {
        _lastError = 'Microphone permission is required to record';
        notifyListeners();
        return;
      }
    }
    _recordingState = RecordingState.recording;
    _startTimer(notify: false);
    _setupStreams();
    await speech?.startListening(partialResults: true);
    // Web implementation uses getUserMedia; on unsupported env, ensurePermission returns denied
    notifyListeners();
  }

  void _setupStreams() {
    _teardownStreams();
    if (audio != null) {
      _ampSub = audio!.amplitudeStream.listen(_pushAmplitude);
    }
    if (speech != null) {
      _sttSub = speech!.transcriptionStream.listen((text) {
        updateTranscription(text);
      });
    }
  }

  void _teardownStreams() {
    _ampSub?.cancel();
    _sttSub?.cancel();
    _ampSub = null;
    _sttSub = null;
    _amplitudeWindow.clear();
  }

  void _pushAmplitude(double level) {
    _amplitudeWindow.add(level.clamp(0.0, 1.0));
    if (_amplitudeWindow.length > _waveformWindowSize) {
      _amplitudeWindow.removeAt(0);
    }
    updateWaveform(List<double>.from(_amplitudeWindow));
  }

  void _seedAmplitudeWindow() {
    _amplitudeWindow
      ..clear()
      ..addAll(List<double>.filled(_waveformWindowSize, 0.0));
    updateWaveform(List<double>.from(_amplitudeWindow));
  }

  // No mock amplitude functions

  bool _applyTranscription(List<String> words, int? activeWordIndex) {
    final normalizedWords = List<String>.from(words);
    final normalizedIndex = _normalizeActiveIndex(
      activeWordIndex,
      wordCount: normalizedWords.length,
    );
    final wordsChanged = !listEquals(normalizedWords, _transcriptWords);
    final indexChanged = normalizedIndex != _activeWordIndex;
    if (!wordsChanged && !indexChanged) {
      return false;
    }
    _transcriptWords = normalizedWords;
    _activeWordIndex = normalizedIndex;
    return true;
  }

  bool _startTimer({bool notify = true}) {
    if (_isTimerRunning) return false;
    _isTimerRunning = true;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedDuration += const Duration(seconds: 1);
      notifyListeners();
    });
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  bool _pauseTimer({bool notify = true}) {
    if (!_isTimerRunning && _timer == null) return false;
    _isTimerRunning = false;
    _timer?.cancel();
    _timer = null;
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  bool _resetTimer({bool notify = true}) {
    final hadElapsed = _elapsedDuration != Duration.zero;
    final wasRunning = _isTimerRunning || _timer != null;
    if (!hadElapsed && !wasRunning) {
      return false;
    }
    _elapsedDuration = Duration.zero;
    if (wasRunning) {
      _timer?.cancel();
      _timer = null;
      _isTimerRunning = false;
    }
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  int _normalizeActiveIndex(int? index, {int? wordCount}) {
    final total = wordCount ?? _transcriptWords.length;
    if (total == 0) {
      return 0;
    }
    final desired = index ?? (total - 1);
    if (desired <= 0) {
      return 0;
    }
    if (desired >= total) {
      return total - 1;
    }
    return desired;
  }

  List<String> _normalizeTranscript(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
  }
}
