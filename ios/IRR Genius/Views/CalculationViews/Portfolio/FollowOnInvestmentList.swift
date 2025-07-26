//
//  FollowOnInvestmentList.swift
//  IRR Genius
//
//  List component for follow-on investments
//

import SwiftUI

struct FollowOnInvestmentList: View {
    @Binding var followOnInvestments: [FollowOnInvestment]
    let showingBatchDetails: Bool
    @Binding var selectedBatchIndex: Int?
    @Binding var showingAddInvestment: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(followOnInvestments.indices, id: \.self) { index in
                PortfolioFollowOnInvestmentRow(
                    investment: $followOnInvestments[index],
                    batchNumber: index + 2,
                    showDetails: showingBatchDetails,
                    onDelete: {
                        deleteInvestment(at: index)
                    },
                    onEdit: {
                        editInvestment(at: index)
                    }
                )
            }
        }
    }
    
    private func deleteInvestment(at index: Int) {
        _ = withAnimation(.easeInOut(duration: 0.3)) {
            followOnInvestments.remove(at: index)
        }
    }
    
    private func editInvestment(at index: Int) {
        selectedBatchIndex = index
        showingAddInvestment = true
    }
}

// Preview
struct FollowOnInvestmentList_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            FollowOnInvestmentList(
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
                    FollowOnInvestment(
                        timingType: .relativeTime,
                        date: Date().addingTimeInterval(86400 * 30),
                        relativeAmount: "6",
                        relativeUnit: .months,
                        investmentType: .buy,
                        amount: "30000",
                        valuationMode: .custom,
                        valuation: "20"
                    )
                ]),
                showingBatchDetails: true,
                selectedBatchIndex: .constant(nil),
                showingAddInvestment: .constant(false)
            )
        }
        .padding()
    }
}