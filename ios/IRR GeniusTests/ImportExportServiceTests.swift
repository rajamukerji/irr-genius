//
//  ImportExportServiceTests.swift
//  IRR GeniusTests
//

import XCTest
@testable import IRR_Genius

final class ImportExportServiceTests: XCTestCase {
    
    var csvImportService: CSVImportService!
    var excelImportService: ExcelImportService!
    var pdfExportService: PDFExportServiceImpl!
    var csvExcelExportService: CSVExcelExportServiceImpl!
    
    override func setUp() {
        super.setUp()
        csvImportService = CSVImportService()
        excelImportService = ExcelImportService()
        pdfExportService = PDFExportServiceImpl()
        csvExcelExportService = CSVExcelExportServiceImpl()
    }
    
    override func tearDown() {
        csvImportService = nil
        excelImportService = nil
        pdfExportService = nil
        csvExcelExportService = nil
        super.tearDown()
    }
    
    func testCSVImportValidData() async throws {
        // Given a valid CSV content
        let csvContent = """
        Name,Type,Initial Investment,Outcome Amount,Time (Months),IRR,Notes
        "Real Estate Deal","calculateIRR",100000,150000,24,,"Property investment"
        "Stock Analysis","calculateOutcome",50000,,12,15,"Stock portfolio"
        "Bond Investment","calculateInitial",,120000,36,8,"Government bonds"
        """
        
        let csvData = csvContent.data(using: .utf8)!
        let tempURL = createTempFile(with: csvData, extension: "csv")
        
        // When importing CSV
        let result = try await csvImportService.importCSV(from: tempURL)
        
        // Then should parse successfully
        XCTAssertEqual(4, result.rows.count) // 3 data rows + 1 header
        XCTAssertEqual(7, result.headers.count)
        XCTAssertTrue(result.headers.contains("Name"))
        XCTAssertTrue(result.headers.contains("Type"))
        
        // Verify suggested mapping
        XCTAssertFalse(result.suggestedMapping.isEmpty)
        XCTAssertNotNil(result.suggestedMapping["Name"])
        XCTAssertNotNil(result.suggestedMapping["Type"])
        
        cleanupTempFile(tempURL)
    }
    
    func testCSVImportInvalidData() async throws {
        // Given CSV with invalid data
        let csvContent = """
        Name,Type,Initial Investment,Outcome Amount,Time (Months)
        "","calculateIRR",100000,150000,24
        "Valid Name","invalidType",50000,75000,12
        "Negative Investment","calculateIRR",-1000,150000,24
        """
        
        let csvData = csvContent.data(using: .utf8)!
        let tempURL = createTempFile(with: csvData, extension: "csv")
        
        // When importing CSV
        let result = try await csvImportService.importCSV(from: tempURL)
        
        // Then should parse the structure successfully
        XCTAssertEqual(4, result.rows.count) // 3 data rows + 1 header
        
        // Verify the import detected the data
        XCTAssertFalse(result.suggestedMapping.isEmpty)
        XCTAssertFalse(result.validationErrors.isEmpty)
        
        cleanupTempFile(tempURL)
    }
    
    func testCSVImportCustomDelimiter() async throws {
        // Given CSV with semicolon delimiter
        let csvContent = """
        Name;Type;Initial Investment;Outcome Amount;Time (Months)
        "Test Calculation";calculateIRR;100000;150000;24
        """
        
        let csvData = csvContent.data(using: .utf8)!
        let tempURL = createTempFile(with: csvData, extension: "csv")
        
        // When importing with custom delimiter
        let result = try await csvImportService.importCSV(from: tempURL, delimiter: ";")
        
        // Then should parse successfully
        XCTAssertEqual(2, result.rows.count) // 1 data row + 1 header
        XCTAssertTrue(result.headers.contains("Name"))
        
        // Verify the import detected the data with custom delimiter
        XCTAssertFalse(result.suggestedMapping.isEmpty)
        XCTAssertEqual("Test Calculation", result.rows[1][0])
        
        cleanupTempFile(tempURL)
    }
    
