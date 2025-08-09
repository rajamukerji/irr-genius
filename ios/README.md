# IRR Genius - iOS

Native iOS application built with Swift and SwiftUI for calculating Internal Rate of Return and related financial metrics.

## 📱 Requirements

- **iOS**: 17.0 or later
- **macOS**: 14.0 or later (Mac Catalyst support)
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

## 🏗️ Project Structure

```
IRR Genius/
├── IRR Genius/               # Main app target
│   ├── Models/              # Data models and enums
│   │   ├── Enums.swift
│   │   ├── FollowOnInvestment.swift
│   │   └── GrowthPoint.swift
│   ├── Views/               # SwiftUI views
│   │   ├── ContentView.swift           # Main coordinator
│   │   ├── Components/                 # Reusable UI components
│   │   ├── CalculationViews/          # Mode-specific views
│   │   └── FollowOnInvestment/        # Follow-on investment UI
│   ├── Services/            # Business logic
│   │   └── IRRCalculator.swift
│   └── Utilities/           # Helper utilities
│       └── NumberFormatter.swift
├── IRR GeniusTests/         # Unit tests
└── IRR GeniusUITests/       # UI tests
```

## 🚀 Getting Started

### Opening the Project
```bash
cd ios/
open "IRR Genius.xcodeproj"
```

### Building and Running
1. Select target device or simulator
2. Press `⌘+R` to build and run
3. Or use Product → Run from the menu

Note: The shared scheme runs a pre-build action that formats the `ios/` codebase with SwiftFormat (if installed). Install with `brew install swiftformat`.

### Running Tests
```bash
# Unit tests
⌘+U in Xcode
# Or Product → Test

# Specific test target
⌘+Shift+U to configure test plan
```

## 🏛️ Architecture

### MVVM-like Pattern
- **Views**: SwiftUI views with `@State` for local UI state
- **Models**: Data structures and enums
- **Services**: Business logic separated from UI
- **Utilities**: Shared helper functions

### State Management
- `@State` for local view state
- `@Binding` for parent-child communication
- Callback patterns for actions
- No external state management framework

### Key Components

#### ContentView.swift
- Main coordinator managing calculation modes
- Handles navigation between different calculation types
- Manages follow-on investments list
- Coordinates with IRRCalculator service

#### IRRCalculator.swift
- Core business logic for all calculations
- Pure functions with no UI dependencies
- Handles complex blended IRR calculations
- Generates chart data points

#### Reusable Components
- `InputField`: Formatted text input with validation
- `CalculateButton`: Action button with loading states
- `ResultCard`: Display calculation results
- `GrowthChartView`: Interactive line charts
- `ModeSelectorView`: Tab-style mode selection

## 📊 Features

### Calculation Modes
1. **Calculate IRR**: From initial investment, outcome, and time
2. **Calculate Outcome**: From initial investment, IRR, and time  
3. **Calculate Initial**: From target outcome, IRR, and time
4. **Blended IRR**: With multiple follow-on investments

### Advanced Features
- **Swift Charts**: Native chart visualization
- **Follow-on Investments**: Complex investment scenarios
- **Tag-Along Investments**: Automatic IRR following
- **Custom Valuations**: User-specified valuations
- **Real-time Formatting**: Currency and percentage formatting
- **Input Validation**: Comprehensive error checking

### UI/UX
- **SwiftUI**: Modern declarative UI
- **Dark Mode**: Automatic system appearance support
- **Accessibility**: VoiceOver and accessibility features
- **Universal**: iPhone and iPad support
- **Mac Catalyst**: Native macOS version

## 🧪 Testing

### Unit Tests (IRR GeniusTests)
- Mathematical calculation verification
- Input validation testing
- Edge case handling
- Round-trip calculation consistency

### UI Tests (IRR GeniusUITests) 
- User interaction flows
- Input field behavior
- Navigation testing
- Accessibility testing

