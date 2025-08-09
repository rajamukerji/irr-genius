# IRR Genius - Android

Native Android application built with Kotlin and Jetpack Compose for calculating Internal Rate of Return and related financial metrics.

## 📱 Requirements

- **Android**: API 26 (Android 8.0) or later
- **Android Studio**: Hedgehog (2023.1.1) or later
- **Kotlin**: 1.9.20 or later
- **Gradle**: 8.2 or later
- **Java**: Compatible with Java 8+ (Note: Java 24 requires special configuration)

## 🚀 Getting Started

### Java 24 Compatibility Note
If using Java 24, the project is configured for Java 1.8 target compatibility. Unit tests may fail due to Robolectric compatibility issues, but the app builds and runs correctly.

### Building and Running
```bash
# Build the project (compilation only, skip tests if using Java 24)
./gradlew build -x test

# Build APK only (recommended for Java 24)
./gradlew assembleDebug

# Install on connected device
./gradlew installDebug
```

### Running Tests
```bash
# Unit tests (may fail on Java 24 due to Robolectric compatibility)
./gradlew test

# Instrumented tests  
./gradlew connectedAndroidTest
```

### Troubleshooting Java 24 Issues
If you encounter build issues with Java 24:
1. The project is configured with Java 1.8 target compatibility
2. Use `./gradlew assembleDebug` instead of `./gradlew build` to skip tests
3. Unit tests fail due to Robolectric framework compatibility, but app compilation works fine

### Linting & Formatting
```bash
# Auto-format Kotlin before build (wired to preBuild)
./gradlew ktlintFormat

# Static check (wired to check)
./gradlew ktlintCheck
```
Requires `ktlint` installed locally (e.g., `brew install ktlint`). The `preBuild` task will run `ktlintFormat` automatically when available.

## 🏛️ Architecture

- **MVVM Pattern** with Jetpack Compose
- **Hilt** for dependency injection
- **StateFlow** for reactive state management
- **Material 3** design system

## 📊 Features

Complete feature parity with iOS version:
- All 4 calculation modes
- Interactive charts with Vico
- Follow-on investment management
- Real-time input formatting
- Dark theme support

## 📚 Documentation

See [main README](../README.md) for complete documentation and feature details.

## 🤝 Contributing to Android

### Contributor Checklist
- [ ] Branch from `main`; use Conventional Commits (e.g., `feat:`, `fix:`, `docs:`).
- [ ] Build succeeds with Java 8+ (`./gradlew assembleDebug`) and app runs on API 26 and latest emulator.
- [ ] Tests pass: `./gradlew test` (note: may fail on Java 24 due to Robolectric compatibility).
- [ ] Verify light/dark theme and basic accessibility labels/content descriptions.
- [ ] Apply Android Studio formatting and idiomatic Kotlin/Compose patterns.
- [ ] No keystores, API keys, or secrets committed; keep local configs out of VCS.
- [ ] For UI changes, include before/after screenshots and a brief test plan in the PR.
