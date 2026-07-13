# AGENTS.md

Guidance for AI coding agents working in this repository.

## Scope

- Flutter mobile app in `lib/`.
- Firebase config in `firebase.json`, `firestore.indexes.json`, and generated `lib/firebase_options.dart`.
- Cloud Functions backend in `functions/` (Node 20).

## Fast Commands

Run from repository root unless noted.

- Install Flutter deps: `flutter pub get`
- Run app (debug): `flutter run`
- Analyze: `flutter analyze`
- Run tests: `flutter test`
- Build Android APK: `flutter build apk --release --split-per-abi`
- Build Android App Bundle: `flutter build appbundle --release`

Cloud Functions (run from `functions/`):

- Install deps: `npm install`
- Start emulator: `npm run serve`
- Deploy functions: `npm run deploy`

## Project Map

- App bootstrap and localization: `lib/main.dart`
- Shared code: `lib/core/`
  - Services: `lib/core/services/`
  - Models: `lib/core/models/`
  - Theme/constants/widgets: `lib/core/theme/`, `lib/core/constants/`, `lib/core/widgets/`
- Feature modules: `lib/features/`
- Functions backend: `functions/index.js`

## Non-Obvious Conventions

- App is Arabic-first and RTL by default (`ar-SA`, Directionality RTL).
- AI integration uses Anthropic in `lib/core/services/ai_service.dart`.
  - API key resolution order: `--dart-define=ANTHROPIC_API_KEY`, then `.env`, then Firebase Remote Config key `anthropic_api_key`.
  - Do not change `TAAMEEM_JSON_START` / `TAAMEEM_JSON_END` markers without updating all parsing call sites.
- Firestore queries and sort patterns in `lib/core/services/firestore_service.dart` depend on indexes in `firestore.indexes.json`.
  - If query shape changes, update indexes too.
- Notification function `notifyUsersByScope` is deployed in region `me-central1` (see `functions/index.js`). Keep region and data shape assumptions aligned with mobile writes.

## Pitfalls

- There are legacy/malformed duplicate folders: `lib/{core` and `lib/{features`.
  - Do not add new imports from brace-prefixed paths.
  - Prefer canonical paths under `lib/core` and `lib/features`.
- Repository includes generated/build outputs (`build/`, `.dart_tool/` artifacts may appear).
  - Avoid editing generated files unless task explicitly requires it.
- Secrets hygiene: never print or commit actual secret values from `.env`.

## Working Style For Agents

- Keep changes minimal and focused; preserve existing architecture and naming.
- Prefer fixing root causes over superficial UI-only patches.
- After code edits, run `flutter analyze` and relevant tests when possible.
- For backend-related edits, verify function runtime assumptions in `functions/README.md` and `functions/index.js`.

## Link-First Documentation

Use existing docs for details instead of duplicating long instructions:

- Project overview: [README.md](README.md)
- Local setup: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- Firebase setup: [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- AI setup: [AI_SETUP.md](AI_SETUP.md)
- Performance notes: [PERFORMANCE.md](PERFORMANCE.md)
- Publishing: [PUBLISHING_GUIDE.md](PUBLISHING_GUIDE.md)
- Functions details: [functions/README.md](functions/README.md)
