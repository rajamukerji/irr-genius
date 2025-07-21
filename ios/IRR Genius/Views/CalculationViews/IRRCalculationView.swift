//
//  IRRCalculationView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

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
            // Title
            Text("Calculate IRR")
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
                
                InputField(
                    title: "Outcome Amount",
                    placeholder: "Enter final outcome amount",
                    text: $outcomeAmount,
                    formatType: .currency
                )
                
                InputField(
                    title: "Time Period (Months)",
                    placeholder: "Enter time period in months",
                    text: $timeInMonths,
                    formatType: .number
                )
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
                title: "Calculate IRR",
                isLoading: isCalculating,
                action: onCalculate
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 