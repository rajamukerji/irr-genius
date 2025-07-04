//
//  InputField.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let formatType: FormatType
    
    enum FormatType {
        case currency
        case number
        case none
    }
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .decimalPad,
        formatType: FormatType = .currency
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.formatType = formatType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: text) { _, newValue in
                    switch formatType {
                    case .currency:
                        text = NumberFormatting.formatCurrencyInput(newValue)
                    case .number:
                        text = NumberFormatting.formatNumberInput(newValue)
                    case .none:
                        break
                    }
                }
        }
    }
} 