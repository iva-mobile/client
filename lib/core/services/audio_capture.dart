import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum AudioPermissionStatus { granted, denied, restricted }

abstract class AudioCaptureService {
  Future<AudioPermissionStatus> ensurePermission();
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Stream<double> get amplitudeStream; // 0.0 to 1.0
}

class AudioCaptureServiceImpl implements AudioCaptureService {
  AudioCaptureServiceImpl({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final StreamController<double> _levelController =
      StreamController<double>.broadcast();
  StreamSubscription<Amplitude>? _subscription;

  @override
  Stream<double> get amplitudeStream => _levelController.stream;

  @override
  Future<AudioPermissionStatus> ensurePermission() async {
    final has = await _recorder.hasPermission();
    return has ? AudioPermissionStatus.granted : AudioPermissionStatus.denied;
  }

  @override
  Future<void> start() async {
    if (!await _recorder.isRecording()) {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/iva_rec_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: file.path,
      );
    }
    _subscription ??= _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
          final normalized = _normalizeDb(amp.current);
          if (!_levelController.isClosed) {
            _levelController.add(normalized);
          }
        });
  }

  @override
  Future<void> pause() async {
    if (await _recorder.isRecording()) {
      await _recorder.pause();
    }
  }

  @override
  Future<void> resume() async {
    if (await _recorder.isPaused()) {
      await _recorder.resume();
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _subscription?.cancel();
    } finally {
      _subscription = null;
    }
    if (await _recorder.isRecording() || await _recorder.isPaused()) {
      await _recorder.stop();
    }
  }

  double _normalizeDb(double db) {
    // Map [-45dB, 0dB] to [0, 1], clamp outside
    const minDb = -45.0;
    const maxDb = 0.0;
    final clamped = db.clamp(minDb, maxDb);
    return (clamped - minDb) / (maxDb - minDb);
  }

  @mustCallSuper
  void dispose() {
    _levelController.close();
    _subscription?.cancel();
  }
}
