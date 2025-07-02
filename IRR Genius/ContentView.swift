//
//  ContentView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

enum CalculationMode: String, CaseIterable {
    case calculateIRR = "Calculate IRR"
    case calculateOutcome = "Calculate Outcome"
    case calculateInitial = "Calculate Initial Investment"
}

struct ContentView: View {
    @State private var selectedMode: CalculationMode = .calculateIRR
    
    // IRR Calculation inputs
    @State private var initialInvestment: String = ""
    @State private var outcomeAmount: String = ""
    @State private var timeInMonths: String = ""
    
    // Outcome Calculation inputs
    @State private var outcomeInitialInvestment: String = ""
    @State private var outcomeIRR: String = ""
    @State private var outcomeTimeInMonths: String = ""
    
    // Initial Investment Calculation inputs
    @State private var initialOutcomeAmount: String = ""
    @State private var initialIRR: String = ""
    @State private var initialTimeInMonths: String = ""
    
    @State private var calculatedResult: Double?
    @State private var showingResult = false
    @State private var isCalculating = false
    @State private var errorMessage: String?
    
    var body: some View {
        HStack {
            Spacer(minLength: 0)
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("IRR Genius")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Financial Calculator")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Mode Selector
                    Picker("Calculation Mode", selection: $selectedMode) {
                        ForEach(CalculationMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Input Form based on selected mode
                    switch selectedMode {
                    case .calculateIRR:
                        IRRCalculationView(
                            initialInvestment: $initialInvestment,
                            outcomeAmount: $outcomeAmount,
                            timeInMonths: $timeInMonths,
                            calculatedResult: $calculatedResult,
                            isCalculating: $isCalculating,
                            errorMessage: $errorMessage,
                            onCalculate: calculateIRR
                        )
                    case .calculateOutcome:
                        OutcomeCalculationView(
                            initialInvestment: $outcomeInitialInvestment,
                            irr: $outcomeIRR,
                            timeInMonths: $outcomeTimeInMonths,
                            calculatedResult: $calculatedResult,
                            isCalculating: $isCalculating,
                            errorMessage: $errorMessage,
                            onCalculate: calculateOutcome
                        )
                    case .calculateInitial:
                        InitialCalculationView(
                            outcomeAmount: $initialOutcomeAmount,
                            irr: $initialIRR,
                            timeInMonths: $initialTimeInMonths,
                            calculatedResult: $calculatedResult,
                            isCalculating: $isCalculating,
                            errorMessage: $errorMessage,
                            onCalculate: calculateInitialInvestment
                        )
                    }
                    
                    // Results Section
                    if let result = calculatedResult {
                        ResultCard(
                            mode: selectedMode,
                            result: result,
                            inputs: getInputsForMode()
                        )
                    }
                    
                    Spacer(minLength: 50)
                }
                .frame(maxWidth: 420)
                .padding(.vertical, 32)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private func getInputsForMode() -> [String: Double] {
        switch selectedMode {
        case .calculateIRR:
            let cleanInitial = initialInvestment.replacingOccurrences(of: ",", with: "")
            let cleanOutcome = outcomeAmount.replacingOccurrences(of: ",", with: "")
            let months = Double(timeInMonths) ?? 0
            return [
                "Initial Investment": Double(cleanInitial) ?? 0,
                "Outcome Amount": Double(cleanOutcome) ?? 0,
                "Time Period (Months)": months,
                "Time Period (Years)": months / 12.0
            ]
        case .calculateOutcome:
            let cleanInitial = outcomeInitialInvestment.replacingOccurrences(of: ",", with: "")
            let months = Double(outcomeTimeInMonths) ?? 0
            return [
                "Initial Investment": Double(cleanInitial) ?? 0,
                "IRR": Double(outcomeIRR) ?? 0,
                "Time Period (Months)": months,
                "Time Period (Years)": months / 12.0
            ]
        case .calculateInitial:
            let cleanOutcome = initialOutcomeAmount.replacingOccurrences(of: ",", with: "")
            let months = Double(initialTimeInMonths) ?? 0
            return [
                "Outcome Amount": Double(cleanOutcome) ?? 0,
                "IRR": Double(initialIRR) ?? 0,
                "Time Period (Months)": months,
                "Time Period (Years)": months / 12.0
            ]
        }
    }
    
    private func calculateIRR() {
        let cleanInitial = initialInvestment.replacingOccurrences(of: ",", with: "")
        let cleanOutcome = outcomeAmount.replacingOccurrences(of: ",", with: "")
        
        guard let initial = Double(cleanInitial),
              let outcome = Double(cleanOutcome),
              let months = Double(timeInMonths) else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        isCalculating = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let years = months / 12.0
            let irr = calculateIRRValue(initialInvestment: initial, outcomeAmount: outcome, timeInYears: years)
            calculatedResult = irr
            isCalculating = false
            showingResult = true
        }
    }
    
    private func calculateOutcome() {
        let cleanInitial = outcomeInitialInvestment.replacingOccurrences(of: ",", with: "")
        
        guard let initial = Double(cleanInitial),
              let irr = Double(outcomeIRR),
              let months = Double(outcomeTimeInMonths) else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        isCalculating = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let years = months / 12.0
            let outcome = calculateOutcomeValue(initialInvestment: initial, irr: irr, timeInYears: years)
            calculatedResult = outcome
            isCalculating = false
            showingResult = true
        }
    }
    
    private func calculateInitialInvestment() {
        let cleanOutcome = initialOutcomeAmount.replacingOccurrences(of: ",", with: "")
        
        guard let outcome = Double(cleanOutcome),
              let irr = Double(initialIRR),
              let months = Double(initialTimeInMonths) else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        isCalculating = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let years = months / 12.0
            let initial = calculateInitialValue(outcomeAmount: outcome, irr: irr, timeInYears: years)
            calculatedResult = initial
            isCalculating = false
            showingResult = true
        }
    }
    
