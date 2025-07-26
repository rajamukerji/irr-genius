//
//  PortfolioUnitInvestmentView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/24/25.
//

import SwiftUI
import Foundation
import UIKit

struct PortfolioUnitInvestmentView: View {
    @Binding var initialInvestment: String
    @Binding var unitPrice: String
    @Binding var numberOfUnits: String
    @Binding var successRate: String
    @Binding var timeInMonths: String
    @Binding var followOnInvestments: [FollowOnInvestment]
    @Binding var calculatedResult: Double?
    @Binding var isCalculating: Bool
    @Binding var errorMessage: String?
    @Binding var showingAddInvestment: Bool
    let onCalculate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Portfolio Unit Investment")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Basic input fields
            VStack(spacing: 16) {
                InputField(
                    title: "Initial Investment Amount",
                    placeholder: "Enter initial investment amount",
                    text: $initialInvestment,
                    formatType: .currency
                )
                
                HStack(spacing: 12) {
                    InputField(
                        title: "Unit Price",
                        placeholder: "Price per unit",
                        text: $unitPrice,
                        formatType: .currency
                    )
                    
                    InputField(
                        title: "Number of Units",
                        placeholder: "Units purchased",
                        text: $numberOfUnits,
                        formatType: .number
                    )
                }
                
                InputField(
                    title: "Success Rate (%)",
                    placeholder: "Expected success rate",
                    text: $successRate,
                    formatType: .number
                )
                
                InputField(
                    title: "Time Period (Months)",
                    placeholder: "Investment time horizon",
                    text: $timeInMonths,
                    formatType: .number
                )
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            // Follow-on investments placeholder
            VStack(alignment: .leading, spacing: 12) {
                Text("Follow-on Investments")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Follow-on investments: \(followOnInvestments.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Add Follow-on Investment") {
                    showingAddInvestment = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            // Calculate button
            CalculateButton(
                title: "Calculate Portfolio IRR",
                isLoading: isCalculating,
                action: onCalculate
            )
            .disabled(initialInvestment.isEmpty || unitPrice.isEmpty)
            
            // Results display
            if let result = calculatedResult {
                VStack(spacing: 8) {
                    Text("Portfolio IRR")
                        .font(.headline)
                    Text("\(String(format: "%.2f", result))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Error message
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
}

// Simple preview
struct PortfolioUnitInvestmentView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioUnitInvestmentView(
            initialInvestment: .constant("100000"),
            unitPrice: .constant("10"),
            numberOfUnits: .constant("10000"),
            successRate: .constant("80"),
            timeInMonths: .constant("60"),
            followOnInvestments: .constant([]),
            calculatedResult: .constant(15.5),
            isCalculating: .constant(false),
            errorMessage: .constant(nil),
            showingAddInvestment: .constant(false),
            onCalculate: {}
        )
    }
}