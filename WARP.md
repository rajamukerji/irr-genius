# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

IRR Genius is a cross-platform Internal Rate of Return calculator built with native iOS (Swift/SwiftUI) and Android (Kotlin/Jetpack Compose) applications. The project features sophisticated financial calculations, data persistence, cloud synchronization, and comprehensive import/export capabilities.

## Essential Commands

### iOS Development
```bash
# Prerequisites (REQUIRED - build will fail without this)
brew install swiftformat

# Open project
cd ios && open "IRR Genius.xcodeproj"

# Build and run in Xcode
# Use ⌘+R or Product → Run

# Run tests 
# Use ⌘+U or Product → Test

# Format code manually
cd ios && swiftformat .
# OR use project-wide script:
./scripts/format-ios.sh
```

### Android Development
```bash
# Build and run checks
cd android && ./gradlew build

# Install debug build
./gradlew installDebug

# Run unit tests
./gradlew test

# Run instrumented tests
./gradlew connectedAndroidTest

# Format code (requires ktlint installed)
./gradlew ktlintFormat
# OR use project-wide script:
./scripts/format-android.sh

# Lint check
./gradlew ktlintCheck
```

### Cross-Platform Operations
```bash
# Format both platforms
./scripts/format-all.sh

# Set up git hooks (recommended)
./scripts/setup-hooks.sh

# Requirements check
java --version  # Need Java 17+ for Android
swift --version  # Need Swift 5.9+ for iOS
```

### Release Management
```bash
# Tag a new release
git pull origin main
git tag -a v1.0.0 -m "release: v1.0.0"  
git push origin v1.0.0

# This triggers CI workflows:
# - Android: uploads AAB to Play Internal Testing
# - iOS: uploads to TestFlight via Fastlane
```

## Architecture Overview

This is a dual-platform native application with **shared mathematical specifications** but **platform-specific implementations**.

### Platform Architecture

#### iOS (Swift/SwiftUI)
- **Architecture Pattern**: MVVM with SwiftUI state management and repository pattern
- **Data Persistence**: Core Data with async/await patterns, WAL mode, background contexts
- **Cloud Sync**: Full CloudKit integration with conflict resolution  
- **Navigation**: 4-tab TabView structure (Calculator, Saved, Projects, Settings)
- **Charts**: Native Swift Charts framework
- **Testing**: Swift Testing framework with Core Data and CloudKit test coverage
- **Requirements**: iOS 17.0+, macOS 14.0+, SwiftFormat (required for build)

#### Android (Kotlin/Compose)  
- **Architecture Pattern**: MVVM with StateFlow, Repository pattern, and Jetpack Compose
- **Data Persistence**: Room database with Kotlin coroutines and proper async patterns
- **Navigation**: Bottom navigation with Compose Navigation
- **Charts**: Custom Canvas-based charting implementation
- **Testing**: JUnit with Kotlin test extensions and Robolectric
- **Requirements**: Android API 26+, Java 17+, Gradle 8.0

### Data Models & Persistence

Both platforms implement identical calculation logic with platform-appropriate storage:

#### Core Data Models
- **SavedCalculation**: Stores all calculation types (IRR, Outcome, Initial, Blended, Portfolio Unit Investment)
- **Project**: Organizes calculations into logical groups
- **FollowOnInvestment**: Supports complex multi-stage investment scenarios
- **Portfolio Unit Investment**: Advanced portfolio calculations with success rates and unit tracking

#### Repository Pattern
Both platforms use repository abstraction for data access:
- `CalculationRepository`: CRUD operations for calculations
- `ProjectRepository`: Project management operations  
- Error handling with structured `RepositoryError` types
- Flow/Publisher-based reactive data streams

### Financial Calculation Engine

Mathematical consistency is maintained across platforms with identical formulas:
- **IRR**: `(FV/PV)^(1/n) - 1`
- **Future Value**: `PV × (1 + IRR)^n`  
- **Present Value**: `FV / (1 + IRR)^n`
- **Blended IRR**: Time-weighted money-weighted returns for follow-on investments
- **Portfolio Unit Investment**: Unit-based calculations with success rate modeling

## Key Services & Components

### iOS-Specific Services
- **CloudKitSyncService**: Full bidirectional sync with conflict resolution
- **CSVImportService** & **ExcelImportService**: Comprehensive data import with validation
- **PDFExportService**: Professional PDF generation with charts
- **ValidationService**: Real-time input validation with error severity levels
- **CoreDataStack**: Optimized Core Data configuration with background contexts

