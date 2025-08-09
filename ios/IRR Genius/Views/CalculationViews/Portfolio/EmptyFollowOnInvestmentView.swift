//
//  EmptyFollowOnInvestmentView.swift
//  IRR Genius
//
//  Empty state view for follow-on investments
//

import SwiftUI

struct EmptyFollowOnInvestmentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("No follow-on investments added")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Tap + to add investment batches with different unit prices and timing")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Preview
struct EmptyFollowOnInvestmentView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyFollowOnInvestmentView()
            .padding()
    }
}
