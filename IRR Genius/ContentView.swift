//
//  ContentView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI
import Charts

enum CalculationMode: String, CaseIterable {
    case calculateIRR = "Calculate IRR"
    case calculateOutcome = "Calculate Outcome"
    case calculateInitial = "Calculate Initial Investment"
    case calculateBlendedIRR = "Calculate Blended IRR"
}

enum ValuationType: String, CaseIterable {
    case computed = "Computed (based on IRR)"
    case specified = "Specified Valuation"
}

enum TimingType: String, CaseIterable {
    case absoluteDate = "Specific Date"
    case relativeTime = "Relative to Initial Investment"
}

enum TimeUnit: String, CaseIterable {
    case days = "Days"
    case months = "Months"
    case years = "Years"
}

// Data structure for follow-on investments
struct FollowOnInvestment: Identifiable {
    let id = UUID()
    var timingType: TimingType
    var date: Date // Used when timingType is .absoluteDate
    var relativeAmount: String // Used when timingType is .relativeTime
    var relativeUnit: TimeUnit // Used when timingType is .relativeTime
    var amount: String
    var valuationType: ValuationType
    var valuation: String // Either computed based on IRR or specified directly
    var irr: String // Used for computed valuation
    
    // Computed property to get the actual investment date
    var investmentDate: Date {
        switch timingType {
        case .absoluteDate:
            return date
        case .relativeTime:
            let amount = Double(relativeAmount) ?? 0
            let calendar = Calendar.current
            switch relativeUnit {
            case .days:
                return calendar.date(byAdding: .day, value: Int(amount), to: Date()) ?? Date()
            case .months:
                return calendar.date(byAdding: .month, value: Int(amount), to: Date()) ?? Date()
            case .years:
                return calendar.date(byAdding: .year, value: Int(amount), to: Date()) ?? Date()
            }
        }
    }
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
    
