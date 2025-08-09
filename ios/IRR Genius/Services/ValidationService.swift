//
//  ValidationService.swift
//  IRR Genius
//
//  Created by Kiro on 7/26/25.
//

import Foundation
import SwiftUI

// MARK: - Validation Framework

/// Protocol for validatable fields
protocol Validatable {
    func validate() throws
}

/// Validation result for UI feedback
struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]

    static let valid = ValidationResult(isValid: true, errors: [])

    static func invalid(_ errors: [ValidationError]) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors)
    }

    static func invalid(_ error: ValidationError) -> ValidationResult {
        return ValidationResult(isValid: false, errors: [error])
    }
}

/// Validation error with context and suggestions
struct ValidationError: Identifiable, LocalizedError {
    let id = UUID()
    let field: String
    let message: String
    let suggestion: String?
    let severity: Severity

    enum Severity {
        case error
        case warning
        case info
    }

    var errorDescription: String? {
        return message
    }

    var recoverySuggestion: String? {
        return suggestion
    }
}

/// Field validation rules
enum ValidationRule {
    case required
    case minLength(Int)
    case maxLength(Int)
    case range(min: Double, max: Double)
    case positive
    case percentage
    case currency
    case email
    case custom((String) -> ValidationResult)

    func validate(_ value: String, fieldName: String) -> ValidationResult {
        switch self {
        case .required:
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) is required",
                    suggestion: "Please enter a value for \(fieldName)",
                    severity: .error
                ))
                : .valid

        case let .minLength(min):
            return value.count < min
                ? .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be at least \(min) characters",
                    suggestion: "Enter at least \(min) characters",
                    severity: .error
                ))
                : .valid

        case let .maxLength(max):
            return value.count > max
                ? .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be no more than \(max) characters",
                    suggestion: "Reduce to \(max) characters or less",
                    severity: .error
                ))
                : .valid

        case let .range(min, max):
            guard let doubleValue = Double(value.replacingOccurrences(of: ",", with: "")) else {
                return .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be a valid number",
                    suggestion: "Enter a numeric value",
                    severity: .error
                ))
            }

            if doubleValue < min || doubleValue > max {
                return .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be between \(min) and \(max)",
                    suggestion: "Enter a value between \(min) and \(max)",
                    severity: .error
                ))
            }
            return .valid

        case .positive:
            guard let doubleValue = Double(value.replacingOccurrences(of: ",", with: "")) else {
                return .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be a valid number",
                    suggestion: "Enter a numeric value",
                    severity: .error
                ))
            }

            return doubleValue <= 0
                ? .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be positive",
                    suggestion: "Enter a value greater than 0",
                    severity: .error
                ))
                : .valid

        case .percentage:
            guard let doubleValue = Double(value.replacingOccurrences(of: ",", with: "")) else {
                return .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be a valid percentage",
                    suggestion: "Enter a numeric percentage value",
                    severity: .error
                ))
            }

            if doubleValue < 0 || doubleValue > 100 {
                return .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be between 0% and 100%",
                    suggestion: "Enter a percentage between 0 and 100",
                    severity: .error
                ))
            }
            return .valid

        case .currency:
            let cleanValue = value.replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")

            guard let doubleValue = Double(cleanValue) else {
                return .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be a valid currency amount",
                    suggestion: "Enter a valid dollar amount",
                    severity: .error
                ))
            }

            return doubleValue < 0
                ? .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) cannot be negative",
                    suggestion: "Enter a positive dollar amount",
                    severity: .error
                ))
                : .valid

        case .email:
            let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

            return emailPredicate.evaluate(with: value)
                ? .valid
                : .invalid(ValidationError(
                    field: fieldName,
                    message: "\(fieldName) must be a valid email address",
                    suggestion: "Enter a valid email address (e.g., user@example.com)",
                    severity: .error
                ))

        case let .custom(validator):
            return validator(value)
        }
    }
}

/// Validation service for managing field validation
class ValidationService: ObservableObject {
    @Published var fieldErrors: [String: [ValidationError]] = [:]
    @Published var hasErrors: Bool = false

    var fieldRules: [String: [ValidationRule]] = [:]
    private var realTimeValidation: Bool = true

    /// Registers validation rules for a field
    func registerField(_ fieldName: String, rules: [ValidationRule]) {
        fieldRules[fieldName] = rules
    }

    /// Validates a single field
    func validateField(_ fieldName: String, value: String) -> ValidationResult {
        guard let rules = fieldRules[fieldName] else {
            return .valid
        }

        var errors: [ValidationError] = []

        for rule in rules {
            let result = rule.validate(value, fieldName: fieldName)
            if !result.isValid {
                errors.append(contentsOf: result.errors)
            }
        }

        // Update field errors
        if errors.isEmpty {
            fieldErrors.removeValue(forKey: fieldName)
        } else {
            fieldErrors[fieldName] = errors
        }

        updateHasErrors()

        return errors.isEmpty ? .valid : .invalid(errors)
    }

