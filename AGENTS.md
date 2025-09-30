# Repository Guidelines

## Project Structure & Module Organization

- `lib/` holds app code; features live under `lib/features/<feature>/` with `view`, `viewmodel`, `widget`, and `models` folders following MVVM. Core-wide utilities will eventually sit under `lib/core/`.
- `test/` mirrors the feature layout (`test/features/voice_to_text/...`) for unit and widget coverage. Keep test helpers close to the code they exercise.
- Platform scaffolding resides in the standard `android/`, `ios/`, `web/`, and desktop directories. Treat these as generated unless platform work is assigned.

## Build, Test, and Development Commands

- `flutter pub get` — sync dependencies declared in `pubspec.yaml`.
- `flutter run` — launch the app using current configuration; defaults to `VoiceToTextScreen`.
- `flutter test` — execute all unit and widget tests; use `flutter test test/features/...` for targeted suites.

## Coding Style & Naming Conventions

- Follow Dart style: 2-space indentation, `lowerCamelCase` for variables/methods, `UpperCamelCase` for types, and `snake_case.dart` filenames.
- Widgets and view models live in dedicated files named after the class (`text_display.dart`, `voice_to_text_model.dart`).
- Rely on Flutter’s formatter: `dart format .` or the IDE’s auto-format on save. Static analysis is enforced via `analysis_options.yaml`; resolve its warnings before committing.

## Testing Guidelines

- Write unit tests for view models and pure logic; use `flutter_test` for widget layout/animation checks (see `waveform_test.dart`).
- Name tests descriptively using `group` + `testWidgets`/`test`; prefer arranging inputs/expectations inline for readability.
- Ensure new features extend the mirrored directory structure in `test/` and run `flutter test` before pushing.

## Commit & Pull Request Guidelines

- Use commits conventions fix, tests, chore, feat, build, refactor
- Commits in history use short, imperative messages (`Add waveform visualization`). Keep them scoped to a single concern and ensure formatting/lints pass (`flutter analyze` runs pre-commit via tooling).
- Pull requests should:
  1. Reference the corresponding GitHub issue in the description (`Fixes #2`).
  2. Summarize functional changes plus any architectural notes (e.g., new providers).
  3. Include screenshots or screen recordings for UI changes when feasible.
  4. Confirm tests ran successfully (`flutter test`) and note any manual verification performed.

## Architecture Overview

- The app is converging on MVVM: views consume `VoiceToTextModelState`/future providers, while view models expose immutable state and notify listeners. New features should respect this separation and favor dependency injection for services.

## Tools

- ALWAYS use `gh` cli when interacting with github

## Code style

- Always follow the guidelines layout [here](https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md)
