//
//  FollowOnInvestmentBatchSection.swift
//  IRR Genius
//
//  Main follow-on investment batch management section
//

import SwiftUI

struct FollowOnInvestmentBatchSection: View {
    @Binding var followOnInvestments: [FollowOnInvestment]
    @Binding var showingBatchDetails: Bool
    @Binding var showingAddInvestment: Bool
    @Binding var selectedBatchIndex: Int?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Follow-on Investment Batches")
                    .font(.headline)
                
                Spacer()
                
                if !followOnInvestments.isEmpty {
                    Button(action: { showingBatchDetails.toggle() }) {
                        Image(systemName: showingBatchDetails ? "eye.slash" : "eye")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: { showingAddInvestment = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            if followOnInvestments.isEmpty {
                EmptyFollowOnInvestmentView()
            } else {
                FollowOnInvestmentContent(
                    followOnInvestments: $followOnInvestments,
                    showingBatchDetails: showingBatchDetails,
                    selectedBatchIndex: $selectedBatchIndex,
                    showingAddInvestment: $showingAddInvestment
                )
            }
        }
    }
}

// Preview
struct FollowOnInvestmentBatchSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Empty state
            FollowOnInvestmentBatchSection(
                followOnInvestments: .constant([]),
                showingBatchDetails: .constant(false),
                showingAddInvestment: .constant(false),
                selectedBatchIndex: .constant(nil)
            )
            
            // With investments
            FollowOnInvestmentBatchSection(
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
                    )
                ]),
                showingBatchDetails: .constant(true),
                showingAddInvestment: .constant(false),
                selectedBatchIndex: .constant(nil)
            )
        }
        .padding()
    }
}