    /// Validates all registered fields
    func validateAllFields(_ values: [String: String]) -> ValidationResult {
        var allErrors: [ValidationError] = []

        for (fieldName, _) in fieldRules {
            let value = values[fieldName] ?? ""
            let result = validateField(fieldName, value: value)
            if !result.isValid {
                allErrors.append(contentsOf: result.errors)
            }
        }

        return allErrors.isEmpty ? .valid : .invalid(allErrors)
    }

    /// Clears all validation errors
    func clearErrors() {
        fieldErrors.removeAll()
        updateHasErrors()
    }

    /// Clears errors for a specific field
    func clearFieldErrors(_ fieldName: String) {
        fieldErrors.removeValue(forKey: fieldName)
        updateHasErrors()
    }

    /// Gets errors for a specific field
    func getFieldErrors(_ fieldName: String) -> [ValidationError] {
        return fieldErrors[fieldName] ?? []
    }

    /// Checks if a field has errors
    func hasFieldErrors(_ fieldName: String) -> Bool {
        return !(fieldErrors[fieldName]?.isEmpty ?? true)
    }

    /// Enables or disables real-time validation
    func setRealTimeValidation(_ enabled: Bool) {
        realTimeValidation = enabled
    }

    private func updateHasErrors() {
        hasErrors = !fieldErrors.isEmpty
    }
}

// MARK: - Calculation-Specific Validation

/// Validation service specifically for calculation forms
class CalculationValidationService: ValidationService {
    /// Sets up validation rules for a specific calculation type
    func setupValidationRules(for calculationType: CalculationMode) {
        clearErrors()
        fieldRules.removeAll()

        // Common validation rules
        registerField("name", rules: [
            .required,
            .maxLength(100),
            .custom { value in
                let invalidChars = CharacterSet(charactersIn: "<>:\"/\\|?*")
                return value.rangeOfCharacter(from: invalidChars) == nil
                    ? .valid
                    : .invalid(ValidationError(
                        field: "name",
                        message: "Name contains invalid characters",
                        suggestion: "Remove characters like < > : \" / \\ | ? *",
                        severity: .error
                    ))
            },
        ])

        // Calculation-specific rules
        switch calculationType {
        case .calculateIRR:
            registerField("initialInvestment", rules: [.required, .currency, .positive])
            registerField("outcomeAmount", rules: [.required, .currency, .positive])
            registerField("timeInMonths", rules: [.required, .positive, .range(min: 0.1, max: 1200)])

        case .calculateOutcome:
            registerField("initialInvestment", rules: [.required, .currency, .positive])
            registerField("irr", rules: [.required, .range(min: -100, max: 1000)])
            registerField("timeInMonths", rules: [.required, .positive, .range(min: 0.1, max: 1200)])

        case .calculateInitial:
            registerField("outcomeAmount", rules: [.required, .currency, .positive])
            registerField("irr", rules: [.required, .range(min: -100, max: 1000)])
            registerField("timeInMonths", rules: [.required, .positive, .range(min: 0.1, max: 1200)])

        case .calculateBlendedIRR:
            registerField("initialInvestment", rules: [.required, .currency, .positive])
            registerField("outcomeAmount", rules: [.required, .currency, .positive])
            registerField("timeInMonths", rules: [.required, .positive, .range(min: 0.1, max: 1200)])

        case .portfolioUnitInvestment:
            registerField("initialInvestment", rules: [.required, .currency, .positive])
            registerField("unitPrice", rules: [.required, .currency, .positive])
            registerField("successRate", rules: [.required, .percentage])
            registerField("outcomePerUnit", rules: [.required, .currency, .positive])
            registerField("investorShare", rules: [.required, .percentage])
            registerField("timeInMonths", rules: [.required, .positive, .range(min: 0.1, max: 1200)])
        }
    }

    /// Validates follow-on investment data
    func validateFollowOnInvestment(_ investment: FollowOnInvestment) -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate amount
        if let amountValue = Double(investment.amount.replacingOccurrences(of: ",", with: "")), amountValue <= 0 {
            errors.append(ValidationError(
                field: "amount",
                message: "Investment amount must be positive",
                suggestion: "Enter an amount greater than 0",
                severity: .error
            ))
        } else if Double(investment.amount.replacingOccurrences(of: ",", with: "")) == nil && !investment.amount.isEmpty {
            errors.append(ValidationError(
                field: "amount",
                message: "Investment amount must be a valid number",
                suggestion: "Enter a numeric value",
                severity: .error
            ))
        }

