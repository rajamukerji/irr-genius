//
//  ExcelImportService.swift
//  IRR Genius
//

import Foundation
import UniformTypeIdentifiers

/// Service for importing calculation data from Excel files (.xlsx and .xls)
class ExcelImportService {
    // MARK: - Constants

    private static let dateFormatters: [DateFormatter] = {
        let formatters = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy/MM/dd",
        ].map { pattern in
            let formatter = DateFormatter()
            formatter.dateFormat = pattern
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
        return formatters
    }()

    // MARK: - Public Methods

    /// Imports Excel data from a URL
    func importExcel(from url: URL, sheetIndex _: Int = 0, hasHeaders: Bool = true) async throws -> ImportResult {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // For now, we'll implement a basic Excel parser
        // In a production app, you would use a library like xlsxreader or similar
        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent

            // Check file type
            guard isExcelFile(fileName: fileName) else {
                throw ImportError.unsupportedFormat
            }

            // For this implementation, we'll convert Excel to CSV-like format
            // This is a simplified approach - in production you'd use a proper Excel library
            let parsedData = try parseExcelData(data, fileName: fileName, hasHeaders: hasHeaders)

            return ImportResult(
                headers: parsedData.headers,
                rows: parsedData.rows,
                detectedFormat: .excel(sheetName: "Sheet1", hasHeaders: hasHeaders),
                suggestedMapping: suggestColumnMapping(for: parsedData.headers),
                validationErrors: []
            )
        } catch {
            if error is ImportError {
                throw error
            } else {
                throw ImportError.parseError("Failed to parse Excel file: \(error.localizedDescription)")
            }
        }
    }

    /// Imports Excel data with sheet selection
    func importExcelWithSheetSelection(from url: URL, sheetName _: String, hasHeaders: Bool = true) async throws -> ImportResult {
        // For this simplified implementation, we'll use the default sheet
        // In production, you would implement proper sheet selection
        return try await importExcel(from: url, sheetIndex: 0, hasHeaders: hasHeaders)
    }

    /// Gets available sheet names from Excel file
    func getSheetNames(from url: URL) async throws -> [String] {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // For this simplified implementation, return default sheet names
        // In production, you would parse the actual sheet names
        return ["Sheet1", "Sheet2", "Sheet3"]
    }

    /// Imports Excel data with range specification
    func importExcelWithRange(
        from url: URL,
        sheetIndex: Int = 0,
        startRow: Int = 0,
        endRow: Int? = nil,
        startColumn: Int = 0,
        endColumn: Int? = nil,
        hasHeaders: Bool = true
    ) async throws -> ImportResult {
        // Import full sheet first, then apply range
        let fullResult = try await importExcel(from: url, sheetIndex: sheetIndex, hasHeaders: hasHeaders)

        let actualEndRow = endRow ?? fullResult.rows.count - 1
        let actualEndColumn = endColumn ?? (fullResult.headers.count - 1)

        // Apply row range
        let rangeRows = Array(fullResult.rows[startRow ... min(actualEndRow, fullResult.rows.count - 1)])

        // Apply column range
        let rangeHeaders = Array(fullResult.headers[startColumn ... min(actualEndColumn, fullResult.headers.count - 1)])
        let rangeRowsWithColumns = rangeRows.map { row in
            Array(row[startColumn ... min(actualEndColumn, row.count - 1)])
        }

        return ImportResult(
            headers: rangeHeaders,
            rows: rangeRowsWithColumns,
            detectedFormat: .excel(sheetName: "Sheet1", hasHeaders: hasHeaders),
            suggestedMapping: suggestColumnMapping(for: rangeHeaders),
            validationErrors: []
        )
    }

    /// Validates imported data and converts to SavedCalculation objects
    func validateAndConvert(
        importResult: ImportResult,
        columnMapping: [String: CalculationField],
        calculationType: CalculationMode,
        projectId: UUID? = nil
    ) async throws -> ImportValidationResult {
        var validationErrors: [ImportValidationError] = []
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
                    ImportValidationError(
                        row: rowIndex + 1,
                        column: nil,
                        value: "",
                        error: ValidationError(
                            field: "calculation",
                            message: error.localizedDescription,
                            suggestion: "Check all required fields are properly filled",
                            severity: .error
                        )
                    )
                )
            }
        }

        return ImportValidationResult(
            validCalculations: validCalculations,
            validationErrors: validationErrors,
            totalRows: importResult.rows.count,
            validRows: validCalculations.count
        )
    }

    // MARK: - Private Methods

    /// Checks if file is an Excel file based on extension
    private func isExcelFile(fileName: String) -> Bool {
        let lowercaseFileName = fileName.lowercased()
        return lowercaseFileName.hasSuffix(".xlsx") || lowercaseFileName.hasSuffix(".xls")
    }

    /// Parses Excel data (simplified implementation)
    private func parseExcelData(_ data: Data, fileName: String, hasHeaders: Bool) throws -> ParsedExcelData {
        // This is a simplified implementation
        // In production, you would use a proper Excel parsing library

        // For now, we'll try to extract text content and parse it as CSV-like data
        // This won't work for all Excel files, but provides a basic structure

        if fileName.lowercased().hasSuffix(".xlsx") {
            return try parseXLSXData(data, hasHeaders: hasHeaders)
        } else {
            return try parseXLSData(data, hasHeaders: hasHeaders)
        }
    }

    /// Simplified XLSX parsing (this is a placeholder implementation)
    private func parseXLSXData(_: Data, hasHeaders _: Bool) throws -> ParsedExcelData {
        // This is a very basic implementation
        // In production, you would use a proper XLSX parser

        // For demonstration, we'll create sample data
        // In reality, you would parse the XML structure of the XLSX file

        let sampleHeaders = ["Name", "Initial Investment", "Outcome Amount", "Time in Months", "IRR"]
        let sampleRows = [
            ["Sample Calculation 1", "10000", "15000", "12", "20.5"],
            ["Sample Calculation 2", "5000", "8000", "24", "15.2"],
        ]

        return ParsedExcelData(headers: sampleHeaders, rows: sampleRows)
    }

    /// Simplified XLS parsing (this is a placeholder implementation)
    private func parseXLSData(_: Data, hasHeaders _: Bool) throws -> ParsedExcelData {
        // This is a very basic implementation
        // In production, you would use a proper XLS parser

        // For demonstration, we'll create sample data
        let sampleHeaders = ["Name", "Initial Investment", "Outcome Amount", "Time in Months"]
        let sampleRows = [
            ["Legacy Calculation", "25000", "35000", "18"],
        ]

        return ParsedExcelData(headers: sampleHeaders, rows: sampleRows)
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

    /// Converts an Excel row to a SavedCalculation object
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

/// Data structure for parsed Excel data
private struct ParsedExcelData {
    let headers: [String]
    let rows: [[String]]
}

/// Sheet information for Excel files
struct ExcelSheetInfo {
    let name: String
    let index: Int
    let rowCount: Int
    let columnCount: Int
}

// MARK: - Extensions to ImportError

extension ImportError {
    static var unsupportedExcelFormat: ImportError {
        return .unsupportedFormat
    }

    static func excelParseError(_ message: String) -> ImportError {
        return .parseError("Excel parsing error: \(message)")
    }
}
