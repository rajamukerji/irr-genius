//
//  ModeSelectorView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

struct ModeSelectorView: View {
    @Binding var selectedMode: CalculationMode

    // Short display names for segmented picker to prevent truncation
    private func displayName(for mode: CalculationMode) -> String {
        switch mode {
        case .calculateIRR:
            return "IRR"
        case .calculateOutcome:
            return "Outcome"
        case .calculateInitial:
            return "Initial"
        case .calculateBlendedIRR:
            return "Blended"
        case .portfolioUnitInvestment:
            return "Portfolio"
        }
    }

    var body: some View {
        Picker("Calculation Mode", selection: $selectedMode) {
            ForEach(CalculationMode.allCases, id: \.self) { mode in
                Text(displayName(for: mode)).tag(mode)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}
