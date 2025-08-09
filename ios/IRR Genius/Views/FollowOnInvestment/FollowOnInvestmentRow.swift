//
//  FollowOnInvestmentRow.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

struct FollowOnInvestmentRow: View {
    @Binding var investment: FollowOnInvestment
    let onDelete: () -> Void

    private var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        switch investment.timingType {
        case .absoluteDate:
            return formatter.string(from: investment.date)
        case .relativeTime:
            let calculatedDate = investment.investmentDate
            return "\(investment.relativeAmount) \(investment.relativeUnit.rawValue.lowercased()) from initial (\(formatter.string(from: calculatedDate)))"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(investment.investmentType.rawValue) - \(investment.amount)")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(dateDisplay)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }

            if investment.valuationMode == .custom {
                HStack {
                    Text("Valuation:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(investment.valuation)
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()
                }
            } else {
                HStack {
                    Text("Tag-along (follows initial IRR)")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}
