//
//  BlendedIRRCalculationView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

struct BlendedIRRCalculationView: View {
    @Binding var initialInvestment: String
    @Binding var initialDate: Date
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
            // Title
            Text("Calculate Blended IRR")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Input fields
            VStack(spacing: 16) {
                InputField(
                    title: "Initial Investment",
                    placeholder: "Enter initial investment amount",
                    text: $initialInvestment,
                    formatType: .currency
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Initial Investment Date")
                        .font(.headline)
                        .foregroundColor(.primary)

                    DatePicker("", selection: $initialDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                }

                InputField(
                    title: "Final Valuation",
                    placeholder: "Enter final portfolio value",
                    text: $finalValuation,
                    formatType: .currency
                )

                InputField(
                    title: "Total Time Period (Months)",
                    placeholder: "Enter total time period in months",
                    text: $timeInMonths,
                    formatType: .number
                )
            }

            // Follow-on Investments Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Follow-on Investments")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Button("Add Investment") {
                        showingAddInvestment = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                if followOnInvestments.isEmpty {
                    Text("No follow-on investments added yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
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

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Calculate button
            CalculateButton(
                title: "Calculate Blended IRR",
                isLoading: isCalculating,
                action: onCalculate
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
