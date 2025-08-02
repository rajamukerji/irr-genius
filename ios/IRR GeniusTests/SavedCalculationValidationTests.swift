//
//  SavedCalculationValidationTests.swift
//  IRR GeniusTests
//

import XCTest
@testable import IRR_Genius

final class SavedCalculationValidationTests: XCTestCase {
    
    func testValidCalculationCreation() throws {
        // Given valid inputs
        let calculation = try SavedCalculation(
            name: "Test Calculation",
            calculationType: .calculateIRR,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24,
            calculatedResult: 22.47
        )
        
        // Then calculation should be created successfully
        XCTAssertEqual("Test Calculation", calculation.name)
        XCTAssertEqual(.calculateIRR, calculation.calculationType)
        XCTAssertTrue(calculation.isComplete)
    }
    
    func testEmptyNameValidation() {
        // When creating calculation with empty name
        XCTAssertThrowsError(try SavedCalculation(
            name: "",
            calculationType: .calculateIRR
        )) { error in
            // Then should throw validation error
            XCTAssertTrue(error is SavedCalculationValidationError)
            if case SavedCalculationValidationError.emptyName = error {
                // Expected error type
            } else {
                XCTFail("Expected emptyName error")
            }
        }
    }
    
    func testLongNameValidation() {
        // Given name longer than 100 characters
        let longName = String(repeating: "a", count: 101)
        
        // When creating calculation
        XCTAssertThrowsError(try SavedCalculation(
            name: longName,
            calculationType: .calculateIRR
        )) { error in
            // Then should throw validation error
            XCTAssertTrue(error is SavedCalculationValidationError)
            if case SavedCalculationValidationError.invalidName(let reason) = error {
                XCTAssertTrue(reason.contains("too long"))
            } else {
                XCTFail("Expected invalidName error")
            }
        }
    }
    
    func testInvalidCharactersInName() {
        // Given names with invalid characters
        let invalidNames = ["test<name", "test>name", "test:name", "test\"name", "test/name"]
        
        for invalidName in invalidNames {
            // When creating calculation
            XCTAssertThrowsError(try SavedCalculation(
                name: invalidName,
                calculationType: .calculateIRR
            )) { error in
                // Then should throw validation error
                XCTAssertTrue(error is SavedCalculationValidationError)
                if case SavedCalculationValidationError.invalidName(let reason) = error {
                    XCTAssertTrue(reason.contains("invalid characters"))
                } else {
                    XCTFail("Expected invalidName error for: \(invalidName)")
                }
            }
        }
    }
    
    func testCalculateIRRValidation() {
        // Test missing required fields
        XCTAssertThrowsError(try SavedCalculation(
            name: "Test",
            calculationType: .calculateIRR,
            initialInvestment: 100000
            // Missing outcomeAmount and timeInMonths
        )) { error in
            if case SavedCalculationValidationError.missingRequiredFields(let fields) = error {
                XCTAssertTrue(fields.contains("Outcome Amount"))
                XCTAssertTrue(fields.contains("Time in Months"))
            } else {
                XCTFail("Expected missingRequiredFields error")
            }
        }
    }
    
    func testNegativeInvestmentValidation() {
        // When creating calculation with negative investment
        XCTAssertThrowsError(try SavedCalculation(
            name: "Test",
            calculationType: .calculateIRR,
            initialInvestment: -1000,
            outcomeAmount: 150000,
            timeInMonths: 24
        )) { error in
            // Then should throw validation error
            XCTAssertTrue(error is SavedCalculationValidationError)
            if case SavedCalculationValidationError.negativeInvestment = error {
                // Expected error type
            } else {
                XCTFail("Expected negativeInvestment error")
            }
        }
    }
    
    func testPortfolioUnitInvestmentValidation() throws {
        // Test all required fields for portfolio unit investment
        let calculation = try SavedCalculation(
            name: "Portfolio Test",
            calculationType: .portfolioUnitInvestment,
            initialInvestment: 100000,
            timeInMonths: 36,
            unitPrice: 1000,
            successRate: 75,
            outcomePerUnit: 2000,
            investorShare: 80
        )
        
        XCTAssertEqual(.portfolioUnitInvestment, calculation.calculationType)
        XCTAssertEqual(75, calculation.successRate)
        XCTAssertTrue(calculation.isComplete)
    }
    
