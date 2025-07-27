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
    let fieldName: String?
    let validationService: ValidationService?
    let isRequired: Bool
    
    @State private var validationErrors: [ValidationError] = []
    @State private var hasBeenEdited: Bool = false
    
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
        formatType: FormatType = .currency,
        fieldName: String? = nil,
        validationService: ValidationService? = nil,
        isRequired: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.formatType = formatType
        self.fieldName = fieldName
        self.validationService = validationService
        self.isRequired = isRequired
    }
    
    private var hasErrors: Bool {
        return !validationErrors.isEmpty
    }
    
    private var borderColor: Color {
        if hasErrors {
            return .red
        } else if hasBeenEdited && !text.isEmpty {
            return .green
        } else {
            return Color(.systemGray4)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.headline)
                }
                
                Spacer()
                
                if hasBeenEdited && !hasErrors && !text.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: hasErrors ? 2 : 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                        )
                )
                .onChange(of: text) { _, newValue in
                    hasBeenEdited = true
                    
                    // Format input
                    switch formatType {
                    case .currency:
                        text = NumberFormatting.formatCurrencyInput(newValue)
                    case .number:
                        text = NumberFormatting.formatNumberInput(newValue)
                    case .none:
                        break
                    }
                    
                    // Validate if validation service is provided
                    if let fieldName = fieldName, let validationService = validationService {
                        let result = validationService.validateField(fieldName, value: text)
                        validationErrors = result.errors
                    }
                }
                .onAppear {
                    // Initial validation if field has content
                    if !text.isEmpty, let fieldName = fieldName, let validationService = validationService {
                        let result = validationService.validateField(fieldName, value: text)
                        validationErrors = result.errors
                    }
                }
            
            // Error messages
            if !validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(validationErrors) { error in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: iconForSeverity(error.severity))
                                .foregroundColor(colorForSeverity(error.severity))
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(error.message)
                                    .font(.caption)
                                    .foregroundColor(colorForSeverity(error.severity))
                                
                                if let suggestion = error.suggestion {
                                    Text(suggestion)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func iconForSeverity(_ severity: ValidationError.Severity) -> String {
        switch severity {
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private func colorForSeverity(_ severity: ValidationError.Severity) -> Color {
        switch severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
} 