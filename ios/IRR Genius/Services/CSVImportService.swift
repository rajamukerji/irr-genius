//
//  CSVImportService.swift
//  IRR Genius
//

import Foundation

/// Service for importing calculation data from CSV files
class CSVImportService {
    
    // MARK: - Constants
    
    private static let supportedDelimiters: [Character] = [",", ";", "\t", "|"]
    private static let dateFormatters: [DateFormatter] = {
        let formatters = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy/MM/dd"
        ].map { pattern in
            let formatter = DateFormatter()
            formatter.dateFormat = pattern
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
        return formatters
    }()
    
    // MARK: - Public Methods
    
    /// Imports CSV data from a URL
    func importCSV(from url: URL, delimiter: Character = ",", hasHeaders: Bool = true) async throws -> ImportResult {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            guard !lines.isEmpty else {
                throw ImportError.emptyFile
            }
            
            let actualDelimiter = detectDelimiter(in: lines.first!, preferred: delimiter)
            let parsedData = parseCSVLines(lines, delimiter: actualDelimiter, hasHeaders: hasHeaders)
            
            return ImportResult(
                headers: parsedData.headers,
                rows: parsedData.rows,
                detectedFormat: .csv(delimiter: actualDelimiter, hasHeaders: hasHeaders),
                suggestedMapping: suggestColumnMapping(for: parsedData.headers),
                validationErrors: []
            )
        } catch {
            if error is ImportError {
                throw error
            } else {
                throw ImportError.parseError("Failed to parse CSV: \(error.localizedDescription)")
            }
        }
    }
    
    /// Validates imported data and converts to SavedCalculation objects
    func validateAndConvert(
        importResult: ImportResult,
        columnMapping: [String: CalculationField],
        calculationType: CalculationMode,
        projectId: UUID? = nil
    ) async throws -> ValidationResult {
        var validationErrors: [ValidationError] = []
        var validCalculations: [SavedCalculation] = []
        
        for (rowIndex, row) in importResult.rows.enumerated() {
            do {
                let calculation = try convertRowToCalculation(
                    row: row,
                    headers: importResult.headers,
                    columnMapping: columnMapping,
                    calculationType: calculationType,
                    projectId: projectId,
                    rowIndex: rowIndex
                )
                
                // Validate the calculation
                try calculation.validate()
                validCalculations.append(calculation)
                
            } catch {
                validationErrors.append(
                    ValidationError(
                        row: rowIndex + 1,
                        column: nil,
                        message: error.localizedDescription,
                        severity: .error
                    )
                )
            }
        }
        
        return ValidationResult(
            validCalculations: validCalculations,
            validationErrors: validationErrors,
            totalRows: importResult.rows.count,
            validRows: validCalculations.count
        )
    }
    
    // MARK: - Private Methods
    
    /// Detects the most likely delimiter in a CSV line
    private func detectDelimiter(in line: String, preferred: Character) -> Character {
        if line.contains(preferred) {
            return preferred
        }
        
        return Self.supportedDelimiters.max { delimiter1, delimiter2 in
            line.filter { $0 == delimiter1 }.count < line.filter { $0 == delimiter2 }.count
        } ?? ","
    }
    
    /// Parses CSV lines into headers and rows
    private func parseCSVLines(_ lines: [String], delimiter: Character, hasHeaders: Bool) -> ParsedCSVData {
        let headers: [String]
        if hasHeaders && !lines.isEmpty {
            headers = parseCSVLine(lines.first!, delimiter: delimiter)
        } else {
            // Generate default headers if no headers provided
            let firstLine = lines.first ?? ""
            let columnCount = parseCSVLine(firstLine, delimiter: delimiter).count
            headers = (1...columnCount).map { "Column \($0)" }
        }
        
        let dataStartIndex = hasHeaders ? 1 : 0
        let rows = lines.dropFirst(dataStartIndex).compactMap { line in
            let parsedLine = parseCSVLine(line, delimiter: delimiter)
            return parsedLine.isEmpty ? nil : parsedLine
        }
        
        return ParsedCSVData(headers: headers, rows: Array(rows))
    }
    
    /// Parses a single CSV line, handling quoted values
    private func parseCSVLine(_ line: String, delimiter: Character) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            switch char {
            case "\"":
                if inQuotes && line.index(after: i) < line.endIndex && line[line.index(after: i)] == "\"" {
                    // Escaped quote
                    current.append("\"")
                    i = line.index(after: i) // Skip next quote
                } else {
                    // Toggle quote state
                    inQuotes.toggle()
                }
            case delimiter where !inQuotes:
                result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            default:
                current.append(char)
            }
            
            i = line.index(after: i)
        }
        
        result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return result
    }
    
    /// Suggests column mapping based on header names
    private func suggestColumnMapping(for headers: [String]) -> [String: CalculationField] {
        var mapping: [String: CalculationField] = [:]
        
        for header in headers {
            let normalizedHeader = header.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
            
            let suggestedField: CalculationField?
            switch normalizedHeader {
            case let h where h.contains("initial") || h.contains("investment"):
                suggestedField = .initialInvestment
            case let h where h.contains("outcome") || h.contains("exit"):
                suggestedField = .outcomeAmount
            case let h where h.contains("time") || h.contains("month") || h.contains("duration"):
                suggestedField = .timeInMonths
            case let h where h.contains("irr") || h.contains("return"):
                suggestedField = .irr
            case let h where h.contains("name") || h.contains("title"):
                suggestedField = .name
            case let h where h.contains("note") || h.contains("comment"):
                suggestedField = .notes
            case let h where h.contains("date") || h.contains("created"):
                suggestedField = .date
            case let h where h.contains("unit") && h.contains("price"):
                suggestedField = .unitPrice
            case let h where h.contains("success") && h.contains("rate"):
                suggestedField = .successRate
            case let h where h.contains("outcome") && h.contains("unit"):
                suggestedField = .outcomePerUnit
            case let h where h.contains("investor") && h.contains("share"):
                suggestedField = .investorShare
            case let h where h.contains("fee"):
                suggestedField = .feePercentage
            default:
                suggestedField = nil
            }
            
            if let field = suggestedField {
                mapping[header] = field
            }
        }
        
        return mapping
    }
    
    /// Converts a CSV row to a SavedCalculation object
    private func convertRowToCalculation(
        row: [String],
        headers: [String],
        columnMapping: [String: CalculationField],
        calculationType: CalculationMode,
        projectId: UUID?,
        rowIndex: Int
    ) throws -> SavedCalculation {
        var fieldValues: [CalculationField: String] = [:]
        
        // Map row values to calculation fields
        for (index, header) in headers.enumerated() {
            if index < row.count, let field = columnMapping[header] {
                fieldValues[field] = row[index]
            }
        }
        
        // Extract and validate field values
        let name = fieldValues[.name]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? fieldValues[.name]!
            : "Imported Calculation \(rowIndex + 1)"
        
        let initialInvestment = try fieldValues[.initialInvestment].flatMap { 
            try parseDouble($0, fieldName: "Initial Investment", rowNumber: rowIndex + 1)
        }
        
        let outcomeAmount = try fieldValues[.outcomeAmount].flatMap {
            try parseDouble($0, fieldName: "Outcome Amount", rowNumber: rowIndex + 1)
        }
        
        let timeInMonths = try fieldValues[.timeInMonths].flatMap {
            try parseDouble($0, fieldName: "Time in Months", rowNumber: rowIndex + 1)
        }
        
        let irr = try fieldValues[.irr].flatMap {
            try parseDouble($0, fieldName: "IRR", rowNumber: rowIndex + 1)
        }
        
        let unitPrice = try fieldValues[.unitPrice].flatMap {
            try parseDouble($0, fieldName: "Unit Price", rowNumber: rowIndex + 1)
        }
        
        let successRate = try fieldValues[.successRate].flatMap {
            try parseDouble($0, fieldName: "Success Rate", rowNumber: rowIndex + 1)
        }
        
        let outcomePerUnit = try fieldValues[.outcomePerUnit].flatMap {
            try parseDouble($0, fieldName: "Outcome Per Unit", rowNumber: rowIndex + 1)
        }
        
        let investorShare = try fieldValues[.investorShare].flatMap {
            try parseDouble($0, fieldName: "Investor Share", rowNumber: rowIndex + 1)
        }
        
        let feePercentage = try fieldValues[.feePercentage].flatMap {
            try parseDouble($0, fieldName: "Fee Percentage", rowNumber: rowIndex + 1)
        }
        
        let notes = fieldValues[.notes]
        
        let createdDate = try fieldValues[.date].flatMap { 
            try parseDate($0, rowNumber: rowIndex + 1) 
        } ?? Date()
        
        return try SavedCalculation(
            name: name,
            calculationType: calculationType,
            createdDate: createdDate,
            modifiedDate: Date(),
            projectId: projectId,
            initialInvestment: initialInvestment,
            outcomeAmount: outcomeAmount,
            timeInMonths: timeInMonths,
            irr: irr,
            unitPrice: unitPrice,
            successRate: successRate,
            outcomePerUnit: outcomePerUnit,
            investorShare: investorShare,
            feePercentage: feePercentage,
            notes: notes
        )
    }
    
    /// Parses a string to Double with error handling
    private func parseDouble(_ value: String, fieldName: String, rowNumber: Int) throws -> Double? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }
        
        // Remove common currency symbols and formatting
        let cleanValue = trimmedValue.replacingOccurrences(of: "[$,€£¥%\\s]", with: "", options: .regularExpression)
        
        guard let doubleValue = Double(cleanValue) else {
            throw ImportError.invalidNumberFormat(row: rowNumber, field: fieldName, value: value)
        }
        
        return doubleValue
    }
    
    /// Parses a string to Date with error handling
    private func parseDate(_ value: String, rowNumber: Int) throws -> Date? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }
        
        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: trimmedValue) {
                return date
            }
        }
        
        throw ImportError.invalidDateFormat(row: rowNumber, value: value)
    }
}