    // Blended IRR Calculation inputs
    @State private var blendedInitialInvestment: String = ""
    @State private var blendedFinalValuation: String = ""
    @State private var blendedTimeInMonths: String = ""
    @State private var followOnInvestments: [FollowOnInvestment] = []
    @State private var showingAddInvestment = false
    
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
                    case .calculateBlendedIRR:
                        BlendedIRRCalculationView(
                            initialInvestment: $blendedInitialInvestment,
                            finalValuation: $blendedFinalValuation,
                            timeInMonths: $blendedTimeInMonths,
                            followOnInvestments: $followOnInvestments,
                            calculatedResult: $calculatedResult,
                            isCalculating: $isCalculating,
                            errorMessage: $errorMessage,
                            showingAddInvestment: $showingAddInvestment,
                            onCalculate: calculateBlendedIRR
                        )
                    }
                    
                    // Results Section
                    if let result = calculatedResult {
                        ResultCard(
                            mode: selectedMode,
                            result: result,
                            inputs: getInputsForMode()
                        )
                        if let chartData = chartDataForCurrentInputs() {
                            GrowthChartView(data: chartData)
                        }
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
        case .calculateBlendedIRR:
            let cleanInitial = blendedInitialInvestment.replacingOccurrences(of: ",", with: "")
            let cleanFinalValuation = blendedFinalValuation.replacingOccurrences(of: ",", with: "")
            let months = Double(blendedTimeInMonths) ?? 0
            var inputs: [String: Double] = [
                "Initial Investment": Double(cleanInitial) ?? 0,
                "Final Valuation": Double(cleanFinalValuation) ?? 0,
                "Time Period (Months)": months,
                "Time Period (Years)": months / 12.0,
                "Follow-on Investments": Double(followOnInvestments.count)
            ]
            
            // Add total follow-on investment amount
            let totalFollowOnAmount = followOnInvestments.reduce(0.0) { total, investment in
                total + (Double(investment.amount.replacingOccurrences(of: ",", with: "")) ?? 0)
            }
            inputs["Total Follow-on Amount"] = totalFollowOnAmount
            
            return inputs
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
    
    private func calculateBlendedIRR() {
        let cleanInitial = blendedInitialInvestment.replacingOccurrences(of: ",", with: "")
        let cleanFinalValuation = blendedFinalValuation.replacingOccurrences(of: ",", with: "")
        
        guard let initial = Double(cleanInitial),
              let finalValuation = Double(cleanFinalValuation),
              let totalMonths = Double(blendedTimeInMonths) else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        // Validate follow-on investments
        for investment in followOnInvestments {
            let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")
            let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
            
            guard let amount = Double(cleanAmount),
                  let valuation = Double(cleanValuation),
                  amount > 0, valuation > 0 else {
                errorMessage = "Please enter valid amounts for all follow-on investments"
                return
            }
        }
        
        isCalculating = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let totalYears = totalMonths / 12.0
            let blendedIRR = calculateBlendedIRRValue(
                initialInvestment: initial,
                followOnInvestments: followOnInvestments,
                finalValuation: finalValuation,
                totalTimeInYears: totalYears
            )
            calculatedResult = blendedIRR
            isCalculating = false
            showingResult = true
        }
    }
    
    private func calculateBlendedIRRValue(
        initialInvestment: Double,
        followOnInvestments: [FollowOnInvestment],
        finalValuation: Double,
        totalTimeInYears: Double
    ) -> Double {
        // Sort investments by date
        let sortedInvestments = followOnInvestments.sorted { $0.investmentDate < $1.investmentDate }
        
        // Calculate total invested capital (time-weighted)
        var totalInvested = initialInvestment * totalTimeInYears // Initial investment for full period
        
        for investment in sortedInvestments {
            let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")
            let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
            
            guard let amount = Double(cleanAmount),
                  let valuation = Double(cleanValuation) else { continue }
            
            // Calculate time from investment date to final date
            let monthsFromInvestment = Calendar.current.dateComponents([.month], from: investment.investmentDate, to: Date()).month ?? 0
            let yearsFromInvestment = Double(monthsFromInvestment) / 12.0
            
            // Add time-weighted investment amount
            totalInvested += amount * yearsFromInvestment
        }
        
        // Calculate total final value
        let totalFinalValue = finalValuation
        
        // Calculate blended IRR using the formula: (Final Value / Total Invested)^(1/Total Time) - 1
        let ratio = totalFinalValue / totalInvested
        let blendedIRR = pow(ratio, 1.0 / totalTimeInYears) - 1
        
        return blendedIRR * 100
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
    
    // Chart Data Calculation
    private func chartDataForCurrentInputs() -> [GrowthPoint]? {
        switch selectedMode {
        case .calculateIRR:
            guard let initial = Double(initialInvestment.replacingOccurrences(of: ",", with: "")),
                  let outcome = Double(outcomeAmount.replacingOccurrences(of: ",", with: "")),
                  let monthsDouble = Double(timeInMonths),
                  initial > 0, outcome > 0 else { return nil }
            let months = Int(monthsDouble)
            guard months > 0 else { return nil }
            let years = Double(months) / 12.0
            let irr = calculateIRRValue(initialInvestment: initial, outcomeAmount: outcome, timeInYears: years) / 100.0
            return growthPoints(initial: initial, rate: irr, months: months)
        case .calculateOutcome:
            guard let initial = Double(outcomeInitialInvestment.replacingOccurrences(of: ",", with: "")),
                  let irr = Double(outcomeIRR),
                  let monthsDouble = Double(outcomeTimeInMonths),
                  initial > 0 else { return nil }
            let months = Int(monthsDouble)
            guard months > 0 else { return nil }
            let rate = irr / 100.0
            return growthPoints(initial: initial, rate: rate, months: months)
        case .calculateInitial:
            guard let outcome = Double(initialOutcomeAmount.replacingOccurrences(of: ",", with: "")),
                  let irr = Double(initialIRR),
                  let monthsDouble = Double(initialTimeInMonths),
                  outcome > 0 else { return nil }
            let months = Int(monthsDouble)
            guard months > 0 else { return nil }
            let rate = irr / 100.0
            // Calculate initial investment needed
            let initial = outcome / pow(1 + rate, Double(months) / 12.0)
            return growthPoints(initial: initial, rate: rate, months: months)
        case .calculateBlendedIRR:
            guard let initial = Double(blendedInitialInvestment.replacingOccurrences(of: ",", with: "")),
                  let finalValuation = Double(blendedFinalValuation.replacingOccurrences(of: ",", with: "")),
                  let monthsDouble = Double(blendedTimeInMonths),
                  initial > 0, finalValuation > 0 else { return nil }
            let months = Int(monthsDouble)
            guard months > 0 else { return nil }
            
            // Calculate blended IRR for chart
            let totalYears = Double(months) / 12.0
            let blendedIRR = calculateBlendedIRRValue(
                initialInvestment: initial,
                followOnInvestments: followOnInvestments,
                finalValuation: finalValuation,
                totalTimeInYears: totalYears
            ) / 100.0
            
            return growthPointsWithFollowOn(
                initial: initial,
                followOnInvestments: followOnInvestments,
                finalValuation: finalValuation,
                months: months
            )
        }
    }
    
    private func growthPoints(initial: Double, rate: Double, months: Int) -> [GrowthPoint] {
        (0...months).map { month in
            let value = initial * pow(1 + rate, Double(month) / 12.0)
            return GrowthPoint(month: month, value: value)
        }
    }
    
    private func growthPointsWithFollowOn(
        initial: Double,
        followOnInvestments: [FollowOnInvestment],
        finalValuation: Double,
        months: Int
    ) -> [GrowthPoint] {
        var growthPoints: [GrowthPoint] = []
        
        // Calculate the blended IRR rate
        let totalYears = Double(months) / 12.0
        let blendedIRR = calculateBlendedIRRValue(
            initialInvestment: initial,
            followOnInvestments: followOnInvestments,
            finalValuation: finalValuation,
            totalTimeInYears: totalYears
        ) / 100.0
        
        // Sort investments by their actual investment date
        let sortedInvestments = followOnInvestments.sorted { $0.investmentDate < $1.investmentDate }
        
        // Generate monthly growth points
        for month in 0...months {
            var totalValue = initial * pow(1 + blendedIRR, Double(month) / 12.0)
            
            // Add value from follow-on investments
            for investment in sortedInvestments {
                let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")
                guard let amount = Double(cleanAmount) else { continue }
                
                // Calculate when this investment was made (months from start)
                let investmentMonth = Calendar.current.dateComponents([.month], from: Date(), to: investment.investmentDate).month ?? 0
                let investmentMonthFromStart = max(0, investmentMonth)
                
                // Only add growth if the investment was made before or at this month
                if month >= investmentMonthFromStart {
                    let monthsSinceInvestment = month - investmentMonthFromStart
                    let investmentGrowth = amount * pow(1 + blendedIRR, Double(monthsSinceInvestment) / 12.0)
                    totalValue += investmentGrowth
                }
            }
            
            growthPoints.append(GrowthPoint(month: month, value: totalValue))
        }
        
        return growthPoints
    }
    
    static func formatWithCommas(_ value: Double, fractionDigits: Int = 2) -> String {
        Formatter.withSeparator.maximumFractionDigits = fractionDigits
        return Formatter.withSeparator.string(from: NSNumber(value: value)) ?? String(format: "%.*f", fractionDigits, value)
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
                        Text("(\(ContentView.formatWithCommas(months / 12.0, fractionDigits: 2)) years)")
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
                        Text("(\(ContentView.formatWithCommas(months / 12.0, fractionDigits: 2)) years)")
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

struct BlendedIRRCalculationView: View {
    @Binding var initialInvestment: String
    @Binding var finalValuation: String
    @Binding var timeInMonths: String
    @Binding var followOnInvestments: [FollowOnInvestment]
    @Binding var calculatedResult: Double?
    @Binding var isCalculating: Bool
    @Binding var errorMessage: String?
    @Binding var showingAddInvestment: Bool
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
                title: "Final Valuation",
                placeholder: "Enter final valuation (e.g., 15,000)",
                value: $finalValuation,
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
            
            // Follow-on Investments Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Follow-on Investments")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: {
                        showingAddInvestment = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                
                if followOnInvestments.isEmpty {
                    Text("No follow-on investments added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(followOnInvestments.indices, id: \.self) { index in
                        FollowOnInvestmentRow(
                            investment: $followOnInvestments[index],
                            onDelete: {
                                followOnInvestments.remove(at: index)
                            }
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )
            
            CalculateButton(
                title: "Calculate Blended IRR",
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
        .sheet(isPresented: $showingAddInvestment) {
            AddFollowOnInvestmentView(
                investment: FollowOnInvestment(
                    timingType: .absoluteDate,
                    date: Date(),
                    relativeAmount: "",
                    relativeUnit: .days,
                    amount: "",
                    valuationType: .computed,
                    valuation: "",
                    irr: ""
                )
            ) { newInvestment in
                followOnInvestments.append(newInvestment)
                showingAddInvestment = false
            }
        }
    }
    
    private var isFormValid: Bool {
        let cleanInitial = initialInvestment.replacingOccurrences(of: ",", with: "")
        let cleanFinalValuation = finalValuation.replacingOccurrences(of: ",", with: "")
        
        return !initialInvestment.isEmpty && 
        !finalValuation.isEmpty && 
        !timeInMonths.isEmpty &&
        Double(cleanInitial) != nil &&
        Double(cleanFinalValuation) != nil &&
        Double(timeInMonths) != nil &&
        Double(cleanInitial) ?? 0 > 0 &&
        Double(cleanFinalValuation) ?? 0 > 0 &&
        Double(timeInMonths) ?? 0 > 0
    }
}

struct FollowOnInvestmentRow: View {
    @Binding var investment: FollowOnInvestment
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Investment: $\(ContentView.formatWithCommas(Double(investment.amount.replacingOccurrences(of: ",", with: "")) ?? 0))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Display timing information based on type
                    if investment.timingType == .absoluteDate {
                        Text("Date: \(investment.investmentDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Timing: \(investment.relativeAmount) \(investment.relativeUnit.rawValue) after initial investment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            
            if investment.valuationType == .computed {
                Text("Valuation: $\(ContentView.formatWithCommas(Double(investment.valuation.replacingOccurrences(of: ",", with: "")) ?? 0)) (computed at \(investment.irr)% IRR)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Valuation: $\(ContentView.formatWithCommas(Double(investment.valuation.replacingOccurrences(of: ",", with: "")) ?? 0)) (specified)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddFollowOnInvestmentView: View {
    @State private var investment: FollowOnInvestment
    @Environment(\.dismiss) private var dismiss
    let onSave: (FollowOnInvestment) -> Void
    
    init(investment: FollowOnInvestment, onSave: @escaping (FollowOnInvestment) -> Void) {
        self._investment = State(initialValue: investment)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Timing Type Selection
                Picker("Timing Type", selection: $investment.timingType) {
                    ForEach(TimingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Conditional timing input based on selection
                if investment.timingType == .absoluteDate {
                    DatePicker("Investment Date", selection: $investment.date, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                } else {
                    HStack {
                        InputField(
                            title: "Time After Initial Investment",
                            placeholder: "Enter number (e.g., 6)",
                            value: $investment.relativeAmount,
                            icon: "clock.fill",
                            isCurrency: false
                        )
                        
                        Picker("Unit", selection: $investment.relativeUnit) {
                            ForEach(TimeUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                }
                
                InputField(
                    title: "Investment Amount",
                    placeholder: "Enter amount (e.g., 5,000)",
                    value: $investment.amount,
                    icon: "dollarsign.circle.fill",
                    isCurrency: true
                )
                
                Picker("Valuation Type", selection: $investment.valuationType) {
                    ForEach(ValuationType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if investment.valuationType == .computed {
                    InputField(
                        title: "IRR for Valuation",
                        placeholder: "Enter IRR percentage (e.g., 8.5)",
                        value: $investment.irr,
                        icon: "percent",
                        isCurrency: false
                    )
                } else {
                    InputField(
                        title: "Specified Valuation",
                        placeholder: "Enter valuation amount (e.g., 7,500)",
                        value: $investment.valuation,
                        icon: "chart.bar.fill",
                        isCurrency: true
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Follow-on Investment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Calculate computed valuation if needed
                        if investment.valuationType == .computed {
                            let amount = Double(investment.amount.replacingOccurrences(of: ",", with: "")) ?? 0
                            let irr = Double(investment.irr) ?? 0
                            let months = Calendar.current.dateComponents([.month], from: Date(), to: investment.investmentDate).month ?? 0
                            let years = Double(months) / 12.0
                            let computedValuation = amount * pow(1 + irr/100, years)
                            investment.valuation = String(format: "%.2f", computedValuation)
                        }
                        onSave(investment)
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")
        
        guard !investment.amount.isEmpty,
              Double(cleanAmount) != nil,
              Double(cleanAmount) ?? 0 > 0 else {
            return false
        }
        
        // Validate timing input
        if investment.timingType == .relativeTime {
            guard !investment.relativeAmount.isEmpty,
                  Double(investment.relativeAmount) != nil,
                  Double(investment.relativeAmount) ?? 0 > 0 else {
                return false
            }
        }
        
        if investment.valuationType == .computed {
            return !investment.irr.isEmpty && Double(investment.irr) != nil
        } else {
            let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
            return !investment.valuation.isEmpty && Double(cleanValuation) != nil && Double(cleanValuation) ?? 0 > 0
        }
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
                        Text("$\(ContentView.formatWithCommas(outcome - initial))")
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
                .fill(Color.primary.opacity(0.05))
                .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
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
        case .calculateBlendedIRR:
            return "Blended IRR:"
        }
    }
    
    private var resultDisplay: String {
        switch mode {
        case .calculateIRR:
            return String(format: "%.2f%%", result)
        case .calculateOutcome, .calculateInitial:
            return "$\(ContentView.formatWithCommas(result))"
        case .calculateBlendedIRR:
            return String(format: "%.2f%%", result)
        }
    }
    
    private func inputDisplay(for key: String, value: Double) -> String {
        switch key {
        case "IRR":
            return String(format: "%.2f%%", value)
        case "Time Period (Months)":
            return "\(ContentView.formatWithCommas(value, fractionDigits: 0)) months"
        case "Time Period (Years)":
            return "\(ContentView.formatWithCommas(value, fractionDigits: 2)) years"
        case "Initial Investment", "Outcome Amount", "Target Outcome Amount":
            return "$\(ContentView.formatWithCommas(value))"
        default:
            return ContentView.formatWithCommas(value)
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

struct GrowthPoint: Identifiable {
    let month: Int
    let value: Double
    var id: Int { month }
}

struct GrowthChartView: View {
    let data: [GrowthPoint]
    @State private var selectedMonth: Int? = nil
    
    private var yAxisRange: ClosedRange<Double> {
        let minValue = data.map { $0.value }.min() ?? 0
        let maxValue = data.map { $0.value }.max() ?? 0
        return minValue...maxValue
    }

    // Helper for drag gesture
    private func handleDrag(location: CGPoint) {
        let totalMonths = data.count - 1
        if totalMonths > 0 {
            let estimatedChartWidth: CGFloat = 350
            let clampedX = max(0, min(location.x, estimatedChartWidth))
            let percent = clampedX / estimatedChartWidth
            let monthIndex = Int(round(percent * Double(totalMonths)))
            self.selectedMonth = min(max(monthIndex, 0), totalMonths)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Growth Over Time")
                .font(.headline)
                .padding(.top, 8)
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.monotone)
                    PointMark(
                        x: .value("Month", point.month),
                        y: .value("Value", point.value)
                    )
                }
                if let selectedMonth = selectedMonth, let selectedPoint = data.first(where: { $0.month == selectedMonth }) {
                    RuleMark(x: .value("Month", selectedMonth))
                        .foregroundStyle(Color.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                        .annotation(position: .top, alignment: .center) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.1))
                                    .shadow(radius: 2)
                                VStack(spacing: 2) {
                                    Text("Month: \(selectedMonth)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("$\(ContentView.formatWithCommas(selectedPoint.value))")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                .padding(4)
                            }
                        }
                }
            }
            .frame(height: 180)
            .chartXAxisLabel("Month")
            .chartYAxisLabel("Value ($)")
            .chartXScale(domain: 0...(data.last?.month ?? 0))
            .chartYScale(domain: yAxisRange)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(location: value.location)
                    }
            )
            .onTapGesture {
                self.selectedMonth = nil
            }
        }
        .padding(.horizontal)
    }
}