        // Validate timing
        switch investment.timingType {
        case .absoluteDate:
            if investment.date < Date() {
                errors.append(ValidationError(
                    field: "absoluteDate",
                    message: "Investment date cannot be in the past",
                    suggestion: "Select a future date",
                    severity: .warning
                ))
            }

        case .relativeTime:
            if let relativeTimeValue = Double(investment.relativeAmount), relativeTimeValue <= 0 {
                errors.append(ValidationError(
                    field: "relativeTime",
                    message: "Relative time must be positive",
                    suggestion: "Enter a positive time value",
                    severity: .error
                ))
            } else if Double(investment.relativeAmount) == nil && !investment.relativeAmount.isEmpty {
                errors.append(ValidationError(
                    field: "relativeTime",
                    message: "Relative time must be a valid number",
                    suggestion: "Enter a numeric value",
                    severity: .error
                ))
            }
        }

        // Validate valuation
        switch investment.valuationMode {
        case .custom:
            if investment.valuationType == .specified {
                if let valuationValue = Double(investment.valuation.replacingOccurrences(of: ",", with: "")), valuationValue <= 0 {
                    errors.append(ValidationError(
                        field: "customValuation",
                        message: "Custom valuation must be positive",
                        suggestion: "Enter a positive valuation amount",
                        severity: .error
                    ))
                } else if Double(investment.valuation.replacingOccurrences(of: ",", with: "")) == nil && !investment.valuation.isEmpty {
                    errors.append(ValidationError(
                        field: "customValuation",
                        message: "Custom valuation must be a valid number",
                        suggestion: "Enter a numeric value",
                        severity: .error
                    ))
                }
            } else if investment.valuationType == .computed {
                if let irrValue = Double(investment.irr), irrValue <= -100 || irrValue >= 1000 {
                    errors.append(ValidationError(
                        field: "irr",
                        message: "IRR must be between -100% and 1000%",
                        suggestion: "Enter a realistic IRR percentage",
                        severity: .error
                    ))
                } else if Double(investment.irr) == nil && !investment.irr.isEmpty {
                    errors.append(ValidationError(
                        field: "irr",
                        message: "IRR must be a valid number",
                        suggestion: "Enter a numeric percentage value",
                        severity: .error
                    ))
                }
            }
        case .tagAlong:
            // Tag-along mode doesn't require additional validation
            break
        }

        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

// MARK: - Import Data Validation

/// Validation service for imported data
class ImportValidationService: ObservableObject {
    @Published var validationResults: [ImportFieldValidationResult] = []
    @Published var hasValidationErrors: Bool = false

    struct ImportFieldValidationResult {
        let row: Int
        let column: String
        let value: String
        let error: ValidationError
    }

    /// Validates imported CSV/Excel data
    func validateImportedData(_ data: [[String]], headers: [String], fieldMapping: [String: String]) -> [ImportFieldValidationResult] {
        var results: [ImportFieldValidationResult] = []

        for (rowIndex, row) in data.enumerated() {
            for (columnIndex, value) in row.enumerated() {
                guard columnIndex < headers.count else { continue }

                let header = headers[columnIndex]
                guard let fieldName = fieldMapping[header] else { continue }

                let validationResult = validateImportedField(fieldName, value: value)
                if !validationResult.isValid {
                    for error in validationResult.errors {
                        results.append(ImportFieldValidationResult(
                            row: rowIndex + 1,
                            column: header,
                            value: value,
                            error: error
                        ))
                    }
                }
            }
        }

        validationResults = results
        hasValidationErrors = !results.isEmpty

        return results
    }

    private func validateImportedField(_ fieldName: String, value: String) -> ValidationResult {
        switch fieldName {
        case "initialInvestment", "outcomeAmount", "unitPrice", "outcomePerUnit", "customValuation":
            return ValidationRule.currency.validate(value, fieldName: fieldName)

        case "irr":
            return ValidationRule.range(min: -100, max: 1000).validate(value, fieldName: fieldName)

        case "timeInMonths":
            return ValidationRule.positive.validate(value, fieldName: fieldName)

        case "successRate", "investorShare", "feePercentage":
            return ValidationRule.percentage.validate(value, fieldName: fieldName)

        case "name":
            let requiredResult = ValidationRule.required.validate(value, fieldName: fieldName)
            if !requiredResult.isValid { return requiredResult }

            let lengthResult = ValidationRule.maxLength(100).validate(value, fieldName: fieldName)
            if !lengthResult.isValid { return lengthResult }

            return .valid

        default:
            return .valid
        }
    }

    /// Clears validation results
    func clearValidationResults() {
        validationResults.removeAll()
        hasValidationErrors = false
    }
}

// MARK: - UI Extensions

extension View {
    /// Adds validation error display to a view
    func validationError(_ errors: [ValidationError]) -> some View {
        overlay(
            VStack {
                Spacer()
                if !errors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(errors) { error in
                            HStack {
                                Image(systemName: iconForSeverity(error.severity))
                                    .foregroundColor(colorForSeverity(error.severity))

                                Text(error.message)
                                    .font(.caption)
                                    .foregroundColor(colorForSeverity(error.severity))

                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemBackground))
                    .cornerRadius(4)
                    .shadow(radius: 2)
                }
            },
            alignment: .bottomLeading
        )
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