### Test Coverage
Run tests with coverage to ensure quality:
```bash
# In Xcode: Product → Test
# Enable code coverage in scheme settings
```

## 🔧 Development Setup

### Xcode Configuration
1. Set development team in project settings
2. Configure code signing if needed
3. Set minimum deployment target (iOS 17.0)
4. Enable SwiftUI previews for faster development

### Swift Package Dependencies
The project uses no external dependencies, only native iOS frameworks:
- SwiftUI for UI
- Swift Charts for charting
- Foundation for utilities

### Code Style
- Follow Swift naming conventions
- Use SwiftUI best practices
- Organize code with `// MARK: -` comments
- Keep views focused and composable

## 📱 Platform-Specific Features

### iOS Specific
- Native iOS navigation patterns
- Haptic feedback for interactions
- System keyboard and input handling
- Native date pickers and controls

### macOS Support
- Mac Catalyst compatibility
- Keyboard shortcuts and menu support
- Window resizing and management
- Native macOS UI adaptations

## 🎨 Design Guidelines

### Colors
- Primary Blue: `#4A90E2`
- Secondary Green: `#50E3C2` 
- Accent Gold: `#F5A623`
- System colors for accessibility

### Typography
- System fonts for consistency
- Appropriate font weights and sizes
- Good contrast ratios
- Dynamic Type support

### Layout
- Responsive design for all screen sizes
- Proper spacing and alignment
- Safe area respect
- Landscape orientation support

## 🔍 Debugging

### Common Issues
1. **Build Errors**: Clean build folder (⌘+Shift+K)
2. **Simulator Issues**: Reset simulator content
3. **Preview Problems**: Restart Xcode, rebuild project
4. **Signing Issues**: Check development team settings

### Debug Tools
- Xcode debugger and breakpoints
- SwiftUI preview debugging
- View hierarchy inspector
- Memory graph debugger

## 📦 Building for Distribution

### App Store Build
1. Set scheme to Release
2. Archive the project (Product → Archive)
3. Upload to App Store Connect
4. Submit for review

### TestFlight Distribution
1. Archive with distribution certificate
2. Upload to App Store Connect
3. Add external testers
4. Send build for testing

## 🔄 Recent Changes

See [REFACTORING_GUIDE.md](../shared/docs/REFACTORING_GUIDE.md) for details on the recent modular architecture refactoring.

### Key Improvements
- Separated monolithic ContentView into focused components
- Improved code organization and maintainability
- Better separation of concerns
- Enhanced reusability of UI components

## 🤝 Contributing to iOS

### Development Workflow
1. Create feature branch from main
2. Implement changes following Swift/SwiftUI best practices
3. Add/update tests as appropriate
4. Test on multiple devices and iOS versions
5. Submit pull request with clear description

### Code Review Checklist
- [ ] Follows Swift naming conventions
- [ ] Uses SwiftUI best practices
- [ ] Includes appropriate tests
- [ ] Works on iPhone and iPad
- [ ] Supports dark mode
- [ ] Accessible for VoiceOver users
- [ ] Performance optimized

### Contributor Checklist
- [ ] Branch from `main`; use Conventional Commits (e.g., `feat:`, `fix:`).
- [ ] Build and run on iOS 17+ simulators and at least one device profile.
- [ ] Run tests (⌘U) and verify deterministic financial results match `shared/specs/CALCULATIONS.md`.
- [ ] Verify light/dark mode, Dynamic Type, and basic VoiceOver labels.
- [ ] No secrets or CloudKit credentials committed; entitlements configured locally only.
- [ ] Update screenshots or GIFs for UI changes and note test plan in PR.

## 📚 Resources

### Apple Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Charts](https://developer.apple.com/documentation/charts)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios)

### Best Practices
- [Swift Style Guide](https://github.com/raywenderlich/swift-style-guide)
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui/view-layout-and-presentation)
- [iOS App Architecture](https://developer.apple.com/documentation/swift/choosing-between-structures-and-classes)