    func testInvalidSuccessRate() {
        // Test success rate outside valid range
        XCTAssertThrowsError(try SavedCalculation(
            name: "Test",
            calculationType: .portfolioUnitInvestment,
            initialInvestment: 100000,
            timeInMonths: 36,
            unitPrice: 1000,
            successRate: 150, // Invalid: > 100
            outcomePerUnit: 2000,
            investorShare: 80
        )) { error in
            XCTAssertTrue(error is SavedCalculationValidationError)
            if case SavedCalculationValidationError.invalidIRR = error {
                // Expected error type (reused for percentage validation)
            } else {
                XCTFail("Expected invalidIRR error for success rate")
            }
        }
    }
    
    func testCalculationSummary() throws {
        // Test different calculation type summaries
        let irrCalc = try SavedCalculation(
            name: "IRR Test",
            calculationType: .calculateIRR,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24,
            calculatedResult: 22.47
        )
        
        XCTAssertEqual("IRR: 22.47%", irrCalc.summary)
        
        let outcomeCalc = try SavedCalculation(
            name: "Outcome Test",
            calculationType: .calculateOutcome,
            initialInvestment: 100000,
            timeInMonths: 24,
            irr: 15,
            calculatedResult: 132500
        )
        
        XCTAssertEqual("Outcome: $132500.00", outcomeCalc.summary)
    }
    
    func testFollowOnInvestmentValidation() throws {
        // Given valid follow-on investment
        let followOn = FollowOnInvestment(
            timingType: .absoluteDate,
            date: Date(),
            relativeAmount: "12",
            relativeUnit: .months,
            investmentType: .buy,
            amount: "50000",
            valuationMode: .tagAlong,
            valuationType: .computed,
            valuation: "100000",
            irr: "15.0",
            initialInvestmentDate: Date()
        )
        
        // When creating calculation with follow-on investments
        let calculation = try SavedCalculation(
            name: "Test with Follow-on",
            calculationType: .calculateBlendedIRR,
            initialInvestment: 100000,
            outcomeAmount: 200000,
            timeInMonths: 36,
            followOnInvestments: [followOn]
        )
        
        // Then should be created successfully
        XCTAssertEqual(1, calculation.followOnInvestments?.count)
        XCTAssertTrue(calculation.isComplete)
    }
    
    func testInvalidFollowOnInvestmentValidation() {
        // Given invalid follow-on investment (negative amount)
        let invalidFollowOn = FollowOnInvestment(
            timingType: .absoluteDate,
            date: Date(),
            relativeAmount: "12",
            relativeUnit: .months,
            investmentType: .buy,
            amount: "-50000", // Invalid: negative amount
            valuationMode: .tagAlong,
            valuationType: .computed,
            valuation: "100000",
            irr: "15.0",
            initialInvestmentDate: Date()
        )
        
        // When creating calculation with invalid follow-on investments
        XCTAssertThrowsError(try SavedCalculation(
            name: "Test with Invalid Follow-on",
            calculationType: .calculateBlendedIRR,
            initialInvestment: 100000,
            outcomeAmount: 200000,
            timeInMonths: 36,
            followOnInvestments: [invalidFollowOn]
        )) { error in
            if case SavedCalculationValidationError.invalidFollowOnInvestments(let errors) = error {
                XCTAssertFalse(errors.isEmpty)
                XCTAssertTrue(errors[0].contains("positive"))
            } else {
                XCTFail("Expected invalidFollowOnInvestments error")
            }
        }
    }
    