// MARK: - Supporting Types

/// Data structure for parsed CSV data
private struct ParsedCSVData {
    let headers: [String]
    let rows: [[String]]
}

/// Enum representing calculation fields that can be imported
enum CalculationField: String, CaseIterable {
    case name = "Calculation Name"
    case initialInvestment = "Initial Investment"
    case outcomeAmount = "Outcome Amount"
    case timeInMonths = "Time in Months"
    case irr = "IRR (%)"
    case unitPrice = "Unit Price"
    case successRate = "Success Rate (%)"
    case outcomePerUnit = "Outcome Per Unit"
    case investorShare = "Investor Share (%)"
    case feePercentage = "Fee Percentage (%)"
    case notes = "Notes"
    case date = "Date"
    
    var displayName: String {
        return self.rawValue
    }
}

/// Import format specification
enum ImportFormat {
    case csv(delimiter: Character, hasHeaders: Bool)
    case excel(sheetName: String, hasHeaders: Bool)
}

/// Result of CSV import operation
struct ImportResult {
    let headers: [String]
    let rows: [[String]]
    let detectedFormat: ImportFormat
    let suggestedMapping: [String: CalculationField]
    let validationErrors: [ValidationError]
}

/// Result of data validation
struct ValidationResult {
    let validCalculations: [SavedCalculation]
    let validationErrors: [ValidationError]
    let totalRows: Int
    let validRows: Int
    
