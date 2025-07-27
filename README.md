# IRR Genius

A cross-platform Internal Rate of Return calculator for iOS and Android, designed for investors and financial professionals.

## 📱 Platforms

- **iOS**: Native Swift/SwiftUI application (iOS 17.0+)
- **Android**: Native Kotlin/Jetpack Compose application (API 26+)

## ✨ Features

### Core Calculations
- **Calculate IRR**: Determine Internal Rate of Return from investment parameters
- **Calculate Outcome**: Find future value given IRR and time horizon  
- **Calculate Initial Investment**: Determine required capital for target outcomes
- **Blended IRR**: Complex calculations with multiple follow-on investments
- **Portfolio Unit Investment**: Calculate IRR for unit-based portfolio investments with success rates

### Advanced Features
- **Interactive Growth Charts**: Visualize investment trajectory over time
- **Follow-on Investments**: Model additional investments at different times
- **Tag-Along Investments**: Automatically follow initial investment's IRR
- **Custom Valuations**: Specify valuations for follow-on investments
- **Buy/Sell/Buy-Sell**: Support different investment transaction types
- **Unit-Based Metrics**: Track cost per unit, average unit IRR, and portfolio composition
- **Investment Batch Management**: Organize multiple investment batches with different unit prices
- **Success Rate Modeling**: Apply probability-based adjustments to portfolio returns

### Data Management
- **Save Calculations**: Store calculations locally with name, notes, and tags
- **Project Organization**: Group related calculations into projects
- **Search & Filter**: Find calculations by name, notes, tags, or project
- **Import/Export**: CSV export for single and multiple calculations
- **Auto-save**: Automatic saving of calculations with configurable behavior
- **Data Validation**: Real-time input validation with error severity levels
- **Cloud Sync Ready**: Infrastructure for future cloud synchronization

### UI/UX
- **Real-time Formatting**: Automatic currency and percentage formatting
- **Input Validation**: Comprehensive error checking and user guidance
- **Dark Mode**: Full support on both platforms
- **Responsive Design**: Optimized for phones and tablets

## 🏗️ Project Structure

```
├── ios/                          # iOS application
│   ├── IRR Genius/               # Main iOS project
│   │   ├── Data/                 # Core Data persistence layer
│   │   ├── Models/               # Data models and business logic
│   │   └── Views/                # SwiftUI views and components
│   ├── IRR Genius.xcodeproj/     # Xcode project file
│   ├── IRR GeniusTests/          # Unit tests
│   └── IRR GeniusUITests/        # UI tests
├── android/                      # Android application  
│   ├── app/                      # Main Android module
│   │   ├── data/                 # Room database and repositories
│   │   │   ├── dao/              # Data Access Objects
│   │   │   ├── database/         # Room database configuration
│   │   │   ├── repository/       # Repository implementations
│   │   │   ├── export/           # Export services (CSV/PDF)
│   │   │   └── sync/             # Cloud sync infrastructure
│   │   ├── ui/                   # Compose UI and ViewModels
│   │   │   ├── components/       # Reusable UI components
│   │   │   ├── screens/          # Screen implementations
│   │   │   └── theme/            # Material Design theme
│   │   ├── utils/                # Utility classes and helpers
│   │   ├── validation/           # Input validation services
│   │   └── services/             # Business logic services
│   ├── build.gradle.kts          # Build configuration
│   └── settings.gradle.kts       # Project settings
├── .kiro/                        # Kiro AI specifications
│   └── specs/                    # Enhanced data management specs
├── shared/                       # Common assets and documentation
│   ├── docs/                     # Shared documentation
│   ├── assets/                   # Design assets and specifications
│   └── specs/                    # Technical specifications
└── README.md                     # This file
```

## 📈 Recent Updates

### Android Build System Improvements (Latest)
- **Simplified ValidationService**: Clean single-object design with comprehensive validation rules
- **Fixed Material Design Icons**: Replaced deprecated icons with available alternatives
- **Resolved Compilation Issues**: Reduced errors from 100+ to minimal warnings
- **Enhanced Services**:
  - ValidationService with field-specific rules and severity levels
  - ErrorRecoveryService for graceful error handling
  - CloudSyncService with proper async/await patterns
  - SharingService for CSV/PDF export functionality
- **Improved Architecture**: Repository pattern with proper interface segregation

## 🚀 Quick Start

### iOS Development
```bash
cd ios/
open "IRR Genius.xcodeproj"
# Build and run in Xcode (⌘+R)
```

