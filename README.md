# iva_mobile

Voice-to-text mobile client built with Flutter.

## Getting Started

### Dependencies

Audio and speech dependencies live in `pubspec.yaml`:

- `record` – microphone capture and amplitude stream.
- `speech_to_text` – on-device speech recognition with partial results.
- `provider` – MVVM state injection.

### Platform permissions

- Android: `android/app/src/main/AndroidManifest.xml` declares
  `android.permission.RECORD_AUDIO`.
- iOS: `ios/Runner/Info.plist` includes `NSMicrophoneUsageDescription` and
  `NSSpeechRecognitionUsageDescription` strings.

### Run locally

```
flutter pub get
flutter run
```

The app boots to the voice screen. Tap the microphone to request permission and
start recording. The waveform animates from live amplitude data and the
transcription updates as speech is recognized.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
