//
//  ValidationFeedbackView.swift
//  IRR Genius
//
//  Real-time validation feedback component
//

import SwiftUI

struct ValidationFeedbackView: View {
    let validationErrors: [String]
    @Binding var showingDetails: Bool

    var body: some View {
        if !validationErrors.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("Input Validation")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Spacer()

                    Button(showingDetails ? "Hide Details" : "Show Details") {
                        showingDetails.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }

                if showingDetails {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(validationErrors, id: \.self) { error in
                            HStack(alignment: .top) {
                                Text("•")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                } else {
                    Text("\(validationErrors.count) validation issue\(validationErrors.count == 1 ? "" : "s") found")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// Preview
struct ValidationFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ValidationFeedbackView(
                validationErrors: ["Initial investment is required", "Unit price must be greater than 0"],
                showingDetails: .constant(true)
            )
            ValidationFeedbackView(
                validationErrors: ["Single error"],
                showingDetails: .constant(false)
            )
            ValidationFeedbackView(
                validationErrors: [],
                showingDetails: .constant(false)
            )
        }
        .padding()
    }
}