### Android Development  
```bash
cd android/
# Open in Android Studio or:
./gradlew build
./gradlew installDebug
```

#### Build Requirements
- **Gradle**: 8.0
- **Android Gradle Plugin**: 8.1.4
- **Kotlin**: 1.9.0
- **Java**: 17 or higher

## 🧮 Calculation Examples

### Basic IRR Calculation
- **Initial Investment**: $100,000
- **Final Outcome**: $150,000  
- **Time Period**: 2 years
- **Result**: 22.47% IRR

### Blended IRR with Follow-on
- **Initial**: $100,000 (Year 0)
- **Follow-on**: $50,000 (Year 1) 
- **Final Outcome**: $200,000 (Year 3)
- **Result**: Blended IRR accounting for time-weighted returns

### Portfolio Unit Investment
- **Initial Investment**: $100,000 for 100 units @ $1,000/unit
- **Success Rate**: 80% expected success
- **Follow-on Batch**: 50 units @ $1,200/unit (Year 1)
- **Result**: Portfolio IRR with unit-based performance metrics

## 🔧 Technical Details

### iOS (Swift/SwiftUI)
- **Architecture**: MVVM with SwiftUI state management
- **Persistence**: Core Data with async/await patterns
- **Charts**: Native Swift Charts framework
- **Testing**: Swift Testing framework
- **Minimum Version**: iOS 17.0, macOS 14.0

### Android (Kotlin/Compose)
- **Architecture**: MVVM with StateFlow and Repository pattern
- **Persistence**: Room database with Kotlin coroutines
- **Charts**: Vico charting library
- **Testing**: JUnit with Kotlin test extensions
- **Minimum Version**: Android API 26 (Android 8.0)
- **Compose BOM**: 2024.04.01
- **Material Design 3**: Full implementation

### Shared Specifications
- **Calculations**: Identical mathematical formulas across platforms
- **Data Models**: Equivalent structures for all data types
- **UI Patterns**: Consistent user experience and interaction patterns
- **Testing**: Common test cases and validation scenarios

## 📊 Mathematical Formulas

All calculations use standard financial formulas:

- **IRR**: `(FV/PV)^(1/n) - 1`
- **Future Value**: `PV × (1 + IRR)^n`  
- **Present Value**: `FV / (1 + IRR)^n`
- **Blended IRR**: Time-weighted money-weighted returns

See [shared/specs/CALCULATIONS.md](shared/specs/CALCULATIONS.md) for detailed specifications.

## 🧪 Testing

### iOS Testing
```bash
cd ios/
# In Xcode: ⌘+U or Product → Test
```

### Android Testing
```bash
cd android/
./gradlew test                    # Unit tests
./gradlew connectedAndroidTest    # Instrumented tests
```

### Common Test Cases
- Basic IRR calculations with known results
- Round-trip calculation verification
- Edge cases (zero values, negative returns)
- Input validation and error handling
- Follow-on investment scenarios

## 🎨 Design Assets

Design specifications and assets are located in `shared/assets/`:
- App icon specifications for both platforms
- Color palette and brand guidelines  
- UI component design standards
- Chart styling and formatting rules

## 📖 Documentation

### Platform-Specific
- [iOS README](ios/README.md) - iOS-specific setup and development
- [Android README](android/README.md) - Android-specific setup and development

### Shared Documentation
- [Calculation Specifications](shared/specs/CALCULATIONS.md) - Mathematical formulas and business logic
- [Refactoring Guide](shared/docs/REFACTORING_GUIDE.md) - iOS codebase evolution
- [Claude AI Guide](shared/docs/CLAUDE.md) - AI assistant integration guide

## 🔒 Security & Privacy

- **No Network Access**: All calculations performed locally
- **No Data Collection**: No user data transmitted or stored remotely
- **Input Sanitization**: All user inputs validated and sanitized
- **Secure Calculations**: Financial calculations use double-precision arithmetic

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Platform-Specific Contributions
- **iOS**: Follow Swift style guidelines and SwiftUI best practices
- **Android**: Follow Kotlin coding conventions and Jetpack Compose patterns
- **Shared**: Ensure mathematical consistency across platforms

## 📞 Support

For questions, bug reports, or feature requests:
- Create an issue in this repository
- Ensure bug reports include platform, version, and reproduction steps
- Feature requests should specify target platform(s) or cross-platform scope

## 🏆 Credits

- Original iOS development and financial calculations
- Android port with feature parity and modern architecture
- Cross-platform design and mathematical specifications