    private func calculateIRRValue(initialInvestment: Double, outcomeAmount: Double, timeInYears: Double) -> Double {
        let ratio = outcomeAmount / initialInvestment
        let irr = pow(ratio, 1.0 / timeInYears) - 1
        return irr * 100
    }
    
    private func calculateOutcomeValue(initialInvestment: Double, irr: Double, timeInYears: Double) -> Double {
        let irrDecimal = irr / 100
        return initialInvestment * pow(1 + irrDecimal, timeInYears)
    }
    
    private func calculateInitialValue(outcomeAmount: Double, irr: Double, timeInYears: Double) -> Double {
        let irrDecimal = irr / 100
        return outcomeAmount / pow(1 + irrDecimal, timeInYears)
    }
}

struct IRRCalculationView: View {
    @Binding var initialInvestment: String
    @Binding var outcomeAmount: String
    @Binding var timeInMonths: String
    @Binding var calculatedResult: Double?
    @Binding var isCalculating: Bool
    @Binding var errorMessage: String?
    let onCalculate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            InputField(
                title: "Initial Investment",
                placeholder: "Enter amount (e.g., 10,000)",
                value: $initialInvestment,
                icon: "dollarsign.circle.fill",
                isCurrency: true
            )
            
            InputField(
                title: "Outcome Amount",
                placeholder: "Enter final amount (e.g., 15,000)",
                value: $outcomeAmount,
                icon: "chart.bar.fill",
                isCurrency: true
            )
            
            InputField(
                title: "Time Period (Months)",
                placeholder: "Enter number of months (e.g., 60)",
                value: $timeInMonths,
                icon: "clock.fill",
                isCurrency: false
            )
            
