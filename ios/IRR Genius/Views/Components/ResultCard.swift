//
//  ResultCard.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

struct ResultCard: View {
    let mode: CalculationMode
    let result: Double
    let inputs: [String: Double]
    
    @EnvironmentObject var dataManager: DataManager

    private var resultTitle: String {
        switch mode {
        case .calculateIRR:
            return "Internal Rate of Return"
        case .calculateOutcome:
            return "Final Outcome"
        case .calculateInitial:
            return "Required Initial Investment"
        case .calculateBlendedIRR:
            return "Blended IRR"
        case .portfolioUnitInvestment:
            return "Portfolio Unit IRR"
        }
    }

    private var resultUnit: String {
        switch mode {
        case .calculateIRR, .calculateBlendedIRR, .portfolioUnitInvestment:
            return "%"
        case .calculateOutcome, .calculateInitial:
            return ""
        }
    }

    private var formattedResult: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        if mode == .calculateIRR || mode == .calculateBlendedIRR || mode == .portfolioUnitInvestment {
            return "\(formatter.string(from: NSNumber(value: result)) ?? String(format: "%.2f", result))%"
        } else {
            formatter.groupingSeparator = ","
            return "$\(formatter.string(from: NSNumber(value: result)) ?? String(format: "%.2f", result))"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Result
            VStack(spacing: 8) {
                Text(resultTitle)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(formattedResult)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            }

            // Inputs used
            VStack(alignment: .leading, spacing: 8) {
                Text("Inputs Used:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(Array(inputs.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatInputValue(inputs[key] ?? 0, for: key))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Save button
            Button(action: {
                saveCalculation()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Calculation")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private func formatInputValue(_ value: Double, for key: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2

        if key.contains("Investment") || key.contains("Amount") || key.contains("Valuation") {
            formatter.groupingSeparator = ","
            return "$\(formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))"
        } else if key.contains("IRR") {
            return "\(formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))%"
        } else if key.contains("Time") {
            return "\(formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value))"
        } else {
            return "\(formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value))"
        }
    }
    
    private func saveCalculation() {
        // Create a calculation from current inputs and results
        let calculation = createCalculationFromInputs()
        dataManager.showSaveDialog(for: calculation)
    }
    
    private func createCalculationFromInputs() -> SavedCalculation {
        let growthPoints = generateGrowthPoints()
        
        do {
            switch mode {
            case .calculateIRR:
                return try SavedCalculation(
                    name: "Untitled IRR Calculation",
                    calculationType: mode,
                    initialInvestment: inputs["Initial Investment"],
                    outcomeAmount: inputs["Outcome Amount"],
                    timeInMonths: inputs["Time Period (Months)"],
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
                
            case .calculateOutcome:
                return try SavedCalculation(
                    name: "Untitled Outcome Calculation",
                    calculationType: mode,
                    initialInvestment: inputs["Initial Investment"],
                    timeInMonths: inputs["Time Period (Months)"],
                    irr: inputs["IRR"],
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
                
            case .calculateInitial:
                return try SavedCalculation(
                    name: "Untitled Initial Investment Calculation",
                    calculationType: mode,
                    outcomeAmount: inputs["Outcome Amount"],
                    timeInMonths: inputs["Time Period (Months)"],
                    irr: inputs["IRR"],
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
                
            case .calculateBlendedIRR:
                return try SavedCalculation(
                    name: "Untitled Blended IRR Calculation",
                    calculationType: mode,
                    initialInvestment: inputs["Initial Investment"],
                    outcomeAmount: inputs["Final Valuation"],
                    timeInMonths: inputs["Time Period (Months)"],
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
                
            case .portfolioUnitInvestment:
                return try SavedCalculation(
                    name: "Untitled Portfolio Unit Investment",
                    calculationType: mode,
                    initialInvestment: inputs["Initial Investment"],
                    timeInMonths: inputs["Time Period (Months)"],
                    unitPrice: inputs["Unit Price"],
                    successRate: inputs["Success Rate (%)"],
                    outcomePerUnit: inputs["Expected Outcome per Unit"],
                    investorShare: inputs["Investor Share (%)"],
                    feePercentage: inputs["Top-Line Fees (%)"],
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
            }
        } catch {
            // Return a minimal calculation if there's an error
            return try! SavedCalculation(
                name: "Untitled Calculation",
                calculationType: mode,
                calculatedResult: result
            )
        }
    }
    
    private func generateGrowthPoints() -> [GrowthPoint] {
        guard let timeInMonths = inputs["Time Period (Months)"],
              timeInMonths > 0 else { return [] }
        
        let months = Int(timeInMonths)
        let monthlyGrowthRate = pow(1 + result/100, 1.0/timeInMonths)
        var points: [GrowthPoint] = []
        
        if let initialInvestment = inputs["Initial Investment"] {
            for month in stride(from: 0, through: months, by: max(1, months/12)) {
                let value = initialInvestment * pow(monthlyGrowthRate, Double(month))
                points.append(GrowthPoint(month: month, value: value))
            }
        }
        
        return points
    }
}