    func testCSVImportMissingFile() async {
        // When importing non-existent file
        let nonExistentURL = URL(fileURLWithPath: "/non/existent/file.csv")
        do {
            _ = try await csvImportService.importCSV(from: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }
    
    func testExcelImportValidData() async throws {
        // Note: This test would require creating an actual Excel file
        // For now, we'll test the service initialization and error handling
        
        // When importing non-existent Excel file
        let nonExistentURL = URL(fileURLWithPath: "/non/existent/file.xlsx")
        do {
            _ = try await excelImportService.importExcel(from: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }
    
    func testPDFExportSingleCalculation() async throws {
        // Given a calculation
        let calculation = try SavedCalculation(
            name: "Test Calculation",
            calculationType: .calculateIRR,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24,
            calculatedResult: 22.47,
            notes: "Test calculation for PDF export"
        )
        
        // When exporting to PDF
        let pdfURL = try await pdfExportService.exportToPDF(calculation)
        
        // Then should create PDF file
        XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path))
        XCTAssertTrue(pdfURL.pathExtension == "pdf")
        XCTAssertTrue(pdfURL.lastPathComponent.contains("Test_Calculation"))
        
        // Verify file has content
        let fileSize = try FileManager.default.attributesOfItem(atPath: pdfURL.path)[.size] as? Int64
        XCTAssertNotNil(fileSize)
        XCTAssertGreaterThan(fileSize!, 0)
        
        cleanupTempFile(pdfURL)
    }
    
    func testPDFExportMultipleCalculations() async throws {
        // Given multiple calculations
        let calculations = [
            try SavedCalculation(
                name: "Calculation 1",
                calculationType: .calculateIRR,
                initialInvestment: 100000,
                outcomeAmount: 150000,
                timeInMonths: 24,
                calculatedResult: 22.47
            ),
            try SavedCalculation(
                name: "Calculation 2",
                calculationType: .calculateOutcome,
                initialInvestment: 50000,
                timeInMonths: 12,
                irr: 15,
                calculatedResult: 57500
            )
        ]
        
        // When exporting to PDF
        let pdfURL = try await pdfExportService.exportMultipleCalculationsToPDF(calculations)
        
        // Then should create PDF file
        XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path))
        XCTAssertTrue(pdfURL.pathExtension == "pdf")
        XCTAssertTrue(pdfURL.lastPathComponent.contains("Calculations_Export"))
        
        cleanupTempFile(pdfURL)
    }
    
    func testCSVExportCalculations() async throws {
        // Given calculations
        let calculations = [
            try SavedCalculation(
                name: "Test Calculation 1",
                calculationType: .calculateIRR,
                initialInvestment: 100000,
                outcomeAmount: 150000,
                timeInMonths: 24,
                calculatedResult: 22.47,
                notes: "First calculation"
            ),
            try SavedCalculation(
                name: "Test Calculation 2",
                calculationType: .calculateOutcome,
                initialInvestment: 50000,
                timeInMonths: 12,
                irr: 15,
                calculatedResult: 57500,
                notes: "Second calculation"
            )
        ]
        
        // When exporting to CSV
        let csvURL = try await csvExcelExportService.exportToCSV(calculations)
        
        // Then should create CSV file
        XCTAssertTrue(FileManager.default.fileExists(atPath: csvURL.path))
        XCTAssertTrue(csvURL.pathExtension == "csv")
        
        // Verify CSV content
        let content = try String(contentsOf: csvURL)
        XCTAssertTrue(content.contains("Test Calculation 1"))
        XCTAssertTrue(content.contains("Test Calculation 2"))
        XCTAssertTrue(content.contains("calculateIRR"))
        XCTAssertTrue(content.contains("calculateOutcome"))
        XCTAssertTrue(content.contains("100000"))
        XCTAssertTrue(content.contains("22.47"))
        
        cleanupTempFile(csvURL)
    }
    
