# glow

Flutter app showcasing [Breez SDK - Spark)](https://sdk-doc-spark.breez.technology/).

## Setup

Install dependencies:
```bash
flutter pub get
```

Generate code and mocks:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Create `secrets.json` in project root (gitignored):
```json
{
  "BREEZ_API_KEY": "your_api_key"
}
```

## Running

Development build:
```bash
flutter run --dart-define-from-file=secrets.json
```

Production build:
```bash
flutter run --dart-define-from-file=secrets.json --release
```

## Testing

Unit tests:
```bash
flutter test
```

Integration tests (requires device/emulator):
```bash
flutter test integration_test
```

## Building

Development:
```bash
flutter build apk --dart-define-from-file=secrets.json
flutter build ios --dart-define-from-file=secrets.json
```

Production:
```bash
flutter build apk --dart-define-from-file=secrets.json --release
flutter build ios --dart-define-from-file=secrets.json --release
```
