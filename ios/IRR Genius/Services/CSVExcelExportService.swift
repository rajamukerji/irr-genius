//
//  CSVExcelExportService.swift
//  IRR Genius
//
//  Created by Kiro on 7/24/25.
//

import Foundation

// MARK: - CSV/Excel Export Service Protocol
protocol CSVExcelExportService {
    func exportToCSV(_ calculations: [SavedCalculation]) async throws -> URL
    func exportToExcel(_ calculations: [SavedCalculation]) async throws -> URL
    func exportCalculationToCSV(_ calculation: SavedCalculation) async throws -> URL
}

// MARK: - CSV/Excel Export Errors
enum CSVExcelExportError: LocalizedError {
    case invalidCalculationData
    case fileWriteFailed(Error)
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidCalculationData:
            return "Invalid calculation data for export"
        case .fileWriteFailed(let error):
            return "Failed to write export file: \(error.localizedDescription)"
        case .unsupportedFormat:
            return "Unsupported export format"
        }
    }
}

// MARK: - CSV/Excel Export Service Implementation
class CSVExcelExportServiceImpl: CSVExcelExportService {
    
    func exportToCSV(_ calculations: [SavedCalculation]) async throws -> URL {
        let csvContent = try generateCSVContent(calculations)
        let filename = "IRR_Calculations_\(DateFormatter.filenameDateFormatter.string(from: Date())).csv"
        return try saveToFile(csvContent, filename: filename)
    }
    
    func exportToExcel(_ calculations: [SavedCalculation]) async throws -> URL {
        // For now, export as CSV since Excel requires additional dependencies
        // In a full implementation, you would use a library like xlsxwriter or similar
        let csvContent = try generateCSVContent(calculations)
        let filename = "IRR_Calculations_\(DateFormatter.filenameDateFormatter.string(from: Date())).xlsx"
        return try saveToFile(csvContent, filename: filename)
    }
    
    func exportCalculationToCSV(_ calculation: SavedCalculation) async throws -> URL {
        let csvContent = try generateCSVContent([calculation])
        let filename = "\(calculation.name.replacingOccurrences(of: " ", with: "_")).csv"
        return try saveToFile(csvContent, filename: filename)
    }
    
    // MARK: - Private Methods
    
    private func generateCSVContent(_ calculations: [SavedCalculation]) throws -> String {
        var csvLines: [String] = []
        
        // Header row
        let headers = [
            "Name",
            "Type",
            "Created Date",
            "Modified Date",
            "Initial Investment",
            "Outcome Amount",
            "Time (Months)",
            "IRR (%)",
            "Unit Price",
            "Success Rate (%)",
            "Outcome Per Unit",
            "Investor Share (%)",
            "Fee Percentage (%)",
            "Calculated Result",
            "Project ID",
            "Notes",
            "Tags"
        ]
        
        csvLines.append(headers.joined(separator: ","))
        
        // Data rows
        for calculation in calculations {
            let row = [
                escapeCSVField(calculation.name),
                escapeCSVField(calculation.calculationType.rawValue),
                escapeCSVField(DateFormatter.csvDateFormatter.string(from: calculation.createdDate)),
                escapeCSVField(DateFormatter.csvDateFormatter.string(from: calculation.modifiedDate)),
                formatOptionalDouble(calculation.initialInvestment),
                formatOptionalDouble(calculation.outcomeAmount),
                formatOptionalDouble(calculation.timeInMonths),
                formatOptionalDouble(calculation.irr),
                formatOptionalDouble(calculation.unitPrice),
                formatOptionalDouble(calculation.successRate),
                formatOptionalDouble(calculation.outcomePerUnit),
                formatOptionalDouble(calculation.investorShare),
                formatOptionalDouble(calculation.feePercentage),
                formatOptionalDouble(calculation.calculatedResult),
                escapeCSVField(calculation.projectId?.uuidString ?? ""),
                escapeCSVField(calculation.notes ?? ""),
                escapeCSVField(calculation.tags.joined(separator: ";"))
            ]
            
            csvLines.append(row.joined(separator: ","))
        }
        
        return csvLines.joined(separator: "\n")
    }
    
    private func escapeCSVField(_ field: String) -> String {
        let needsEscaping = field.contains(",") || field.contains("\"") || field.contains("\n")
        
        if needsEscaping {
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        }
        
        return field
    }
    
    private func formatOptionalDouble(_ value: Double?) -> String {
        guard let value = value else { return "" }
        return String(format: "%.2f", value)
    }
    
    private func saveToFile(_ content: String, filename: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw CSVExcelExportError.fileWriteFailed(error)
        }
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let csvDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}