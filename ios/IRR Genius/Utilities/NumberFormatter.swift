//
//  NumberFormatter.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import Foundation

// Helper for comma formatting
extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

// Number formatting utilities
enum NumberFormatting {
    static func formatWithCommas(_ value: Double, fractionDigits: Int = 2) -> String {
        Formatter.withSeparator.maximumFractionDigits = fractionDigits
        return Formatter.withSeparator.string(from: NSNumber(value: value)) ?? String(format: "%.*f", fractionDigits, value)
    }

    static func formatCurrencyInput(_ input: String) -> String {
        // Remove all non-digit characters except decimal point
        let cleaned = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)

        // Ensure only one decimal point
        let components = cleaned.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }

        // Add commas for thousands
        if let number = Double(cleaned) {
            return formatWithCommas(number)
        }

        return cleaned
    }

    static func formatNumberInput(_ input: String) -> String {
        // Remove all non-digit characters except decimal point
        return input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
    }

    static func formatNumber(_ value: Double) -> String {
        return formatWithCommas(value, fractionDigits: 0)
    }

    static func formatCurrency(_ value: Double) -> String {
        return "$" + formatWithCommas(value)
    }
}
