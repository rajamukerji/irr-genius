# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IRR Genius is a cross-platform Internal Rate of Return calculator with native iOS (Swift/SwiftUI) and Android (Kotlin/Jetpack Compose) applications. Both platforms have 100% feature parity and shared mathematical specifications.

## Project Structure

```
├── ios/                          # iOS application
├── android/                      # Android application  
└── shared/                       # Common documentation and specs
```

## Development Commands

### iOS Development
Navigate to `ios/` directory first:
```bash
cd ios/
```

- **Build**: Open in Xcode and press `⌘+B` or run `xcodebuild`
- **Run**: Press `⌘+R` in Xcode
- **Test**: Press `⌘+U` in Xcode (uses Swift Testing framework, not XCTest)
- **Clean**: Press `⌘+Shift+K` in Xcode
- **Open Project**: `open "IRR Genius.xcodeproj"`

### Android Development
Navigate to `android/` directory first:
```bash
cd android/
```

- **Build**: `./gradlew build` or open in Android Studio
- **Run**: `./gradlew installDebug` or run in Android Studio
- **Test**: `./gradlew test` (unit tests) or `./gradlew connectedAndroidTest` (instrumented)
- **Clean**: `./gradlew clean`
- **Open Project**: Open `android/` folder in Android Studio

## Architecture

Both platforms follow similar MVVM-like architecture with platform-specific implementations:

### iOS Architecture (Swift/SwiftUI)
```
ios/IRR Genius/
├── Models/              # Data models (FollowOnInvestment, GrowthPoint, enums)
├── Views/
│   ├── ContentView.swift        # Main coordinator that manages calculation modes
│   ├── Components/              # Reusable UI components (headers, inputs, charts)
│   ├── CalculationViews/        # Mode-specific views for each calculation type
│   └── FollowOnInvestment/      # Views for managing follow-on investments
├── Services/
│   └── IRRCalculator.swift      # Core business logic for all IRR calculations
└── Utilities/
    └── NumberFormatter.swift    # Shared formatting logic
```

### Android Architecture (Kotlin/Compose)
```
android/app/src/main/java/com/irrgenius/android/
├── data/models/         # Data classes and enums
├── domain/calculator/   # Business logic (IRRCalculator)
├── ui/
│   ├── components/      # Reusable Composable functions
│   ├── screens/         # Screen composables and ViewModel
│   └── theme/           # Material 3 theming
└── utils/               # Utility classes (NumberFormatter)
```

### Key Architectural Patterns

1. **State Management**: 
   - **iOS**: SwiftUI's `@State` for local state and `@Binding` for parent-child communication
   - **Android**: `StateFlow` in ViewModel with Jetpack Compose
2. **Separation of Concerns**: Business logic isolated in `IRRCalculator`, UI logic in views/composables
3. **Component-Based**: Each UI component has a single responsibility
4. **Calculation Modes**: Managed through `CalculationMode` enum with four modes:
   - `CALCULATE_IRR` - Calculate IRR from initial/final values
   - `CALCULATE_OUTCOME` - Calculate future value from IRR
   - `CALCULATE_INITIAL` - Calculate required initial investment
   - `CALCULATE_BLENDED` - Calculate blended IRR with follow-on investments

## Important Implementation Details

### IRR Calculation Logic (Shared Across Platforms)
- Core calculations use identical mathematical formulas on both platforms
- IRR is stored as decimal (0.15 = 15%) internally but displayed as percentage
- All monetary values use `Double` type  
- Years can be fractional (e.g., 2.5 years)
- Business logic is identical between iOS `IRRCalculator.swift` and Android `IRRCalculator.kt`

### Follow-On Investments
- Support for tag-along investments (follow main investment's IRR)
- Buy/Sell/Buy-Sell transaction types
- Custom valuation options
- **iOS**: Stored in `followOnInvestments` array in `ContentView`
- **Android**: Managed in `MainViewModel` state

### UI Patterns
- **iOS**: Real-time number formatting with `NumberFormatter.currencyFormatter`
- **Android**: Real-time formatting with `DecimalFormat` and custom `NumberFormatter` object
- Input validation with error messages in red/error color
- Loading states during calculations using `isCalculating` flag
- **iOS**: Charts use Swift Charts framework
- **Android**: Charts use Vico library

### Platform Support
- **iOS**: iOS 17.0+ and macOS 14.0+ (Universal app)
- **Android**: API 26+ (Android 8.0+), phones and tablets
- Both platforms support dark mode

## Testing

### iOS Testing
- Uses Swift Testing framework (not XCTest)
- Test calculations by comparing with known financial results
- Located in `ios/IRR GeniusTests/`

### Android Testing  
- Uses JUnit with Kotlin extensions
- Unit tests in `android/app/src/test/`
- Instrumented tests in `android/app/src/androidTest/`
- Test same calculations as iOS for consistency

### Shared Test Scenarios
Both platforms test identical scenarios defined in `shared/specs/CALCULATIONS.md`:
- Basic IRR: $100 → $150 in 2 years = 22.47% IRR
- Future Value: $100 at 15% for 3 years = $152.09
- Round-trip calculations for consistency
- Edge cases and input validation

## Code Style Guidelines

### iOS (Swift)
- Use `// MARK: -` comments to organize code sections
- One component per file
- View files end with `View` suffix
- Keep views focused - extract complex logic to services
- Follow Swift naming conventions

### Android (Kotlin)
- Use standard Kotlin coding conventions
- One Composable per file when practical
- Composable files end with `View` suffix (e.g., `InputFieldView.kt`)
- Keep composables focused - business logic in ViewModel
- Follow Material 3 design guidelines

### Cross-Platform Consistency
- Use identical calculation formulas and test cases
- Maintain equivalent UI component behavior
- Format numbers consistently using platform-appropriate formatters
- Keep data model structures equivalent across platforms