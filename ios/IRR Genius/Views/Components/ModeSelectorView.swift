//
//  ModeSelectorView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

struct ModeSelectorView: View {
    @Binding var selectedMode: CalculationMode

    var body: some View {
        Picker("Calculation Mode", selection: $selectedMode) {
            ForEach(CalculationMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}
