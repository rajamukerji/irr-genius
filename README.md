# IRR Genius 📊

A comprehensive Internal Rate of Return (IRR) calculator built with SwiftUI for iOS and macOS. Calculate IRR, future values, and required initial investments with a beautiful, intuitive interface.

## ✨ Features

### 🧮 Three Calculation Modes

1. **Calculate IRR** - Find the internal rate of return given initial investment, outcome amount, and time period
2. **Calculate Outcome** - Determine future value based on initial investment, IRR, and time period  
3. **Calculate Initial Investment** - Find required initial investment to reach a target outcome with given IRR and time

### 🎨 User Experience

- **Real-time comma formatting** for easy number reading (e.g., 1,000,000)
- **Smart input validation** with helpful error messages
- **Month-based time periods** with automatic years conversion display
- **Professional UI** with gradient buttons and smooth animations
- **Cross-platform** support for iOS and macOS

### 📱 Key Features

- **Input Formatting**: Automatic comma insertion for currency fields
- **Time Conversion**: Enter months, see years equivalent in real-time
- **Result Display**: Formatted results with all input values for reference
- **Error Handling**: Clear validation and error messages
- **Loading States**: Professional loading indicators during calculations

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

## 🧮 Mathematical Formulas

### IRR Calculation
```
IRR = (Outcome/Initial)^(1/Years) - 1
```

### Future Value Calculation
```
Future Value = Initial × (1 + IRR)^Years
```

### Initial Investment Calculation
```
Initial = Outcome / (1 + IRR)^Years
```

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
- `InputField`: Reusable input component with formatting
- `ResultCard`: Results display component

### Features Implementation
- **Number Formatting**: Custom `NumberFormatter` with comma separators
- **Input Validation**: Real-time validation with visual feedback
- **State Management**: SwiftUI `@State` properties for reactive UI
- **Cross-Platform**: Single codebase for iOS and macOS

## 📸 Screenshots

*Screenshots will be added here once the app is running*

## 🎯 Use Cases

- **Investors**: Calculate expected returns on investments
- **Financial Planners**: Determine investment strategies
- **Students**: Learn and practice IRR calculations
- **Analysts**: Compare different investment opportunities
- **Business Owners**: Evaluate project profitability

## 🔧 Development

### Project Structure
```
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

**Raja Mukerji**
- GitHub: [@rajamukerji](https://github.com/rajamukerji)
- Created: July 1, 2025

## 🙏 Acknowledgments

- Built with SwiftUI for modern iOS/macOS development
- Inspired by the need for simple, accurate IRR calculations
- Designed for both professional and educational use

---

⭐ **Star this repository if you find it helpful!** 