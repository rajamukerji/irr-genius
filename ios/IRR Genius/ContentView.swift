//
//  ContentView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

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
    @State private var blendedInitialDate: Date = Date()
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
                    HeaderView()
                    
                    // Mode Selector
                    ModeSelectorView(selectedMode: $selectedMode)
                    
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
                            initialDate: $blendedInitialDate,
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
    
    // MARK: - Calculation Methods
    
    private func calculateIRR() {
        let cleanInitial = initialInvestment.replacingOccurrences(of: ",", with: "")
        let cleanOutcome = outcomeAmount.replacingOccurrences(of: ",", with: "")
        
        guard let initial = Double(cleanInitial),
              let outcome = Double(cleanOutcome),
              let months = Double(timeInMonths),
              initial > 0, outcome > 0, months > 0 else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        isCalculating = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let years = months / 12.0
            let irr = IRRCalculator.calculateIRRValue(initialInvestment: initial, outcomeAmount: outcome, timeInYears: years)
            calculatedResult = irr
            isCalculating = false
            showingResult = true
        }
    }
    
    private func calculateOutcome() {
        let cleanInitial = outcomeInitialInvestment.replacingOccurrences(of: ",", with: "")
        
        guard let initial = Double(cleanInitial),
              let irr = Double(outcomeIRR),
              let months = Double(outcomeTimeInMonths),
              initial > 0, months > 0 else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        isCalculating = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let years = months / 12.0
            let outcome = IRRCalculator.calculateOutcomeValue(initialInvestment: initial, irr: irr, timeInYears: years)
            calculatedResult = outcome
            isCalculating = false
            showingResult = true
        }
    }
    
    private func calculateInitialInvestment() {
        let cleanOutcome = initialOutcomeAmount.replacingOccurrences(of: ",", with: "")
        
        guard let outcome = Double(cleanOutcome),
              let irr = Double(initialIRR),
              let months = Double(initialTimeInMonths),
              outcome > 0, months > 0 else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        isCalculating = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let years = months / 12.0
            let initial = IRRCalculator.calculateInitialValue(outcomeAmount: outcome, irr: irr, timeInYears: years)
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
            
            guard let amount = Double(cleanAmount),
                  amount > 0 else {
                errorMessage = "Please enter valid amounts for all follow-on investments"
                return
            }
            
            // For custom valuations, validate the valuation field
            if investment.valuationMode == .custom {
                let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
                guard let valuation = Double(cleanValuation),
                      valuation > 0 else {
                    errorMessage = "Please enter valid valuations for all custom follow-on investments"
                    return
                }
            }
        }
        
        isCalculating = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let totalYears = totalMonths / 12.0
            let blendedIRR = IRRCalculator.calculateBlendedIRRValue(
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
    
    // MARK: - Helper Methods
    
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
            return [
                "Initial Investment": Double(cleanInitial) ?? 0,
                "Final Valuation": Double(cleanFinalValuation) ?? 0,
                "Time Period (Months)": months,
                "Time Period (Years)": months / 12.0,
                "Follow-on Investments": Double(followOnInvestments.count)
            ]
        }
    }
    
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
            let irr = IRRCalculator.calculateIRRValue(initialInvestment: initial, outcomeAmount: outcome, timeInYears: years) / 100.0
            return IRRCalculator.growthPoints(initial: initial, rate: irr, months: months)
        case .calculateOutcome:
            guard let initial = Double(outcomeInitialInvestment.replacingOccurrences(of: ",", with: "")),
                  let irr = Double(outcomeIRR),
                  let monthsDouble = Double(outcomeTimeInMonths),
                  initial > 0 else { return nil }
            let months = Int(monthsDouble)
            guard months > 0 else { return nil }
            let rate = irr / 100.0
            return IRRCalculator.growthPoints(initial: initial, rate: rate, months: months)
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
            return IRRCalculator.growthPoints(initial: initial, rate: rate, months: months)
        case .calculateBlendedIRR:
            guard let initial = Double(blendedInitialInvestment.replacingOccurrences(of: ",", with: "")),
                  let finalValuation = Double(blendedFinalValuation.replacingOccurrences(of: ",", with: "")),
                  let monthsDouble = Double(blendedTimeInMonths),
                  initial > 0, finalValuation > 0 else { return nil }
            let months = Int(monthsDouble)
            guard months > 0 else { return nil }
            
            return IRRCalculator.growthPointsWithFollowOn(
                initial: initial,
                followOnInvestments: followOnInvestments,
                finalValuation: finalValuation,
                months: months
            )
        }
    }
} 