import 'package:flutter/material.dart';

abstract class VoiceToTextModel extends Listenable {
  List<String> get transcript; // already tokenized words or segments
  int get activeWordIndex;
  bool get isCursorVisible;

  void setActiveWord(int index);
  void toggleCursorVisibility(bool visible);

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

  @override
  List<String> get transcript => _transcript;

  @override
  int get activeWordIndex => _activeWordIndex;

  @override
  bool get isCursorVisible => _isCursorVisible;

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
}
