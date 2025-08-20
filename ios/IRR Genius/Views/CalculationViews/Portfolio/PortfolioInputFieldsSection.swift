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
    @Binding var numberOfUnits: String  // Auto-calculated
    @Binding var successRate: String
    @Binding var timeInMonths: String
    @Binding var outcomePerUnit: String
    @Binding var topLineFees: String
    @Binding var managementFees: String
    @Binding var investorShare: String
    @Binding var investmentType: String

    // Auto-calculate units when investment or price changes
    private var calculatedUnits: String {
        let cleanInvestment = initialInvestment.replacingOccurrences(of: ",", with: "")
        let cleanPrice = unitPrice.replacingOccurrences(of: ",", with: "")
        guard let investment = Double(cleanInvestment),
              let price = Double(cleanPrice),
              price > 0 else { return "0" }
        let units = investment / price
        return String(format: "%.2f", units)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Investment Type Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Investment Type")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 8) {
                    ForEach(["litigation", "patent", "debt"], id: \.self) { type in
                        Button(action: { investmentType = type }) {
                            Text(type.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(investmentType == type ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(investmentType == type ? .white : .primary)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            Text("Initial Investment")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            InputField(
                title: "Initial Investment Amount",
                placeholder: "Enter initial investment amount",
                text: $initialInvestment,
                formatType: InputField.FormatType.currency
            )
            .onChange(of: initialInvestment) {
                numberOfUnits = calculatedUnits
            }

            HStack(spacing: 12) {
                InputField(
                    title: "Unit Price",
                    placeholder: "Price per unit",
                    text: $unitPrice,
                    formatType: .currency
                )
                .onChange(of: unitPrice) {
                    numberOfUnits = calculatedUnits
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Number of Units")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(calculatedUnits)
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            InputField(
                title: "Expected Outcome per \(investmentType == "litigation" ? "Case" : investmentType == "patent" ? "Patent" : "Unit")",
                placeholder: investmentType == "litigation" ? "Settlement per case" : "Revenue per unit",
                text: $outcomePerUnit,
                formatType: .currency
            )
            
            HStack(spacing: 12) {
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
            
            // Fee Structure Section
            Text("Fee Structure")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            
            HStack(spacing: 12) {
                InputField(
                    title: investmentType == "litigation" ? "MDL Committee Fee (%)" : "Top-Line Fee (%)",
                    placeholder: "0-10",
                    text: $topLineFees,
                    formatType: .number
                )
                
                InputField(
                    title: "Plaintiff Counsel (%)",
                    placeholder: "40",
                    text: $managementFees,
                    formatType: .number
                )
            }
            
            InputField(
                title: "Investor Share (%)",
                placeholder: "Your share after fees",
                text: $investorShare,
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
            timeInMonths: .constant("60"),
            outcomePerUnit: .constant("450000"),
            topLineFees: .constant("6"),
            managementFees: .constant("40"),
            investorShare: .constant("42.5"),
            investmentType: .constant("litigation")
        )
        .padding()
    }
}
