//
//  ErrorDisplayView.swift
//  IRR Genius
//
//  Error display component for portfolio calculations
//

import SwiftUI

struct ErrorDisplayView: View {
    let errorMessage: String?
    
    var body: some View {
        if let errorMessage = errorMessage {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Calculation Error")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// Preview
struct ErrorDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ErrorDisplayView(errorMessage: "Sample error message for testing")
            ErrorDisplayView(errorMessage: nil)
        }
        .padding()
    }
}