import 'dart:async';

import 'package:flutter/material.dart';

abstract class VoiceToTextModel extends Listenable {
  List<String> get transcript; // already tokenized words or segments
  int get activeWordIndex;
  bool get isCursorVisible;
  List<double> get waveformData;
  Stream<List<double>> get waveformStream;
  Duration get elapsedDuration;
  bool get isTimerRunning;
  RecordingState get recordingState;

  void setActiveWord(int index);
  void toggleCursorVisibility(bool visible);
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

  // Other state already planned (timer, waveform, recording commands) lives here too.
}

enum RecordingState { idle, recording, paused, stopped }

class VoiceToTextModelState extends ChangeNotifier implements VoiceToTextModel {
  VoiceToTextModelState({
    required List<String> initialTranscript,
    int initialActiveWordIndex = 0,
    bool initialCursorVisible = true,
    RecordingState initialRecordingState = RecordingState.idle,
  }) : _transcript = List.unmodifiable(initialTranscript),
       _activeWordIndex = initialActiveWordIndex,
       _isCursorVisible = initialCursorVisible,
       _recordingState = initialRecordingState;

  final List<String> _transcript;
  int _activeWordIndex;
  bool _isCursorVisible;
  List<double> _waveformData = const [];
  final StreamController<List<double>> _waveformController =
      StreamController<List<double>>.broadcast();
  Duration _elapsedDuration = Duration.zero;
  bool _isTimerRunning = false;
  Timer? _timer;
  RecordingState _recordingState;

  @override
  List<String> get transcript => _transcript;

  @override
  int get activeWordIndex => _activeWordIndex;

  @override
  bool get isCursorVisible => _isCursorVisible;

  @override
  List<double> get waveformData => _waveformData;

  @override
  Stream<List<double>> get waveformStream => _waveformController.stream;

  @override
  Duration get elapsedDuration => _elapsedDuration;

  @override
  bool get isTimerRunning => _isTimerRunning;

  @override
  RecordingState get recordingState => _recordingState;

  @override
  void setActiveWord(int index) {
    if (index == _activeWordIndex) return;
    if (index < 0 || index >= _transcript.length) return;
    _activeWordIndex = index;
    notifyListeners();
  }

  @override
  void toggleCursorVisibility(bool visible) {
    if (_isCursorVisible == visible) return;
    _isCursorVisible = visible;
    notifyListeners();
  }

  @override
  void updateWaveform(List<double> amplitudes) {
    _waveformData = List.unmodifiable(amplitudes);
    notifyListeners();
    if (!_waveformController.isClosed) {
      _waveformController.add(_waveformData);
    }
  }

  @override
  void startTimer() {
    if (_isTimerRunning) return;
    _isTimerRunning = true;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedDuration += const Duration(seconds: 1);
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void pauseTimer() {
    if (!_isTimerRunning && _timer == null) return;
    _isTimerRunning = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void resetTimer() {
    final hadElapsed = _elapsedDuration != Duration.zero;
    final wasRunning = _isTimerRunning || _timer != null;
    _elapsedDuration = Duration.zero;
    if (wasRunning) {
      _timer?.cancel();
      _timer = null;
      _isTimerRunning = false;
    }
    if (hadElapsed || wasRunning) {
      notifyListeners();
    }
  }

  @override
  void startRecording() {
    if (_recordingState == RecordingState.recording) return;
    _recordingState = RecordingState.recording;
    startTimer();
    notifyListeners();
  }

  @override
  void pauseRecording() {
    if (_recordingState != RecordingState.recording) return;
    _recordingState = RecordingState.paused;
    pauseTimer();
    notifyListeners();
  }

  @override
  void resumeRecording() {
    if (_recordingState != RecordingState.paused) return;
    _recordingState = RecordingState.recording;
    startTimer();
    notifyListeners();
  }

  @override
  void stopRecording() {
    if (_recordingState == RecordingState.stopped) return;
    _recordingState = RecordingState.stopped;
    resetTimer();
    notifyListeners();
  }

  @override
  void restartRecording() {
    _recordingState = RecordingState.recording;
    resetTimer();
    startTimer();
    notifyListeners();
  }

  @override
  void discardRecording() {
    _recordingState = RecordingState.idle;
    _waveformData = const [];
    if (!_waveformController.isClosed) {
      _waveformController.add(_waveformData);
    }
    resetTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformController.close();
    super.dispose();
  }
}
