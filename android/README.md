# IRR Genius - Android

Native Android application built with Kotlin and Jetpack Compose for calculating Internal Rate of Return and related financial metrics.

## 📱 Requirements

- **Android**: API 26 (Android 8.0) or later
- **Android Studio**: Hedgehog (2023.1.1) or later
- **Kotlin**: 1.9.20 or later
- **Gradle**: 8.2 or later

## 🚀 Getting Started

### Building and Running
```bash
# Build the project
./gradlew build

# Install on connected device
./gradlew installDebug
```

### Running Tests
```bash
# Unit tests
./gradlew test

# Instrumented tests  
./gradlew connectedAndroidTest
```

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
- [ ] Build succeeds with Java 17+ (`./gradlew build`) and app runs on API 26 and latest emulator.
- [ ] Tests pass: `./gradlew test` and, when applicable, `./gradlew connectedAndroidTest`.
- [ ] Verify light/dark theme and basic accessibility labels/content descriptions.
- [ ] Apply Android Studio formatting and idiomatic Kotlin/Compose patterns.
- [ ] No keystores, API keys, or secrets committed; keep local configs out of VCS.
- [ ] For UI changes, include before/after screenshots and a brief test plan in the PR.
