//
//  PortfolioFollowOnInvestmentRow.swift
//  IRR Genius
//
//  Individual follow-on investment row component
//

import SwiftUI

struct PortfolioFollowOnInvestmentRow: View {
    @Binding var investment: FollowOnInvestment
    let batchNumber: Int
    let showDetails: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    private var batchSummary: String {
        let amount = Double(investment.amount.replacingOccurrences(of: ",", with: "")) ?? 0
        let unitPrice = Double(investment.valuation.replacingOccurrences(of: ",", with: "")) ?? 0
        let units = unitPrice > 0 ? amount / unitPrice : 0.0
        return "\(NumberFormatting.formatNumber(units)) units @ \(NumberFormatting.formatCurrency(unitPrice))"
    }
    
    private var investmentAmount: Double {
        return Double(investment.amount.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    private var unitPrice: Double {
        return Double(investment.valuation.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    private var numberOfUnits: Double {
        return unitPrice > 0 ? investmentAmount / unitPrice : 0
    }
    
    private var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        switch investment.timingType {
        case .absoluteDate:
            return formatter.string(from: investment.date)
        case .relativeTime:
            return "\(investment.relativeAmount) \(investment.relativeUnit.rawValue.lowercased()) from initial"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Investment Batch")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Unit details
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Units")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(NumberFormatting.formatNumber(numberOfUnits))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Unit Price")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(NumberFormatting.formatCurrency(unitPrice))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total Investment")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(NumberFormatting.formatCurrency(investmentAmount))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Timing information
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(dateDisplay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Investment type badge
                    HStack {
                        Text(investment.investmentType.rawValue.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Text("Delete")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Preview
struct PortfolioFollowOnInvestmentRow_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioFollowOnInvestmentRow(
            investment: .constant(FollowOnInvestment(
                timingType: .absoluteDate,
                date: Date(),
                relativeAmount: "0",
                relativeUnit: .months,
                investmentType: .buy,
                amount: "25000",
                valuationMode: .custom,
                valuation: "15"
            )),
            batchNumber: 2,
            showDetails: true,
            onDelete: {},
            onEdit: {}
        )
        .padding()
    }
}