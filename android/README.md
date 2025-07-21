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