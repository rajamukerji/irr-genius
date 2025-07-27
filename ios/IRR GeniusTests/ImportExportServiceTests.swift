//
//  ImportExportServiceTests.swift
//  IRR GeniusTests
//

import XCTest
@testable import IRR_Genius

final class ImportExportServiceTests: XCTestCase {
    
    var csvImportService: CSVImportService!
    var excelImportService: ExcelImportService!
    var pdfExportService: PDFExportService!
    var csvExcelExportService: CSVExcelExportService!
    
    override func setUp() {
        super.setUp()
        csvImportService = CSVImportService()
        excelImportService = ExcelImportService()
        pdfExportService = PDFExportService()
        csvExcelExportService = CSVExcelExportService()
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
        let result = await csvImportService.importFromFile(url: tempURL)
        
        // Then should parse successfully
        switch result {
        case .success(let importData):
            XCTAssertEqual(3, importData.calculations.count)
            
            let firstCalc = importData.calculations[0]
            XCTAssertEqual("Real Estate Deal", firstCalc.name)
            XCTAssertEqual(.calculateIRR, firstCalc.calculationType)
            XCTAssertEqual(100000, firstCalc.initialInvestment)
            XCTAssertEqual(150000, firstCalc.outcomeAmount)
            XCTAssertEqual(24, firstCalc.timeInMonths)
            XCTAssertEqual("Property investment", firstCalc.notes)
            
            let secondCalc = importData.calculations[1]
            XCTAssertEqual("Stock Analysis", secondCalc.name)
            XCTAssertEqual(.calculateOutcome, secondCalc.calculationType)
            XCTAssertEqual(50000, secondCalc.initialInvestment)
            XCTAssertEqual(15, secondCalc.irr)
            
        case .failure(let error):
            XCTFail("Import should succeed: \(error)")
        }
        
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
        let result = await csvImportService.importFromFile(url: tempURL)
        
        // Then should return validation errors
        switch result {
        case .success(let importData):
            XCTAssertFalse(importData.validationErrors.isEmpty)
            XCTAssertTrue(importData.validationErrors.contains { $0.contains("empty") })
            XCTAssertTrue(importData.validationErrors.contains { $0.contains("invalidType") })
            XCTAssertTrue(importData.validationErrors.contains { $0.contains("positive") })
            
        case .failure(let error):
            XCTFail("Import should succeed but with validation errors: \(error)")
        }
        
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
        let result = await csvImportService.importFromFile(url: tempURL, delimiter: ";")
        
        // Then should parse successfully
        switch result {
        case .success(let importData):
            XCTAssertEqual(1, importData.calculations.count)
            XCTAssertEqual("Test Calculation", importData.calculations[0].name)
            
        case .failure(let error):
            XCTFail("Import should succeed: \(error)")
        }
        
        cleanupTempFile(tempURL)
    }
    
    func testCSVImportMissingFile() async {
        // When importing non-existent file
        let nonExistentURL = URL(fileURLWithPath: "/non/existent/file.csv")
        let result = await csvImportService.importFromFile(url: nonExistentURL)
        
        // Then should return failure
        switch result {
        case .success:
            XCTFail("Import should fail for non-existent file")
        case .failure(let error):
            XCTAssertTrue(error.localizedDescription.contains("not found") || 
                         error.localizedDescription.contains("No such file"))
        }
    }
    
    func testExcelImportValidData() async {
        // Note: This test would require creating an actual Excel file
        // For now, we'll test the service initialization and error handling
        
        // When importing non-existent Excel file
        let nonExistentURL = URL(fileURLWithPath: "/non/existent/file.xlsx")
        let result = await excelImportService.importFromFile(url: nonExistentURL)
        
        // Then should return failure
        switch result {
        case .success:
            XCTFail("Import should fail for non-existent file")
        case .failure(let error):
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
        let result = await pdfExportService.exportCalculationToPDF(calculation)
        
        // Then should create PDF file
        switch result {
        case .success(let pdfURL):
            XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path))
            XCTAssertTrue(pdfURL.pathExtension == "pdf")
            XCTAssertTrue(pdfURL.lastPathComponent.contains("Test_Calculation"))
            
            // Verify file has content
            let fileSize = try FileManager.default.attributesOfItem(atPath: pdfURL.path)[.size] as? Int64
            XCTAssertNotNil(fileSize)
            XCTAssertGreaterThan(fileSize!, 0)
            
            cleanupTempFile(pdfURL)
            
        case .failure(let error):
            XCTFail("PDF export should succeed: \(error)")
        }
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
                irr: 15,
                timeInMonths: 12,
                calculatedResult: 57500
            )
        ]
        
        // When exporting to PDF
        let result = await pdfExportService.exportCalculationsToPDF(calculations)
        
        // Then should create PDF file
        switch result {
        case .success(let pdfURL):
            XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path))
            XCTAssertTrue(pdfURL.pathExtension == "pdf")
            XCTAssertTrue(pdfURL.lastPathComponent.contains("Calculations_Export"))
            
            cleanupTempFile(pdfURL)
            
        case .failure(let error):
            XCTFail("PDF export should succeed: \(error)")
        }
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
                irr: 15,
                timeInMonths: 12,
                calculatedResult: 57500,
                notes: "Second calculation"
            )
        ]
        
        // When exporting to CSV
        let result = await csvExcelExportService.exportCalculationsToCSV(calculations)
        
        // Then should create CSV file
        switch result {
        case .success(let csvURL):
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
            
        case .failure(let error):
            XCTFail("CSV export should succeed: \(error)")
        }
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
                irr: 15,
                timeInMonths: 12,
                calculatedResult: 57500
            )
        ]
        
        // When exporting to Excel
        let result = await csvExcelExportService.exportCalculationsToExcel(calculations)
        
        // Then should create Excel file
        switch result {
        case .success(let excelURL):
            XCTAssertTrue(FileManager.default.fileExists(atPath: excelURL.path))
            XCTAssertTrue(excelURL.pathExtension == "xlsx")
            
            // Verify file has content
            let fileSize = try FileManager.default.attributesOfItem(atPath: excelURL.path)[.size] as? Int64
            XCTAssertNotNil(fileSize)
            XCTAssertGreaterThan(fileSize!, 0)
            
            cleanupTempFile(excelURL)
            
        case .failure(let error):
            XCTFail("Excel export should succeed: \(error)")
        }
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
        let exportResult = await csvExcelExportService.exportCalculationsToCSV([calculation])
        
        switch exportResult {
        case .success(let csvURL):
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
            let importResult = await csvImportService.importFromFile(url: csvURL)
            
            switch importResult {
            case .success(let importData):
                XCTAssertEqual(1, importData.calculations.count)
                let importedCalc = importData.calculations[0]
                XCTAssertEqual(calculation.name, importedCalc.name)
                XCTAssertEqual(calculation.calculationType, importedCalc.calculationType)
                XCTAssertEqual(calculation.unitPrice, importedCalc.unitPrice)
                XCTAssertEqual(calculation.successRate, importedCalc.successRate)
                XCTAssertEqual(calculation.outcomePerUnit, importedCalc.outcomePerUnit)
                XCTAssertEqual(calculation.investorShare, importedCalc.investorShare)
                XCTAssertEqual(calculation.feePercentage, importedCalc.feePercentage)
                
            case .failure(let error):
                XCTFail("Import should succeed: \(error)")
            }
            
            cleanupTempFile(csvURL)
            
        case .failure(let error):
            XCTFail("Export should succeed: \(error)")
        }
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