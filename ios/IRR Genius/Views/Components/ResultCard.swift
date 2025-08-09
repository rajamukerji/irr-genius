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

        if mode == .calculateIRR || mode == .calculateBlendedIRR {
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
}
