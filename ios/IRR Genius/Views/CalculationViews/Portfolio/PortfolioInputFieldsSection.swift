//
//  PortfolioInputFieldsSection.swift
//  IRR Genius
//
//  Portfolio input fields component
//

import SwiftUI

struct PortfolioInputFieldsSection: View {
    @Binding var initialInvestment: String
    @Binding var unitPrice: String
    @Binding var numberOfUnits: String
    @Binding var successRate: String
    @Binding var timeInMonths: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Initial Investment")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            InputField(
                title: "Initial Investment Amount",
                placeholder: "Enter initial investment amount",
                text: $initialInvestment,
                formatType: InputField.FormatType.currency
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
    }
}

// Preview
struct PortfolioInputFieldsSection_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioInputFieldsSection(
            initialInvestment: .constant("100000"),
            unitPrice: .constant("10"),
            numberOfUnits: .constant("10000"),
            successRate: .constant("80"),
            timeInMonths: .constant("60")
        )
        .padding()
    }
}