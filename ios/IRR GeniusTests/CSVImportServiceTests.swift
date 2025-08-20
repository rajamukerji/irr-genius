//
//  CSVImportServiceTests.swift
//  IRR GeniusTests
//

@testable import IRR_Genius
import XCTest

class CSVImportServiceTests: XCTestCase {
    var csvImportService: CSVImportService!

    override func setUp() {
        super.setUp()
        csvImportService = CSVImportService()
    }

    override func tearDown() {
        csvImportService = nil
        super.tearDown()
    }

    func testImportCSVWithBasicHeaders() async throws {
        let csvContent = """
        Name,Initial Investment,Outcome Amount,Time in Months,IRR
        Test Calculation 1,10000,15000,12,20.5
        Test Calculation 2,5000,8000,24,15.2
        """

        let url = try createTemporaryCSVFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await csvImportService.importCSV(from: url, hasHeaders: true)

        XCTAssertEqual(result.headers.count, 5)
        XCTAssertEqual(result.headers[0], "Name")
        XCTAssertEqual(result.headers[1], "Initial Investment")
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0][0], "Test Calculation 1")
        XCTAssertEqual(result.rows[0][1], "10000")
    }

    func testImportCSVWithDifferentDelimiters() async throws {
        let csvContent = """
        Name;Initial Investment;Outcome Amount
        Test;10000;15000
        """

        let url = try createTemporaryCSVFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await csvImportService.importCSV(from: url, delimiter: ";", hasHeaders: true)

        XCTAssertEqual(result.headers.count, 3)
        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.rows[0][0], "Test")
    }

    func testImportCSVWithQuotedValues() async throws {
        let csvContent = """
        Name,Notes
        "Test, with comma","This is a note, with comma"
        """

        let url = try createTemporaryCSVFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await csvImportService.importCSV(from: url, hasHeaders: true)

        XCTAssertEqual(result.rows[0][0], "Test, with comma")
        XCTAssertEqual(result.rows[0][1], "This is a note, with comma")
    }

    func testColumnMappingSuggestions() async throws {
        let csvContent = """
        Investment Name,Initial Amount,Exit Value,Duration Months,Return Rate
        Test,10000,15000,12,20.5
        """

        let url = try createTemporaryCSVFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await csvImportService.importCSV(from: url, hasHeaders: true)

        let mapping = result.suggestedMapping
        XCTAssertEqual(mapping["Investment Name"], .name)
        XCTAssertEqual(mapping["Initial Amount"], .initialInvestment)
        XCTAssertEqual(mapping["Exit Value"], .outcomeAmount)
        XCTAssertEqual(mapping["Duration Months"], .timeInMonths)
        XCTAssertEqual(mapping["Return Rate"], .irr)
    }

    func testValidateAndConvertCreatesValidCalculations() async throws {
        let importResult = ImportResult(
            headers: ["Name", "Initial Investment", "Outcome Amount", "Time in Months"],
            rows: [
                ["Test Calculation", "10000", "15000", "12"],
            ],
            detectedFormat: .csv(delimiter: ",", hasHeaders: true),
            suggestedMapping: [
                "Name": .name,
                "Initial Investment": .initialInvestment,
                "Outcome Amount": .outcomeAmount,
                "Time in Months": .timeInMonths,
            ],
            validationErrors: []
        )

        let columnMapping: [String: CalculationField] = [
            "Name": .name,
            "Initial Investment": .initialInvestment,
            "Outcome Amount": .outcomeAmount,
            "Time in Months": .timeInMonths,
        ]

        let validationResult = try await csvImportService.validateAndConvert(
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
                ["Test", "invalid_number", "15000"],
            ],
            detectedFormat: .csv(delimiter: ",", hasHeaders: true),
            suggestedMapping: [:],
            validationErrors: []
        )

        let columnMapping: [String: CalculationField] = [
            "Name": .name,
            "Initial Investment": .initialInvestment,
            "Outcome Amount": .outcomeAmount,
        ]

        let validationResult = try await csvImportService.validateAndConvert(
            importResult: importResult,
            columnMapping: columnMapping,
            calculationType: .calculateIRR
        )

        XCTAssertEqual(validationResult.validCalculations.count, 0)
        XCTAssertEqual(validationResult.validationErrors.count, 1)
        XCTAssertTrue(validationResult.validationErrors[0].error.message.contains("Invalid number format"))
    }

    func testPortfolioUnitInvestmentFields() async throws {
        let importResult = ImportResult(
            headers: ["Name", "Investment Amount", "Unit Price", "Success Rate", "Outcome Per Unit", "Investor Share", "Time in Months"],
            rows: [
                ["Portfolio Test", "100000", "1000", "75", "2500", "80", "36"],
            ],
            detectedFormat: .csv(delimiter: ",", hasHeaders: true),
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
            "Time in Months": .timeInMonths,
        ]

        let validationResult = try await csvImportService.validateAndConvert(
            importResult: importResult,
            columnMapping: columnMapping,
            calculationType: .portfolioUnitInvestment
        )

        XCTAssertEqual(validationResult.validCalculations.count, 1)
        XCTAssertEqual(validationResult.validationErrors.count, 0)

        let calculation = validationResult.validCalculations[0]
        XCTAssertEqual(calculation.name, "Portfolio Test")
        XCTAssertEqual(calculation.initialInvestment, 100_000.0)
        XCTAssertEqual(calculation.unitPrice, 1000.0)
        XCTAssertEqual(calculation.successRate, 75.0)
        XCTAssertEqual(calculation.outcomePerUnit, 2500.0)
        XCTAssertEqual(calculation.investorShare, 80.0)
        XCTAssertEqual(calculation.timeInMonths, 36.0)
    }

    func testImportEmptyFileThrowsError() async throws {
        let url = try createTemporaryCSVFile(content: "")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try await csvImportService.importCSV(from: url)
            XCTFail("Expected ImportError.emptyFile")
        } catch ImportError.emptyFile {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testImportCSVWithoutHeaders() async throws {
        let csvContent = """
        Test Calculation,10000,15000,12
        Another Test,5000,8000,24
        """

        let url = try createTemporaryCSVFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await csvImportService.importCSV(from: url, hasHeaders: false)

        XCTAssertEqual(result.headers.count, 4)
        XCTAssertEqual(result.headers[0], "Column 1")
        XCTAssertEqual(result.headers[1], "Column 2")
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0][0], "Test Calculation")
    }

    func testHandlesCurrencySymbolsAndFormatting() async throws {
        let csvContent = """
        Name,Initial Investment,Outcome Amount,IRR
        Test,"$10,000","$15,000",20.5%
        """

        let url = try createTemporaryCSVFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await csvImportService.importCSV(from: url, hasHeaders: true)

        let columnMapping: [String: CalculationField] = [
            "Name": .name,
            "Initial Investment": .initialInvestment,
            "Outcome Amount": .outcomeAmount,
            "IRR": .irr,
        ]

        let validationResult = try await csvImportService.validateAndConvert(
            importResult: result,
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

    private func createTemporaryCSVFile(content: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "test_\(UUID().uuidString).csv"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
