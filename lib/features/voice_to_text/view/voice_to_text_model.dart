import 'dart:async';

import 'package:flutter/material.dart';

abstract class VoiceToTextModel extends Listenable {
  List<String> get transcript; // already tokenized words or segments
  int get activeWordIndex;
  bool get isCursorVisible;
  List<double> get waveformData;
  Stream<List<double>> get waveformStream;

  void setActiveWord(int index);
  void toggleCursorVisibility(bool visible);
  void updateWaveform(List<double> amplitudes);

  // Other state already planned (timer, waveform, recording commands) lives here too.
}

class VoiceToTextModelState extends ChangeNotifier implements VoiceToTextModel {
  VoiceToTextModelState({
    required List<String> initialTranscript,
    int initialActiveWordIndex = 0,
    bool initialCursorVisible = true,
  }) : _transcript = List.unmodifiable(initialTranscript),
       _activeWordIndex = initialActiveWordIndex,
       _isCursorVisible = initialCursorVisible;

  final List<String> _transcript;
  int _activeWordIndex;
  bool _isCursorVisible;
  List<double> _waveformData = const [];
  final StreamController<List<double>> _waveformController =
      StreamController<List<double>>.broadcast();

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
  void dispose() {
    _waveformController.close();
    super.dispose();
  }
}