### Android-Specific Services
- **ValidationService**: Comprehensive field validation with severity levels
- **ErrorRecoveryService**: Graceful error handling and retry mechanisms
- **SharingService**: CSV/PDF export with native Android sharing
- **CloudSyncService**: Infrastructure for future cloud sync implementation

### Shared UI Components
Both platforms implement equivalent reusable components:
- **Input Fields**: Formatted currency/percentage inputs with validation
- **Chart Views**: Interactive growth visualization
- **Result Cards**: Consistent calculation result display
- **Mode Selectors**: Tab-style calculation mode switching

## Development Workflow

### Code Style & Formatting
- **Automatic Formatting**: Pre-commit hooks run SwiftFormat (iOS) and ktlint (Android)
- **Build Integration**: iOS build fails without SwiftFormat; Android auto-formats on build
- **Manual Formatting**: Use `./scripts/format-all.sh` or platform-specific scripts

### Testing Strategy
- **iOS**: Swift Testing with Core Data repository tests, CloudKit sync tests, import/export validation
- **Android**: JUnit with Room database tests, repository pattern tests, validation service tests
- **Mathematical Consistency**: Both platforms test against identical calculation scenarios
- **UI Testing**: Platform-specific UI tests for user interaction flows

### Git Workflow
- **Commit Messages**: Follow Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)
- **Hooks**: Run `./scripts/setup-hooks.sh` to enable pre-commit formatting and commit message validation
- **Branches**: Feature branches from `main`, squash merge for clean history

## CI/CD Pipeline

### Continuous Integration (`.github/workflows/ci.yml`)
- **Android Job**: Runs on Ubuntu, installs ktlint, executes `ktlintCheck`, `build`, `test`
- **iOS Job**: Runs on macOS-14, installs SwiftFormat, runs Xcode tests on iPhone 15 simulator
- **Triggers**: Push/PR to main, concurrent job cancellation for efficiency

### Release Pipeline (`.github/workflows/release.yml`)
- **Triggers**: Git tags matching `v*` pattern or manual workflow dispatch
- **Android**: Builds AAB, uploads to Play Internal Testing (requires `PLAY_JSON` secret)
- **iOS**: Runs Fastlane tests and beta lane, uploads to TestFlight (requires ASC API keys)
- **Artifacts**: Stores AAB files for manual distribution if needed

## Important Configuration Notes

### iOS CloudKit Requirements
- iCloud entitlements configured in project
- Requires signed Apple Developer account
- User must be signed into iCloud for sync to work
- Automatic conflict resolution using last-modified-wins strategy

### Android Build Requirements
- **Java Version**: 17+ (checked in CI and build scripts)
- **Gradle Version**: 8.0 with Android Gradle Plugin 8.1.4
- **Kotlin Version**: 1.9.20 with Compose BOM 2023.10.01
- **Min SDK**: 26 (Android 8.0) for broad compatibility

### Security & Privacy
- **Local-First Design**: All calculations performed locally with optional cloud sync
- **No Analytics**: No user behavior tracking or data collection
- **Input Sanitization**: All user inputs validated and sanitized
- **CloudKit Security**: iOS cloud sync uses Apple's encrypted infrastructure

## Common Development Tasks

### Adding New Calculation Types
1. Add enum case to `CalculationMode` in both platforms
2. Extend `SavedCalculation` model with required fields
3. Update database schema (Core Data model + Room migration)
4. Implement calculation logic in respective calculator services
5. Create UI components for the new calculation type
6. Add validation rules and tests

### Database Migrations
- **iOS**: Update Core Data model, add migration mapping model if needed
- **Android**: Increment database version, create `Migration` object in `AppDatabase`
- Test migrations thoroughly with existing data

### Adding New Import/Export Formats
1. Create format-specific service implementing common interface
2. Add file type handling in document picker/file browser
3. Update validation service for format-specific rules
4. Add UI for format selection and configuration
5. Write comprehensive tests for data integrity

### Performance Considerations
- **iOS**: Use background contexts for Core Data operations, implement efficient CloudKit queries
- **Android**: Utilize Room's async/await patterns, implement proper coroutine scoping
- **Charts**: Optimize data point rendering for large datasets
- **Memory**: Implement proper cleanup for large import operations

This documentation reflects the current state of a mature, production-ready cross-platform financial application with comprehensive data management, cloud sync, and professional export capabilities.
