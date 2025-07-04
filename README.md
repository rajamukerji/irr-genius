# IRR Genius 📊

A comprehensive Internal Rate of Return (IRR) calculator built with SwiftUI for iOS and macOS. Calculate IRR, future values, required initial investments, and blended IRR with follow-on investments using a beautiful, intuitive interface.

## ✨ Features

### 🧮 Four Calculation Modes

1. **Calculate IRR** - Find the internal rate of return given initial investment, outcome amount, and time period
2. **Calculate Outcome** - Determine future value based on initial investment, IRR, and time period
3. **Calculate Initial Investment** - Find required initial investment to reach a target outcome with given IRR and time
4. **Calculate Blended IRR** - Calculate overall IRR considering multiple follow-on investments over time

### 🎨 User Experience

- **Real-time comma formatting** for easy number reading (e.g., 1,000,000)
- **Smart input validation** with helpful error messages
- **Month-based time periods** with automatic years conversion display
- **Professional UI** with gradient buttons and smooth animations
- **Cross-platform** support for iOS and macOS
- **Interactive growth charts** with draggable markers to inspect values
- **Dark mode support** with adaptive colors and backgrounds

### 📱 Key Features

- **Input Formatting**: Automatic comma insertion for currency fields
- **Time Conversion**: Enter months, see years equivalent in real-time
- **Result Display**: Formatted results with all input values for reference
- **Error Handling**: Clear validation and error messages
- **Loading States**: Professional loading indicators during calculations
- **Follow-on Investments**: Add multiple investments with dates and valuations
- **Investment Types**: Support for Buy, Sell, and Buy/Sell operations
- **Tag-Along Mode**: Follow-on investments automatically follow the same IRR trajectory as the initial investment
- **Custom Valuation Options**: Choose between computed (IRR-based) or specified valuations
- **Growth Visualization**: Interactive charts showing investment growth over time

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ / macOS 14.0+
- Swift 5.9+

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/rajamukerji/irr-genius.git
   cd irr-genius
   ```

2. **Open in Xcode**

   ```bash
   open "IRR Genius.xcodeproj"
   ```

3. **Build and Run**
   - Select your target device/simulator
   - Press `⌘+R` to build and run

## 📖 Usage Examples

### Calculate IRR

- **Initial Investment**: $10,000
- **Outcome Amount**: $15,000
- **Time Period**: 60 months (5 years)
- **Result**: 8.45% IRR

### Calculate Future Value

- **Initial Investment**: $10,000
- **IRR**: 8.5%
- **Time Period**: 60 months (5 years)
- **Result**: $15,000.00

### Calculate Required Initial Investment

- **Target Outcome**: $15,000
- **IRR**: 8.5%
- **Time Period**: 60 months (5 years)
- **Result**: $10,000.00

### Calculate Blended IRR

#### Tag-Along Investment Example
- **Initial Investment**: $1,000,000
- **Follow-on Investment 1**: $500,000 at month 6 (Tag-Along - follows initial IRR)
- **Follow-on Investment 2**: $500,000 at month 10 (Tag-Along - follows initial IRR)
- **Final Valuation**: $8,000,000
- **Time Period**: 12 months (1 year)
- **Result**: 700% Blended IRR

#### Custom Valuation Example
- **Initial Investment**: $10,000
- **Follow-on Investment 1**: $5,000 at month 12 (computed at 10% IRR)
- **Follow-on Investment 2**: $3,000 at month 24 (specified valuation: $4,500)
- **Final Valuation**: $25,000
- **Time Period**: 60 months (5 years)
- **Result**: 12.34% Blended IRR

## 🧮 Mathematical Formulas

### IRR Calculation

```text
IRR = (Outcome/Initial)^(1/Years) - 1
```

### Future Value Calculation

```text
Future Value = Initial × (1 + IRR)^Years
```

### Initial Investment Calculation

```text
Initial = Outcome / (1 + IRR)^Years
```

### Blended IRR Calculation

#### Tag-Along Investments
```text
For tag-along investments, follow-on investments follow the same IRR trajectory as the initial investment:

Investment Growth = Amount × (1 + Blended IRR)^(Months Since Investment / 12)

Total Value = Initial Investment Growth + Σ(Tag-Along Investment Growth)
```

#### Custom Valuations
```text
Blended IRR = (Final Value / Total Time-Weighted Investment)^(1/Total Years) - 1

Where:
Total Time-Weighted Investment = Initial × Total Years + Σ(Investment × Years Remaining)
```

#### Investment Types
- **Buy**: Adds to invested capital and final value
- **Sell**: Reduces final value (no capital addition)
- **Buy/Sell**: Adds to invested capital but reduces final value by sell amount

## 🛠 Technical Details

### Architecture

- **Framework**: SwiftUI
- **Platform**: iOS 17.0+, macOS 14.0+
- **Language**: Swift 5.9+
- **Design Pattern**: MVVM with State Management

### Key Components

- `ContentView`: Main app interface with mode selection
- `IRRCalculationView`: IRR calculation form
- `OutcomeCalculationView`: Future value calculation form
- `InitialCalculationView`: Initial investment calculation form
- `BlendedIRRCalculationView`: Blended IRR calculation with follow-on investments
- `FollowOnInvestmentRow`: Individual follow-on investment display
- `AddFollowOnInvestmentView`: Modal for adding new follow-on investments
- `InputField`: Reusable input component with formatting
- `ResultCard`: Results display component
- `GrowthChartView`: Interactive growth chart with Swift Charts

### Features Implementation

- **Number Formatting**: Custom `NumberFormatter` with comma separators
- **Input Validation**: Real-time validation with visual feedback
- **State Management**: SwiftUI `@State` properties for reactive UI
- **Cross-Platform**: Single codebase for iOS and macOS
- **Date Handling**: Calendar-based calculations for investment timing
- **Chart Integration**: Swift Charts for interactive data visualization
- **Dark Mode**: Adaptive colors and backgrounds for all UI components

## 📸 Screenshots

## Screenshots will be added here once the app is running

## 🎯 Use Cases

- **Investors**: Calculate expected returns on investments with multiple contributions
- **Financial Planners**: Determine investment strategies with follow-on funding
- **Students**: Learn and practice IRR calculations including complex scenarios
- **Analysts**: Compare different investment opportunities with varying cash flows
- **Business Owners**: Evaluate project profitability with staged investments
- **Startup Investors**: Calculate blended IRR for investments with multiple funding rounds
- **Real Estate Investors**: Analyze returns on properties with renovation investments
- **Venture Capitalists**: Model tag-along investments that follow the same growth trajectory
- **Angel Investors**: Track returns on staged investments with varying participation rights

## 🔧 Development

### Project Structure

```text
IRR Genius/
├── IRR Genius/
│   ├── IRR_GeniusApp.swift      # App entry point
│   ├── ContentView.swift        # Main UI and logic
│   └── Assets.xcassets/         # App icons and assets
├── IRR GeniusTests/             # Unit tests
└── IRR GeniusUITests/           # UI tests
```

### Building for Release

1. Select **Product** → **Archive** in Xcode
2. Choose **Distribute App**
3. Select **App Store Connect**
4. Follow the upload process

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

## Raja Mukerji

- GitHub: [@rajamukerji](https://github.com/rajamukerji)
- Created: July 1, 2025

## 🙏 Acknowledgments

- Built with SwiftUI for modern iOS/macOS development
- Inspired by the need for simple, accurate IRR calculations
- Designed for both professional and educational use
- Enhanced with follow-on investment capabilities for real-world scenarios

---

⭐ **Star this repository if you find it helpful!**
