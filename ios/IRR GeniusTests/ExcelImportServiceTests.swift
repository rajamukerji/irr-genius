//
//  ExcelImportServiceTests.swift
//  IRR GeniusTests
//

import XCTest
@testable import IRR_Genius

class ExcelImportServiceTests: XCTestCase {
    
    var excelImportService: ExcelImportService!
    
    override func setUp() {
        super.setUp()
        excelImportService = ExcelImportService()
    }
    
    override func tearDown() {
        excelImportService = nil
        super.tearDown()
    }
    
    func testImportExcelWithBasicData() async throws {
        // Create a mock Excel file (in reality, this would be a proper Excel file)
        let excelContent = createMockExcelData()
        let url = try createTemporaryExcelFile(data: excelContent, fileName: "test.xlsx")
        defer { try? FileManager.default.removeItem(at: url) }
        
        let result = try await excelImportService.importExcel(from: url, hasHeaders: true)
        
        XCTAssertEqual(result.headers.count, 5)
        XCTAssertEqual(result.headers[0], "Name")
        XCTAssertEqual(result.headers[1], "Initial Investment")
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0][0], "Sample Calculation 1")
        XCTAssertEqual(result.rows[0][1], "10000")
    }
    
    func testColumnMappingSuggestions() async throws {
        let excelContent = createMockExcelData()
        let url = try createTemporaryExcelFile(data: excelContent, fileName: "test.xlsx")
        defer { try? FileManager.default.removeItem(at: url) }
        
        let result = try await excelImportService.importExcel(from: url, hasHeaders: true)
        
        let mapping = result.suggestedMapping
        XCTAssertEqual(mapping["Name"], .name)
        XCTAssertEqual(mapping["Initial Investment"], .initialInvestment)
        XCTAssertEqual(mapping["Outcome Amount"], .outcomeAmount)
        XCTAssertEqual(mapping["Time in Months"], .timeInMonths)
        XCTAssertEqual(mapping["IRR"], .irr)
    }
    
    func testValidateAndConvertCreatesValidCalculations() async throws {
        let importResult = ImportResult(
            headers: ["Name", "Initial Investment", "Outcome Amount", "Time in Months"],
            rows: [
                ["Test Calculation", "10000", "15000", "12"]
            ],
            detectedFormat: .excel(sheetName: "Sheet1", hasHeaders: true),
            suggestedMapping: [
                "Name": .name,
                "Initial Investment": .initialInvestment,
                "Outcome Amount": .outcomeAmount,
                "Time in Months": .timeInMonths
            ],
            validationErrors: []
        )
        
        let columnMapping: [String: CalculationField] = [
            "Name": .name,
            "Initial Investment": .initialInvestment,
            "Outcome Amount": .outcomeAmount,
            "Time in Months": .timeInMonths
        ]
        
        let validationResult = try await excelImportService.validateAndConvert(
            importResult: importResult,
            columnMapping: columnMapping,
            calculationType: .calculateIRR
        )
        
        XCTAssertEqual(validationResult.validCalculations.count, 1)
        XCTAssertEqual(validationResult.validationErrors.count, 0)
        
        let calculation = validationResult.validCalculations[0]
        XCTAssertEqual(calculation.name, "Test Calculation")
        XCTAssertEqual(calculation.initialInvestment, 10000.0)
        XCTAssertEqual(calculation.outcomeAmount, 15000.0)
        XCTAssertEqual(calculation.timeInMonths, 12.0)
        XCTAssertEqual(calculation.calculationType, .calculateIRR)
    }
    
    func testValidateAndConvertHandlesValidationErrors() async throws {
        let importResult = ImportResult(
            headers: ["Name", "Initial Investment", "Outcome Amount"],
            rows: [
                ["Test", "invalid_number", "15000"]
            ],
            detectedFormat: .excel(sheetName: "Sheet1", hasHeaders: true),
            suggestedMapping: [:],
            validationErrors: []
        )
        
        let columnMapping: [String: CalculationField] = [
            "Name": .name,
            "Initial Investment": .initialInvestment,
            "Outcome Amount": .outcomeAmount
        ]
        
        let validationResult = try await excelImportService.validateAndConvert(
            importResult: importResult,
            columnMapping: columnMapping,
            calculationType: .calculateIRR
        )
        
        XCTAssertEqual(validationResult.validCalculations.count, 0)
        XCTAssertEqual(validationResult.validationErrors.count, 1)
        XCTAssertTrue(validationResult.validationErrors[0].message.contains("Invalid number format"))
    }
    
    func testPortfolioUnitInvestmentFields() async throws {
        let importResult = ImportResult(
            headers: ["Name", "Investment Amount", "Unit Price", "Success Rate", "Outcome Per Unit", "Investor Share", "Time in Months"],
            rows: [
                ["Portfolio Test", "100000", "1000", "75", "2500", "80", "36"]
            ],
            detectedFormat: .excel(sheetName: "Sheet1", hasHeaders: true),
            suggestedMapping: [:],
            validationErrors: []
        )
        
        let columnMapping: [String: CalculationField] = [
            "Name": .name,
            "Investment Amount": .initialInvestment,
            "Unit Price": .unitPrice,
            "Success Rate": .successRate,
            "Outcome Per Unit": .outcomePerUnit,
            "Investor Share": .investorShare,
            "Time in Months": .timeInMonths
        ]
        
        let validationResult = try await excelImportService.validateAndConvert(
            importResult: importResult,
            columnMapping: columnMapping,
            calculationType: .portfolioUnitInvestment
        )
        
        XCTAssertEqual(validationResult.validCalculations.count, 1)
        XCTAssertEqual(validationResult.validationErrors.count, 0)
        
        let calculation = validationResult.validCalculations[0]
        XCTAssertEqual(calculation.name, "Portfolio Test")
        XCTAssertEqual(calculation.initialInvestment, 100000.0)
        XCTAssertEqual(calculation.unitPrice, 1000.0)
        XCTAssertEqual(calculation.successRate, 75.0)
        XCTAssertEqual(calculation.outcomePerUnit, 2500.0)
        XCTAssertEqual(calculation.investorShare, 80.0)
        XCTAssertEqual(calculation.timeInMonths, 36.0)
    }
    
    func testGetSheetNames() async throws {
        let excelContent = createMockExcelData()
        let url = try createTemporaryExcelFile(data: excelContent, fileName: "test.xlsx")
        defer { try? FileManager.default.removeItem(at: url) }
        
        let sheetNames = try await excelImportService.getSheetNames(from: url)
        
        XCTAssertTrue(sheetNames.count > 0)
        XCTAssertTrue(sheetNames.contains("Sheet1"))
    }
    
    func testImportExcelWithSheetSelection() async throws {
        let excelContent = createMockExcelData()
        let url = try createTemporaryExcelFile(data: excelContent, fileName: "test.xlsx")
        defer { try? FileManager.default.removeItem(at: url) }
        
        let result = try await excelImportService.importExcelWithSheetSelection(
            from: url,
            sheetName: "Sheet1",
            hasHeaders: true
        )
        
        XCTAssertEqual(result.headers.count, 5)
        XCTAssertEqual(result.rows.count, 2)
    }
    
    func testImportExcelWithRange() async throws {
        let excelContent = createMockExcelData()
        let url = try createTemporaryExcelFile(data: excelContent, fileName: "test.xlsx")
        defer { try? FileManager.default.removeItem(at: url) }
        
        let result = try await excelImportService.importExcelWithRange(
            from: url,
            startRow: 0,
            endRow: 1,
            startColumn: 0,
            endColumn: 2,
            hasHeaders: true
        )
        
        XCTAssertEqual(result.headers.count, 3) // Columns 0-2
        XCTAssertEqual(result.rows.count, 1) // Rows 0-1 (minus header)
    }
    
    func testImportUnsupportedFileFormat() async throws {
        let textContent = "This is not an Excel file"
        let url = try createTemporaryFile(content: textContent, fileName: "test.txt")
        defer { try? FileManager.default.removeItem(at: url) }
        
        do {
            _ = try await excelImportService.importExcel(from: url)
            XCTFail("Expected ImportError.unsupportedFormat")
        } catch ImportError.unsupportedFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testHandlesCurrencySymbolsAndFormatting() async throws {
        let importResult = ImportResult(
            headers: ["Name", "Initial Investment", "Outcome Amount", "IRR"],
            rows: [
                ["Test", "$10,000", "$15,000", "20.5%"]
            ],
            detectedFormat: .excel(sheetName: "Sheet1", hasHeaders: true),
            suggestedMapping: [:],
            validationErrors: []
        )
        
        let columnMapping: [String: CalculationField] = [
            "Name": .name,
            "Initial Investment": .initialInvestment,
            "Outcome Amount": .outcomeAmount,
            "IRR": .irr
        ]
        
        let validationResult = try await excelImportService.validateAndConvert(
            importResult: importResult,
            columnMapping: columnMapping,
            calculationType: .calculateIRR
        )
        
        XCTAssertEqual(validationResult.validCalculations.count, 1)
        let calculation = validationResult.validCalculations[0]
        XCTAssertEqual(calculation.initialInvestment, 10000.0)
        XCTAssertEqual(calculation.outcomeAmount, 15000.0)
        XCTAssertEqual(calculation.irr, 20.5)
    }
    
    // MARK: - Helper Methods
    
    private func createMockExcelData() -> Data {
        // This creates mock data that represents what would be in an Excel file
        // In a real implementation, this would be actual Excel binary data
        let mockData = """
        Name,Initial Investment,Outcome Amount,Time in Months,IRR
        Sample Calculation 1,10000,15000,12,20.5
        Sample Calculation 2,5000,8000,24,15.2
        """.data(using: .utf8) ?? Data()
        
        return mockData
    }
    
    private func createTemporaryExcelFile(data: Data, fileName: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("test_\(UUID().uuidString)_\(fileName)")
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    private func createTemporaryFile(content: String, fileName: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("test_\(UUID().uuidString)_\(fileName)")
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}