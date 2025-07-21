# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IRR Genius is a Swift/SwiftUI application for iOS and macOS that calculates Internal Rate of Return (IRR) and related financial metrics. The app supports multiple calculation modes and features interactive growth visualizations.

## Development Commands

This is an Xcode project. Use these commands:

- **Build**: Open in Xcode and press `⌘+B` or run `xcodebuild`
- **Run**: Press `⌘+R` in Xcode
- **Test**: Press `⌘+U` in Xcode (uses Swift Testing framework, not XCTest)
- **Clean**: Press `⌘+Shift+K` in Xcode
- **Open Project**: `open "IRR Genius.xcodeproj"`

## Architecture

The codebase follows a modular MVVM-like architecture:

```
IRR Genius/
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

### Key Architectural Patterns

1. **State Management**: Uses SwiftUI's `@State` for local state and `@Binding` for parent-child communication
2. **Separation of Concerns**: Business logic is isolated in `IRRCalculator.swift`, UI logic stays in views
3. **Component-Based**: Each view component has a single responsibility
4. **Calculation Modes**: Managed through `CalculationMode` enum with four modes:
   - `.calculateIRR` - Calculate IRR from initial/final values
   - `.calculateOutcome` - Calculate future value from IRR
   - `.calculateInitial` - Calculate required initial investment
   - `.calculateBlended` - Calculate blended IRR with follow-on investments

## Important Implementation Details

### IRR Calculation Logic
- Core calculations use Newton-Raphson method for IRR solving
- IRR is stored as decimal (0.15 = 15%) internally but displayed as percentage
- All monetary values use `Double` type
- Years can be fractional (e.g., 2.5 years)

### Follow-On Investments
- Support for tag-along investments (follow main investment's IRR)
- Buy/Sell/Buy-Sell transaction types
- Custom valuation options
- Stored in `followOnInvestments` array in `ContentView`

### UI Patterns
- Real-time number formatting with `NumberFormatter.currencyFormatter`
- Input validation with error messages in red text
- Loading states during calculations using `isCalculating` flag
- Charts use Swift Charts framework with `GrowthPoint` data model

### Platform Support
- iOS 17.0+ and macOS 14.0+
- Universal app with shared codebase
- Dark mode support built-in

## Testing
- Test files exist but tests are not implemented
- Uses Swift Testing framework (not XCTest)
- Test calculations by comparing with Excel/financial calculator results

## Code Style Guidelines
- Use `// MARK: -` comments to organize code sections
- One component per file
- View files end with `View` suffix
- Keep views focused - extract complex logic to services
- Format numbers consistently using shared formatters