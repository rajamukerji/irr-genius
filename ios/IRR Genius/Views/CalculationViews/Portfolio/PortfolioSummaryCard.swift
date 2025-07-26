//
//  PortfolioSummaryCard.swift
//  IRR Genius
//
//  Portfolio summary metrics display component
//

import SwiftUI

struct PortfolioSummaryCard: View {
    let numberOfUnits: String
    let totalUnits: Double
    let totalFollowOnUnits: Double
    let totalInvestment: Double
    let averageUnitPrice: Double
    let followOnInvestments: [FollowOnInvestment]
    let validationErrors: [String]
    @Binding var showingValidationDetails: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Portfolio Summary")
                    .font(.headline)
                Spacer()
                
                if !validationErrors.isEmpty {
                    Button(action: { showingValidationDetails.toggle() }) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            VStack(spacing: 6) {
                // Initial investment metrics
                HStack {
                    Text("Initial Units:")
                    Spacer()
                    Text("\(NumberFormatting.formatNumber(Double(numberOfUnits) ?? 0))")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Expected Successful Units:")
                    Spacer()
                    Text("\(NumberFormatting.formatNumber(totalUnits))")
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                if !followOnInvestments.isEmpty {
                    HStack {
                        Text("Follow-on Units:")
                        Spacer()
                        Text("\(NumberFormatting.formatNumber(totalFollowOnUnits))")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Total Portfolio Units:")
                        Spacer()
                        Text("\(NumberFormatting.formatNumber(totalUnits + totalFollowOnUnits))")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total Investment:")
                    Spacer()
                    Text(NumberFormatting.formatCurrency(totalInvestment))
                        .fontWeight(.medium)
                }
                
                if averageUnitPrice > 0 {
                    HStack {
                        Text("Average Unit Price:")
                        Spacer()
                        Text(NumberFormatting.formatCurrency(averageUnitPrice))
                            .fontWeight(.medium)
                    }
                }
                
                if !followOnInvestments.isEmpty {
                    HStack {
                        Text("Investment Batches:")
                        Spacer()
                        Text("\(followOnInvestments.count + 1)")
                            .fontWeight(.medium)
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Preview
struct PortfolioSummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PortfolioSummaryCard(
                numberOfUnits: "10000",
                totalUnits: 8000,
                totalFollowOnUnits: 2000,
                totalInvestment: 120000,
                averageUnitPrice: 12.0,
                followOnInvestments: [FollowOnInvestment(
                    timingType: .absoluteDate,
                    date: Date(),
                    relativeAmount: "0",
                    relativeUnit: .months,
                    investmentType: .buy,
                    amount: "20000",
                    valuationMode: .custom,
                    valuation: "15"
                )],
                validationErrors: [],
                showingValidationDetails: .constant(false)
            )
            
            PortfolioSummaryCard(
                numberOfUnits: "5000",
                totalUnits: 4000,
                totalFollowOnUnits: 0,
                totalInvestment: 50000,
                averageUnitPrice: 10.0,
                followOnInvestments: [],
                validationErrors: ["Sample error"],
                showingValidationDetails: .constant(false)
            )
        }
        .padding()
    }
}