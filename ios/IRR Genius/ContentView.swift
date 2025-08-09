//
//  ContentView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @State private var selectedMode: CalculationMode = .calculateIRR
    @State private var showingLoadCalculation = false

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
    @State private var blendedInitialDate: Date = .init()
    @State private var blendedFinalValuation: String = ""
    @State private var blendedTimeInMonths: String = ""
    @State private var followOnInvestments: [FollowOnInvestment] = []
    @State private var showingAddInvestment = false

    // Portfolio Unit Investment inputs
    @State private var portfolioInitialInvestment: String = ""
    @State private var portfolioUnitPrice: String = ""
    @State private var portfolioNumberOfUnits: String = ""
    @State private var portfolioSuccessRate: String = "100"
    @State private var portfolioTimeInMonths: String = ""
    @State private var portfolioInitialDate: Date = .init()
    @State private var portfolioFollowOnInvestments: [FollowOnInvestment] = []
    @State private var showingAddPortfolioInvestment = false

    @State private var calculatedResult: Double?
    @State private var showingResult = false
    @State private var isCalculating = false
    @State private var errorMessage: String?

    var body: some View {
        configuredMainView
    }

    private var configuredMainView: some View {
        mainView
            .sheet(isPresented: $showingAddInvestment) {
                AddFollowOnInvestmentView(
                    isPresented: $showingAddInvestment,
                    followOnInvestments: $followOnInvestments,
                    initialInvestmentDate: blendedInitialDate
                )
            }
            .sheet(isPresented: $showingAddPortfolioInvestment) {
                AddPortfolioFollowOnInvestmentView(
                    isPresented: $showingAddPortfolioInvestment,
                    followOnInvestments: $portfolioFollowOnInvestments,
                    initialInvestmentDate: portfolioInitialDate
                )
            }
            .sheet(isPresented: $dataManager.saveDialogData.isVisible) {
                SaveCalculationDialog()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showingLoadCalculation) {
                LoadCalculationView(isPresented: $showingLoadCalculation) { calculation in
                    loadCalculation(calculation)
                }
                .environmentObject(dataManager)
            }
            .environmentObject(dataManager)
            .loadingState(dataManager.loadingState) {
                // Retry action for failed operations
                Task {
                    await dataManager.loadCalculations()
                }
            }
            .overlay(alignment: .top) {
                BackgroundSyncIndicator(
                    isVisible: .constant(dataManager.isSyncing),
                    message: "Syncing..."
                )
                .padding(.top, 8)
            }
    }

    // MARK: - Computed Properties

    @ViewBuilder
    private var mainView: some View {
        HStack {
            Spacer(minLength: 0)
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HeaderView()

                    // Mode Selector
                    ModeSelectorView(selectedMode: $selectedMode)

                    // Load Calculation Button
                    Button(action: { showingLoadCalculation = true }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Load Calculation")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Input Form based on selected mode
                    calculationView

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

    @ViewBuilder
    private var calculationView: some View {
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
        case .portfolioUnitInvestment:
            PortfolioUnitInvestmentView(
                initialInvestment: $portfolioInitialInvestment,
                unitPrice: $portfolioUnitPrice,
                numberOfUnits: $portfolioNumberOfUnits,
                successRate: $portfolioSuccessRate,
                timeInMonths: $portfolioTimeInMonths,
                followOnInvestments: $portfolioFollowOnInvestments,
                calculatedResult: $calculatedResult,
                isCalculating: $isCalculating,
                errorMessage: $errorMessage,
                showingAddInvestment: $showingAddPortfolioInvestment,
                onCalculate: calculatePortfolioUnitInvestment
            )
        }
    }

    // MARK: - Calculation Methods

    private func calculateIRR() {
        let cleanInitial = initialInvestment.replacingOccurrences(of: ",", with: "")
        let cleanOutcome = outcomeAmount.replacingOccurrences(of: ",", with: "")

        guard let initial = Double(cleanInitial),
              let outcome = Double(cleanOutcome),
              let months = Double(timeInMonths),
              initial > 0, outcome > 0, months > 0
        else {
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

            // Trigger auto-save
            let inputs = getInputsForMode()
            let growthPoints = chartDataForCurrentInputs()
            dataManager.handleCalculationCompleted(
                calculationType: selectedMode,
                inputs: inputs,
                result: irr,
                growthPoints: growthPoints
            )
        }
    }

    private func calculateOutcome() {
        let cleanInitial = outcomeInitialInvestment.replacingOccurrences(of: ",", with: "")

        guard let initial = Double(cleanInitial),
              let irr = Double(outcomeIRR),
              let months = Double(outcomeTimeInMonths),
              initial > 0, months > 0
        else {
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

            // Trigger auto-save
            let inputs = getInputsForMode()
            let growthPoints = chartDataForCurrentInputs()
            dataManager.handleCalculationCompleted(
                calculationType: selectedMode,
                inputs: inputs,
                result: outcome,
                growthPoints: growthPoints
            )
        }
    }

    private func calculateInitialInvestment() {
        let cleanOutcome = initialOutcomeAmount.replacingOccurrences(of: ",", with: "")

        guard let outcome = Double(cleanOutcome),
              let irr = Double(initialIRR),
              let months = Double(initialTimeInMonths),
              outcome > 0, months > 0
        else {
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

            // Trigger auto-save
            let inputs = getInputsForMode()
            let growthPoints = chartDataForCurrentInputs()
            dataManager.handleCalculationCompleted(
                calculationType: selectedMode,
                inputs: inputs,
                result: initial,
                growthPoints: growthPoints
            )
        }
    }

    private func calculateBlendedIRR() {
        let cleanInitial = blendedInitialInvestment.replacingOccurrences(of: ",", with: "")
        let cleanFinalValuation = blendedFinalValuation.replacingOccurrences(of: ",", with: "")

        guard let initial = Double(cleanInitial),
              let finalValuation = Double(cleanFinalValuation),
              let totalMonths = Double(blendedTimeInMonths)
        else {
            errorMessage = "Please enter valid numbers"
            return
        }

        // Validate follow-on investments
        for investment in followOnInvestments {
            let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")

            guard let amount = Double(cleanAmount),
                  amount > 0
            else {
                errorMessage = "Please enter valid amounts for all follow-on investments"
                return
            }

            // For custom valuations, validate the valuation field
            if investment.valuationMode == .custom {
                let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
                guard let valuation = Double(cleanValuation),
                      valuation > 0
                else {
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

            // Trigger auto-save
            let inputs = getInputsForMode()
            let growthPoints = chartDataForCurrentInputs()
            dataManager.handleCalculationCompleted(
                calculationType: selectedMode,
                inputs: inputs,
                result: blendedIRR,
                growthPoints: growthPoints
            )
        }
    }

    private func calculatePortfolioUnitInvestment() {
        let cleanInitial = portfolioInitialInvestment.replacingOccurrences(of: ",", with: "")
        let cleanUnitPrice = portfolioUnitPrice.replacingOccurrences(of: ",", with: "")

        guard let initialInvestment = Double(cleanInitial),
              let unitPrice = Double(cleanUnitPrice),
              let numberOfUnits = Double(portfolioNumberOfUnits),
              let successRate = Double(portfolioSuccessRate),
              let months = Double(portfolioTimeInMonths),
              initialInvestment > 0, unitPrice > 0, numberOfUnits > 0,
              successRate > 0, successRate <= 100, months > 0
        else {
            errorMessage = "Please enter valid numbers"
            return
        }

        // Validate follow-on investments
        for investment in portfolioFollowOnInvestments {
            let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")
            let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")

            guard let amount = Double(cleanAmount),
                  let valuation = Double(cleanValuation),
                  amount > 0, valuation > 0
            else {
                errorMessage = "Please enter valid amounts and unit prices for all follow-on investments"
                return
            }
        }

        isCalculating = true
        errorMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let years = months / 12.0
            let successRateDecimal = successRate / 100.0
            let successfulUnits = numberOfUnits * successRateDecimal

            // Calculate total investment including follow-ons
            let followOnTotal = portfolioFollowOnInvestments.compactMap { investment in
                Double(investment.amount.replacingOccurrences(of: ",", with: ""))
            }.reduce(0, +)
            let totalInvestment = initialInvestment + followOnTotal

            // Calculate expected outcome based on successful units
            // Simplified calculation: assume 2x return on successful units
            let expectedOutcome = successfulUnits * unitPrice * 2.0

            // Calculate portfolio IRR
            let portfolioIRR = if portfolioFollowOnInvestments.isEmpty {
                IRRCalculator.calculateIRRValue(
                    initialInvestment: totalInvestment,
                    outcomeAmount: expectedOutcome,
                    timeInYears: years
                )
            } else {
                // Use blended IRR calculation for complex scenarios
                IRRCalculator.calculateBlendedIRRValue(
                    initialInvestment: initialInvestment,
                    followOnInvestments: portfolioFollowOnInvestments,
                    finalValuation: expectedOutcome,
                    totalTimeInYears: years
                )
            }

            calculatedResult = portfolioIRR
            isCalculating = false
            showingResult = true

            // Trigger auto-save
            let inputs = getInputsForMode()
            let growthPoints = chartDataForCurrentInputs()
            dataManager.handleCalculationCompleted(
                calculationType: selectedMode,
                inputs: inputs,
                result: portfolioIRR,
                growthPoints: growthPoints
            )
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
                "Time Period (Years)": months / 12.0,
            ]
        case .calculateOutcome:
            let cleanInitial = outcomeInitialInvestment.replacingOccurrences(of: ",", with: "")
            let months = Double(outcomeTimeInMonths) ?? 0
            return [
                "Initial Investment": Double(cleanInitial) ?? 0,
                "IRR": Double(outcomeIRR) ?? 0,
                "Time Period (Months)": months,
                "Time Period (Years)": months / 12.0,
            ]
        case .calculateInitial:
            let cleanOutcome = initialOutcomeAmount.replacingOccurrences(of: ",", with: "")
            let months = Double(initialTimeInMonths) ?? 0
            return [
                "Outcome Amount": Double(cleanOutcome) ?? 0,
                "IRR": Double(initialIRR) ?? 0,
                "Time Period (Months)": months,
                "Time Period (Years)": months / 12.0,
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
                "Follow-on Investments": Double(followOnInvestments.count),
            ]
        case .portfolioUnitInvestment:
            let cleanInitial = portfolioInitialInvestment.replacingOccurrences(of: ",", with: "")
            let cleanUnitPrice = portfolioUnitPrice.replacingOccurrences(of: ",", with: "")
            let months = Double(portfolioTimeInMonths) ?? 0
            let units = Double(portfolioNumberOfUnits) ?? 0
            let successRate = Double(portfolioSuccessRate) ?? 100
            let successfulUnits = units * (successRate / 100.0)
            return [
                "Initial Investment": Double(cleanInitial) ?? 0,
                "Unit Price": Double(cleanUnitPrice) ?? 0,
                "Number of Units": units,
                "Success Rate (%)": successRate,
                "Expected Successful Units": successfulUnits,
                "Time Period (Months)": months,
                "Time Period (Years)": months / 12.0,
                "Follow-on Batches": Double(portfolioFollowOnInvestments.count),
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
        case .portfolioUnitInvestment:
            guard let initial = Double(portfolioInitialInvestment.replacingOccurrences(of: ",", with: "")),
                  let unitPrice = Double(portfolioUnitPrice.replacingOccurrences(of: ",", with: "")),
                  let numberOfUnits = Double(portfolioNumberOfUnits),
                  let successRate = Double(portfolioSuccessRate),
                  let monthsDouble = Double(portfolioTimeInMonths),
                  initial > 0, unitPrice > 0, numberOfUnits > 0, successRate > 0 else { return nil }
            let months = Int(monthsDouble)
            guard months > 0 else { return nil }

            let successRateDecimal = successRate / 100.0
            let successfulUnits = numberOfUnits * successRateDecimal
            let expectedOutcome = successfulUnits * unitPrice * 2.0 // Simplified 2x return

            if portfolioFollowOnInvestments.isEmpty {
                let years = Double(months) / 12.0
                let irr = IRRCalculator.calculateIRRValue(
                    initialInvestment: initial,
                    outcomeAmount: expectedOutcome,
                    timeInYears: years
                ) / 100.0
                return IRRCalculator.growthPoints(initial: initial, rate: irr, months: months)
            } else {
                return IRRCalculator.growthPointsWithFollowOn(
                    initial: initial,
                    followOnInvestments: portfolioFollowOnInvestments,
                    finalValuation: expectedOutcome,
                    months: months
                )
            }
        }
    }

    // MARK: - Auto-Save Methods

    private func updateInputTracking() {
        let inputs = getInputsForMode()
        dataManager.updateInputs(inputs)
    }

    // MARK: - Calculation Loading Methods

    private func loadCalculation(_ calculation: SavedCalculation) {
        // Clear current results
        calculatedResult = nil
        errorMessage = nil

        // Set the calculation mode
        selectedMode = calculation.calculationType

        // Populate form fields based on calculation type
        switch calculation.calculationType {
        case .calculateIRR:
            initialInvestment = formatCurrency(calculation.initialInvestment)
            outcomeAmount = formatCurrency(calculation.outcomeAmount)
            timeInMonths = formatNumber(calculation.timeInMonths)
            calculatedResult = calculation.calculatedResult

        case .calculateOutcome:
            outcomeInitialInvestment = formatCurrency(calculation.initialInvestment)
            outcomeIRR = formatNumber(calculation.irr)
            outcomeTimeInMonths = formatNumber(calculation.timeInMonths)
            calculatedResult = calculation.calculatedResult

        case .calculateInitial:
            initialOutcomeAmount = formatCurrency(calculation.outcomeAmount)
            initialIRR = formatNumber(calculation.irr)
            initialTimeInMonths = formatNumber(calculation.timeInMonths)
            calculatedResult = calculation.calculatedResult

        case .calculateBlendedIRR:
            blendedInitialInvestment = formatCurrency(calculation.initialInvestment)
            blendedFinalValuation = formatCurrency(calculation.outcomeAmount)
            blendedTimeInMonths = formatNumber(calculation.timeInMonths)
            followOnInvestments = calculation.followOnInvestments ?? []
            calculatedResult = calculation.calculatedResult

        case .portfolioUnitInvestment:
            portfolioInitialInvestment = formatCurrency(calculation.initialInvestment)
            portfolioUnitPrice = formatCurrency(calculation.unitPrice)
            portfolioNumberOfUnits = formatNumber(calculation.outcomePerUnit) // Using outcomePerUnit as number of units
            portfolioSuccessRate = formatNumber(calculation.successRate)
            portfolioTimeInMonths = formatNumber(calculation.timeInMonths)
            portfolioFollowOnInvestments = calculation.followOnInvestments ?? []
            calculatedResult = calculation.calculatedResult
        }

        // Clear unsaved changes since we just loaded a calculation
        dataManager.clearUnsavedChanges()
    }

    private func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "" }
        return String(format: "%.2f", value)
    }

    private func formatNumber(_ value: Double?) -> String {
        guard let value = value else { return "" }
        return String(format: "%.0f", value)
    }
}