            // Show years equivalent
            Group {
                if let months = Double(timeInMonths), months > 0 {
                    HStack {
                        Spacer()
                        Text("(\(formatWithCommas(months / 12.0, fractionDigits: 2)) years)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("(years will appear here)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }.frame(height: 18)
            
            CalculateButton(
                title: "Calculate IRR",
                isCalculating: isCalculating,
                isEnabled: isFormValid,
                onCalculate: onCalculate
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    private var isFormValid: Bool {
        let cleanInitial = initialInvestment.replacingOccurrences(of: ",", with: "")
        let cleanOutcome = outcomeAmount.replacingOccurrences(of: ",", with: "")
        
        return !initialInvestment.isEmpty && 
        !outcomeAmount.isEmpty && 
        !timeInMonths.isEmpty &&
        Double(cleanInitial) != nil &&
        Double(cleanOutcome) != nil &&
        Double(timeInMonths) != nil &&
        Double(cleanInitial) ?? 0 > 0 &&
        Double(cleanOutcome) ?? 0 > 0 &&
        Double(timeInMonths) ?? 0 > 0
    }
}

struct OutcomeCalculationView: View {
    @Binding var initialInvestment: String
    @Binding var irr: String
    @Binding var timeInMonths: String
    @Binding var calculatedResult: Double?
    @Binding var isCalculating: Bool
    @Binding var errorMessage: String?
    let onCalculate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            InputField(
                title: "Initial Investment",
                placeholder: "Enter amount (e.g., 10,000)",
                value: $initialInvestment,
                icon: "dollarsign.circle.fill",
                isCurrency: true
            )
            
            InputField(
                title: "IRR (%)",
                placeholder: "Enter IRR percentage (e.g., 8.5)",
                value: $irr,
                icon: "percent",
                isCurrency: false
            )
            
            InputField(
                title: "Time Period (Months)",
                placeholder: "Enter number of months (e.g., 60)",
                value: $timeInMonths,
                icon: "clock.fill",
                isCurrency: false
            )
            
            // Show years equivalent
            Group {
                if let months = Double(timeInMonths), months > 0 {
                    HStack {
                        Spacer()
                        Text("(\(formatWithCommas(months / 12.0, fractionDigits: 2)) years)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("(years will appear here)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }.frame(height: 18)
            
            CalculateButton(
                title: "Calculate Outcome",
                isCalculating: isCalculating,
                isEnabled: isFormValid,
                onCalculate: onCalculate
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    private var isFormValid: Bool {
        let cleanInitial = initialInvestment.replacingOccurrences(of: ",", with: "")
        
        return !initialInvestment.isEmpty && 
        !irr.isEmpty && 
        !timeInMonths.isEmpty &&
        Double(cleanInitial) != nil &&
        Double(irr) != nil &&
        Double(timeInMonths) != nil &&
        Double(cleanInitial) ?? 0 > 0 &&
        Double(timeInMonths) ?? 0 > 0
    }
}

struct InitialCalculationView: View {
    @Binding var outcomeAmount: String
    @Binding var irr: String
    @Binding var timeInMonths: String
    @Binding var calculatedResult: Double?
    @Binding var isCalculating: Bool
    @Binding var errorMessage: String?
    let onCalculate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            InputField(
                title: "Target Outcome Amount",
                placeholder: "Enter target amount (e.g., 15,000)",
                value: $outcomeAmount,
                icon: "target",
                isCurrency: true
            )
            
            InputField(
                title: "IRR (%)",
                placeholder: "Enter IRR percentage (e.g., 8.5)",
                value: $irr,
                icon: "percent",
                isCurrency: false
            )
            
            InputField(
                title: "Time Period (Months)",
                placeholder: "Enter number of months (e.g., 60)",
                value: $timeInMonths,
                icon: "clock.fill",
                isCurrency: false
            )
            
            CalculateButton(
                title: "Calculate Initial Investment",
                isCalculating: isCalculating,
                isEnabled: isFormValid,
                onCalculate: onCalculate
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    private var isFormValid: Bool {
        let cleanOutcome = outcomeAmount.replacingOccurrences(of: ",", with: "")
        
        return !outcomeAmount.isEmpty && 
        !irr.isEmpty && 
        !timeInMonths.isEmpty &&
        Double(cleanOutcome) != nil &&
        Double(irr) != nil &&
        Double(timeInMonths) != nil &&
        Double(cleanOutcome) ?? 0 > 0 &&
        Double(timeInMonths) ?? 0 > 0
    }
}

struct CalculateButton: View {
    let title: String
    let isCalculating: Bool
    let isEnabled: Bool
    let onCalculate: () -> Void
    
    var body: some View {
        Button(action: onCalculate) {
            HStack {
                if isCalculating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "function")
                }
                Text(isCalculating ? "Calculating..." : title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(isCalculating || !isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .padding(.horizontal)
    }
}

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var value: String
    let icon: String
    let isCurrency: Bool
    
    @FocusState private var isFocused: Bool
    
    init(title: String, placeholder: String, value: Binding<String>, icon: String, isCurrency: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self._value = value
        self.icon = icon
        self.isCurrency = isCurrency
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            TextField(placeholder, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                .focused($isFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                )
                .onChange(of: value) { _, newValue in
                    if isCurrency {
                        value = formatCurrencyInput(newValue)
                    } else {
                        value = formatNumberInput(newValue)
                    }
                }
        }
    }
    
    private func formatCurrencyInput(_ input: String) -> String {
        // Remove all non-digit characters except decimal point
        let cleaned = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        // Handle decimal points properly
        let components = cleaned.components(separatedBy: ".")
        if components.count > 2 {
            // More than one decimal point, keep only the first
            let wholePart = components[0]
            let decimalPart = components.dropFirst().joined()
            let formatted = formatWholeNumber(wholePart) + "." + decimalPart
            return formatted
        } else if components.count == 2 {
            let wholePart = components[0]
            let decimalPart = components[1]
            let formatted = formatWholeNumber(wholePart) + "." + decimalPart
            return formatted
        } else {
            return formatWholeNumber(cleaned)
        }
    }
    
    private func formatNumberInput(_ input: String) -> String {
        // Remove all non-digit characters except decimal point
        let cleaned = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        // Handle decimal points properly
        let components = cleaned.components(separatedBy: ".")
        if components.count > 2 {
            // More than one decimal point, keep only the first
            let wholePart = components[0]
            let decimalPart = components.dropFirst().joined()
            let formatted = formatWholeNumber(wholePart) + "." + decimalPart
            return formatted
        } else if components.count == 2 {
            let wholePart = components[0]
            let decimalPart = components[1]
            let formatted = formatWholeNumber(wholePart) + "." + decimalPart
            return formatted
        } else {
            return formatWholeNumber(cleaned)
        }
    }
    
    private func formatWholeNumber(_ number: String) -> String {
        guard !number.isEmpty else { return "" }
        
        // Remove leading zeros
        let trimmed = number.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
        guard !trimmed.isEmpty else { return "0" }
        
        // Add commas every 3 digits from the right
        var result = ""
        let reversed = String(trimmed.reversed())
        
        for (index, char) in reversed.enumerated() {
            if index > 0 && index % 3 == 0 {
                result += ","
            }
            result += String(char)
        }
        
        return String(result.reversed())
    }
}

struct ResultCard: View {
    let mode: CalculationMode
    let result: Double
    let inputs: [String: Double]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("\(mode.rawValue) Complete")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text(resultTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(resultDisplay)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                ForEach(Array(inputs.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text("\(key):")
                        Spacer()
                        Text(inputDisplay(for: key, value: inputs[key] ?? 0))
                            .fontWeight(.medium)
                    }
                }
                
                if mode == .calculateIRR {
                    let initial = inputs["Initial Investment"] ?? 0
                    let outcome = inputs["Outcome Amount"] ?? 0
                    HStack {
                        Text("Total Return:")
                        Spacer()
                        Text("$\(formatWithCommas(outcome - initial))")
                            .fontWeight(.medium)
                            .foregroundColor(outcome > initial ? .green : .red)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var resultTitle: String {
        switch mode {
        case .calculateIRR:
            return "Internal Rate of Return:"
        case .calculateOutcome:
            return "Future Value:"
        case .calculateInitial:
            return "Required Initial Investment:"
        }
    }
    
    private var resultDisplay: String {
        switch mode {
        case .calculateIRR:
            return String(format: "%.2f%%", result)
        case .calculateOutcome, .calculateInitial:
            return "$\(formatWithCommas(result))"
        }
    }
    
    private func inputDisplay(for key: String, value: Double) -> String {
        switch key {
        case "IRR":
            return String(format: "%.2f%%", value)
        case "Time Period (Months)":
            return "\(formatWithCommas(value, fractionDigits: 0)) months"
        case "Time Period (Years)":
            return "\(formatWithCommas(value, fractionDigits: 2)) years"
        case "Initial Investment", "Outcome Amount", "Target Outcome Amount":
            return "$\(formatWithCommas(value))"
        default:
            return formatWithCommas(value)
        }
    }
}

// Helper for comma formatting
extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

func formatWithCommas(_ value: Double, fractionDigits: Int = 2) -> String {
    Formatter.withSeparator.maximumFractionDigits = fractionDigits
    return Formatter.withSeparator.string(from: NSNumber(value: value)) ?? String(format: "%.*f", fractionDigits, value)
}

#Preview {
    ContentView()
}

