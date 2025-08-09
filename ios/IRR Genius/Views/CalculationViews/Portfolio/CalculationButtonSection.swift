//
//  CalculationButtonSection.swift
//  IRR Genius
//
//  Enhanced calculation button with validation
//

import SwiftUI

struct CalculationButtonSection: View {
    let title: String
    let isCalculating: Bool
    let isInputValid: Bool
    @Binding var showingValidationDetails: Bool
    let validateInputs: () -> [String]
    let onCalculate: () -> Void

    var body: some View {
        CalculateButton(
            title: title,
            isLoading: isCalculating,
            action: {
                let errors = validateInputs()
                if errors.isEmpty {
                    onCalculate()
                } else {
                    showingValidationDetails = true
                }
            }
        )
        .disabled(!isInputValid)
    }
}

// Preview
struct CalculationButtonSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CalculationButtonSection(
                title: "Calculate Portfolio IRR",
                isCalculating: false,
                isInputValid: true,
                showingValidationDetails: .constant(false),
                validateInputs: { [] },
                onCalculate: {}
            )

            CalculationButtonSection(
                title: "Calculate Portfolio IRR",
                isCalculating: true,
                isInputValid: true,
                showingValidationDetails: .constant(false),
                validateInputs: { [] },
                onCalculate: {}
            )

            CalculationButtonSection(
                title: "Calculate Portfolio IRR",
                isCalculating: false,
                isInputValid: false,
                showingValidationDetails: .constant(false),
                validateInputs: { ["Error"] },
                onCalculate: {}
            )
        }
        .padding()
    }
}
