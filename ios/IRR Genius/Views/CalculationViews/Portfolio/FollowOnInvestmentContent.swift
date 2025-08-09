//
//  FollowOnInvestmentContent.swift
//  IRR Genius
//
//  Content view when follow-on investments exist
//

import SwiftUI

struct FollowOnInvestmentContent: View {
    @Binding var followOnInvestments: [FollowOnInvestment]
    let showingBatchDetails: Bool
    @Binding var selectedBatchIndex: Int?
    @Binding var showingAddInvestment: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Batch Summary Header
            HStack {
                Text("Total Batches: \(followOnInvestments.count + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Total Follow-on: \(NumberFormatting.formatCurrency(followOnInvestments.compactMap { Double($0.amount.replacingOccurrences(of: ",", with: "")) }.reduce(0, +)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            FollowOnInvestmentList(
                followOnInvestments: $followOnInvestments,
                showingBatchDetails: showingBatchDetails,
                selectedBatchIndex: $selectedBatchIndex,
                showingAddInvestment: $showingAddInvestment
            )
        }
    }
}

// Preview
struct FollowOnInvestmentContent_Previews: PreviewProvider {
    static var previews: some View {
        FollowOnInvestmentContent(
            followOnInvestments: .constant([
                FollowOnInvestment(
                    timingType: .absoluteDate,
                    date: Date(),
                    relativeAmount: "0",
                    relativeUnit: .months,
                    investmentType: .buy,
                    amount: "25000",
                    valuationMode: .custom,
                    valuation: "15"
                ),
            ]),
            showingBatchDetails: true,
            selectedBatchIndex: .constant(nil),
            showingAddInvestment: .constant(false)
        )
        .padding()
    }
}