    func testTagsSerialization() throws {
        // Test tags serialization
        let calculation = try SavedCalculation(
            name: "Test",
            calculationType: .calculateIRR,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24,
            tags: ["real-estate", "investment", "analysis"]
        )
        
        XCTAssertEqual(3, calculation.tags.count)
        XCTAssertTrue(calculation.tags.contains("real-estate"))
        XCTAssertTrue(calculation.tags.contains("investment"))
        XCTAssertTrue(calculation.tags.contains("analysis"))
        
        // Test JSON serialization
        let tagsJSON = calculation.tagsJSON
        XCTAssertTrue(tagsJSON.contains("real-estate"))
        XCTAssertTrue(tagsJSON.contains("investment"))
        XCTAssertTrue(tagsJSON.contains("analysis"))
        
        // Test deserialization
        let deserializedTags = SavedCalculation.tags(from: tagsJSON)
        XCTAssertEqual(calculation.tags.sorted(), deserializedTags.sorted())
    }
    
    func testGrowthPointsSerialization() throws {
        // Test growth points serialization
        let growthPoints = [
            GrowthPoint(month: 0, value: 100000),
            GrowthPoint(month: 12, value: 110000),
            GrowthPoint(month: 24, value: 125000)
        ]
        
        let calculation = try SavedCalculation(
            name: "Test",
            calculationType: .calculateIRR,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24,
            growthPoints: growthPoints
        )
        
        XCTAssertEqual(3, calculation.growthPoints?.count)
        XCTAssertEqual(0, calculation.growthPoints?[0].month)
        XCTAssertEqual(100000, calculation.growthPoints?[0].value)
        XCTAssertEqual(24, calculation.growthPoints?[2].month)
        XCTAssertEqual(125000, calculation.growthPoints?[2].value)
        
        // Test serialization to Data
        let growthPointsData = calculation.growthPointsData
        XCTAssertNotNil(growthPointsData)
        
        // Test deserialization from Data
        let deserializedPoints = SavedCalculation.growthPoints(from: growthPointsData)
        XCTAssertEqual(growthPoints.count, deserializedPoints?.count)
        XCTAssertEqual(growthPoints[0].month, deserializedPoints?[0].month)
        XCTAssertEqual(growthPoints[0].value, deserializedPoints?[0].value)
    }
    
    func testModificationDateUpdate() throws {
        // Given a calculation
        let original = try SavedCalculation(
            name: "Test",
            calculationType: .calculateIRR,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24
        )
        
        // Wait a bit to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.01)
        
        // When updating modification date
        let updated = original.withUpdatedModificationDate()
        
        // Then modification date should be newer
        XCTAssertTrue(updated.modifiedDate > original.modifiedDate)
        XCTAssertEqual(original.id, updated.id)
        XCTAssertEqual(original.name, updated.name)
    }
    
    func testCalculationValidation() throws {
        // Given a valid calculation
        let calculation = try SavedCalculation(
            name: "Valid Calculation",
            calculationType: .calculateIRR,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24
        )
        
        // When validating
        XCTAssertNoThrow(try calculation.validate())
        XCTAssertTrue(calculation.isComplete)
    }
    
    func testFollowOnInvestmentsSerialization() throws {
        // Given calculation with follow-on investments
        let followOn = FollowOnInvestment(
            timingType: .absoluteDate,
            date: Date(),
            relativeAmount: "12",
            relativeUnit: .months,
            investmentType: .buy,
            amount: "50000",
            valuationMode: .tagAlong,
            valuationType: .computed,
            valuation: "100000",
            irr: "15.0",
            initialInvestmentDate: Date()
        )
        
        let calculation = try SavedCalculation(
            name: "Test",
            calculationType: .calculateBlendedIRR,
            initialInvestment: 100000,
            outcomeAmount: 200000,
            timeInMonths: 36,
            followOnInvestments: [followOn]
        )
        
        // When serializing to Data
        let followOnData = calculation.followOnInvestmentsData
        XCTAssertNotNil(followOnData)
        
        // When deserializing from Data
        let deserializedFollowOns = SavedCalculation.followOnInvestments(from: followOnData)
        XCTAssertNotNil(deserializedFollowOns)
        XCTAssertEqual(1, deserializedFollowOns?.count)
        XCTAssertEqual(followOn.amount, deserializedFollowOns?[0].amount)
        XCTAssertEqual(followOn.investmentType, deserializedFollowOns?[0].investmentType)
    }
}