    var hasErrors: Bool { !validationErrors.isEmpty }
    var successRate: Double { totalRows > 0 ? Double(validRows) / Double(totalRows) : 0.0 }
}

/// Validation error information
struct ValidationError {
    let row: Int
    let column: String?
    let message: String
    let severity: ValidationSeverity
}

/// Severity levels for validation errors
enum ValidationSeverity {
    case warning
    case error
}

/// Errors that can occur during import operations
enum ImportError: LocalizedError {
    case fileAccessDenied
    case emptyFile
    case parseError(String)
    case invalidNumberFormat(row: Int, field: String, value: String)
    case invalidDateFormat(row: Int, value: String)
    case unsupportedFormat
    case corruptedFile
    case missingRequiredFields([String])
    
    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Unable to access the selected file. Please check file permissions."
        case .emptyFile:
            return "The selected file is empty."
        case .parseError(let message):
            return "Failed to parse file: \(message)"
        case .invalidNumberFormat(let row, let field, let value):
            return "Invalid number format in row \(row) for field '\(field)': '\(value)'"
        case .invalidDateFormat(let row, let value):
            return "Invalid date format in row \(row): '\(value)'"
        case .unsupportedFormat:
            return "File format not supported. Please use CSV or Excel files."
        case .corruptedFile:
            return "File appears to be corrupted or unreadable."
        case .missingRequiredFields(let fields):
            return "Missing required fields: \(fields.joined(separator: ", "))"
        }
    }
}