    func testExcelExportCalculations() async throws {
        // Given calculations
        let calculations = [
            try SavedCalculation(
                name: "Excel Test 1",
                calculationType: .calculateIRR,
                initialInvestment: 100000,
                outcomeAmount: 150000,
                timeInMonths: 24,
                calculatedResult: 22.47
            ),
            try SavedCalculation(
                name: "Excel Test 2",
                calculationType: .calculateOutcome,
                initialInvestment: 50000,
                timeInMonths: 12,
                irr: 15,
                calculatedResult: 57500
            )
        ]
        
        // When exporting to Excel
        let excelURL = try await csvExcelExportService.exportToExcel(calculations)
        
        // Then should create Excel file
        XCTAssertTrue(FileManager.default.fileExists(atPath: excelURL.path))
        XCTAssertTrue(excelURL.pathExtension == "xlsx")
        
        // Verify file has content
        let fileSize = try FileManager.default.attributesOfItem(atPath: excelURL.path)[.size] as? Int64
        XCTAssertNotNil(fileSize)
        XCTAssertGreaterThan(fileSize!, 0)
        
        cleanupTempFile(excelURL)
    }
    
    func testImportDataValidation() async throws {
        // Given import data with mixed valid and invalid calculations
        let validCalc = try SavedCalculation(
            name: "Valid Calculation",
            calculationType: .calculateIRR,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24
        )
        
        // When validating import data
        var validationErrors: [String] = []
        
        do {
            try validCalc.validate()
        } catch {
            validationErrors.append("Valid calc error: \(error.localizedDescription)")
        }
        
        // Create invalid calculation by trying to create with invalid data
        do {
            _ = try SavedCalculation(
                name: "", // Invalid: empty name
                calculationType: .calculateIRR,
                initialInvestment: -1000, // Invalid: negative
                timeInMonths: 24
                // Missing required outcomeAmount
            )
        } catch {
            validationErrors.append("Invalid calc error: \(error.localizedDescription)")
        }
        
        // Then should have validation errors for invalid calculation only
        XCTAssertEqual(1, validationErrors.count)
        XCTAssertTrue(validationErrors[0].contains("Invalid calc error"))
        XCTAssertTrue(validationErrors[0].contains("empty") || validationErrors[0].contains("Missing required fields"))
    }
    
    func testPortfolioUnitInvestmentImportExport() async throws {
        // Given portfolio unit investment calculation
        let calculation = try SavedCalculation(
            name: "Portfolio Test",
            calculationType: .portfolioUnitInvestment,
            initialInvestment: 100000,
            timeInMonths: 36,
            unitPrice: 1000,
            successRate: 75,
            outcomePerUnit: 2000,
            investorShare: 80,
            feePercentage: 2.5,
            calculatedResult: 18.5
        )
        
        // When exporting to CSV
        let csvURL = try await csvExcelExportService.exportToCSV([calculation])
        
        // Then should export successfully
        let content = try String(contentsOf: csvURL)
        XCTAssertTrue(content.contains("Portfolio Test"))
        XCTAssertTrue(content.contains("portfolioUnitInvestment"))
        XCTAssertTrue(content.contains("1000")) // Unit price
        XCTAssertTrue(content.contains("75")) // Success rate
        XCTAssertTrue(content.contains("2000")) // Outcome per unit
        XCTAssertTrue(content.contains("80")) // Investor share
        XCTAssertTrue(content.contains("2.5")) // Fee percentage
        
        // When importing back
        let importResult = try await csvImportService.importCSV(from: csvURL)
        
        // Verify import parsing (basic structure check)
        XCTAssertFalse(importResult.headers.isEmpty)
        XCTAssertFalse(importResult.rows.isEmpty)
        
        cleanupTempFile(csvURL)
    }
    
    // MARK: - Helper Methods
    
    private func createTempFile(with data: Data, extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
        
        do {
            try data.write(to: tempURL)
        } catch {
            XCTFail("Failed to create temp file: \(error)")
        }
        
        return tempURL
    }
    
    private func cleanupTempFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}