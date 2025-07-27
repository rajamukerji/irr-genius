//
//  ProjectValidationTests.swift
//  IRR GeniusTests
//

import XCTest
@testable import IRR_Genius

final class ProjectValidationTests: XCTestCase {
    
    func testValidProjectCreation() throws {
        // Given valid inputs
        let project = try Project(
            name: "Real Estate Portfolio",
            description: "Investment properties analysis",
            color: "#007AFF"
        )
        
        // Then project should be created successfully
        XCTAssertEqual("Real Estate Portfolio", project.name)
        XCTAssertEqual("Investment properties analysis", project.description)
        XCTAssertEqual("#007AFF", project.color)
        XCTAssertTrue(project.isValid)
    }
    
    func testEmptyNameValidation() {
        // When creating project with empty name
        XCTAssertThrowsError(try Project(name: "")) { error in
            // Then should throw validation error
            XCTAssertTrue(error is ProjectValidationError)
            if case ProjectValidationError.emptyName = error {
                // Expected error type
            } else {
                XCTFail("Expected emptyName error")
            }
        }
    }
    
    func testLongNameValidation() {
        // Given name longer than 50 characters
        let longName = String(repeating: "a", count: 51)
        
        // When creating project
        XCTAssertThrowsError(try Project(name: longName)) { error in
            // Then should throw validation error
            XCTAssertTrue(error is ProjectValidationError)
            if case ProjectValidationError.invalidName(let reason) = error {
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
            // When creating project
            XCTAssertThrowsError(try Project(name: invalidName)) { error in
                // Then should throw validation error
                XCTAssertTrue(error is ProjectValidationError)
                if case ProjectValidationError.invalidName(let reason) = error {
                    XCTAssertTrue(reason.contains("invalid characters"))
                } else {
                    XCTFail("Expected invalidName error for: \(invalidName)")
                }
            }
        }
    }
    
    func testLongDescriptionValidation() {
        // Given description longer than 500 characters
        let longDescription = String(repeating: "a", count: 501)
        
        // When creating project
        XCTAssertThrowsError(try Project(
            name: "Test Project",
            description: longDescription
        )) { error in
            // Then should throw validation error
            XCTAssertTrue(error is ProjectValidationError)
            if case ProjectValidationError.invalidDescription(let reason) = error {
                XCTAssertTrue(reason.contains("too long"))
            } else {
                XCTFail("Expected invalidDescription error")
            }
        }
    }
    
    func testInvalidColorValidation() {
        // Given invalid color formats
        let invalidColors = ["FF0000", "#GG0000", "#12345", "#1234567", "red", ""]
        
        for invalidColor in invalidColors {
            // When creating project
            XCTAssertThrowsError(try Project(
                name: "Test Project",
                color: invalidColor
            )) { error in
                // Then should throw validation error
                XCTAssertTrue(error is ProjectValidationError)
                if case ProjectValidationError.invalidColor(let reason) = error {
                    XCTAssertTrue(reason.contains("valid hex color"))
                } else {
                    XCTFail("Expected invalidColor error for: \(invalidColor)")
                }
            }
        }
    }
    
    func testValidColorFormats() throws {
        // Given valid color formats
        let validColors = ["#FF0000", "#00FF00", "#0000FF", "#FFF", "#000", "#123ABC"]
        
        for validColor in validColors {
            // When creating project
            let project = try Project(
                name: "Test Project",
                color: validColor
            )
            
            // Then should be created successfully
            XCTAssertEqual(validColor, project.color)
            XCTAssertTrue(project.isValid)
        }
    }
    
    func testDefaultColors() {
        // Test that default colors are valid
        for color in Project.defaultColors {
            XCTAssertNoThrow(try Project.validateColor(color))
        }
        
        // Test that we have expected number of default colors
        XCTAssertEqual(10, Project.defaultColors.count)
        XCTAssertTrue(Project.defaultColors.contains("#007AFF")) // Blue
        XCTAssertTrue(Project.defaultColors.contains("#34C759")) // Green
    }
    
    func testProjectStatistics() throws {
        // Given a project and calculations
        let project = try Project(name: "Test Project")
        
        let calculations = [
            try createTestCalculation(projectId: project.id, isComplete: true, type: .calculateIRR),
            try createTestCalculation(projectId: project.id, isComplete: false, type: .calculateOutcome),
            try createTestCalculation(projectId: project.id, isComplete: true, type: .calculateIRR),
            try createTestCalculation(projectId: UUID(), isComplete: true, type: .calculateInitial) // Different project
        ]
        
        // When calculating statistics
        let stats = project.calculateStatistics(from: calculations)
        
        // Then should return correct statistics
        XCTAssertEqual(3, stats.totalCalculations) // Only calculations for this project
        XCTAssertEqual(2, stats.completedCalculations)
        XCTAssertEqual(0.67, stats.completionRate, accuracy: 0.01)
        XCTAssertEqual(2, stats.calculationTypes[.calculateIRR])
        XCTAssertEqual(1, stats.calculationTypes[.calculateOutcome])
        XCTAssertNil(stats.calculationTypes[.calculateInitial]) // Not in this project
    }
    
    func testProjectStatisticsEmptyCalculations() throws {
        // Given a project with no calculations
        let project = try Project(name: "Empty Project")
        
        // When calculating statistics
        let stats = project.calculateStatistics(from: [])
        
        // Then should return zero statistics
        XCTAssertEqual(0, stats.totalCalculations)
        XCTAssertEqual(0, stats.completedCalculations)
        XCTAssertEqual(0.0, stats.completionRate)
        XCTAssertTrue(stats.calculationTypes.isEmpty)
        XCTAssertNil(stats.lastModified)
    }
    
    func testModificationDateUpdate() throws {
        // Given a project
        let original = try Project(
            name: "Test Project",
            description: "Original description"
        )
        
        // Wait a bit to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.01)
        
        // When updating modification date
        let updated = original.withUpdatedModificationDate()
        
        // Then modification date should be newer
        XCTAssertTrue(updated.modifiedDate > original.modifiedDate)
        XCTAssertEqual(original.id, updated.id)
        XCTAssertEqual(original.name, updated.name)
        XCTAssertEqual(original.description, updated.description)
    }
    
    func testProjectValidation() throws {
        // Given a valid project
        let project = try Project(
            name: "Valid Project",
            description: "Valid description",
            color: "#FF0000"
        )
        
        // When validating
        XCTAssertNoThrow(try project.validate())
        XCTAssertTrue(project.isValid)
    }
    
    func testProjectEquality() throws {
        // Given two identical projects
        let project1 = try Project(
            id: UUID(),
            name: "Test Project",
            description: "Test description",
            color: "#FF0000"
        )
        
        let project2 = try Project(
            id: project1.id,
            name: "Test Project",
            description: "Test description",
            color: "#FF0000"
        )
        
        // Then they should be equal
        XCTAssertEqual(project1, project2)
        XCTAssertEqual(project1.hashValue, project2.hashValue)
    }
    
    func testProjectInequality() throws {
        // Given two different projects
        let project1 = try Project(name: "Project 1")
        let project2 = try Project(name: "Project 2")
        
        // Then they should not be equal
        XCTAssertNotEqual(project1, project2)
        XCTAssertNotEqual(project1.hashValue, project2.hashValue)
    }
    
    func testProjectCodable() throws {
        // Given a project
        let original = try Project(
            name: "Codable Test",
            description: "Testing Codable conformance",
            color: "#007AFF"
        )
        
        // When encoding and decoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Project.self, from: data)
        
        // Then should be identical
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.description, decoded.description)
        XCTAssertEqual(original.color, decoded.color)
        XCTAssertEqual(original.createdDate.timeIntervalSince1970, decoded.createdDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestCalculation(
        projectId: UUID,
        isComplete: Bool,
        type: CalculationMode
    ) throws -> SavedCalculation {
        if isComplete {
            return try SavedCalculation(
                name: "Test Calculation",
                calculationType: type,
                projectId: projectId,
                initialInvestment: 100000,
                outcomeAmount: 150000,
                timeInMonths: 24,
                calculatedResult: 22.47
            )
        } else {
            // Create incomplete calculation by omitting required fields
            return try SavedCalculation(
                name: "Incomplete Calculation",
                calculationType: type,
                projectId: projectId
                // Missing required fields for the calculation type
            )
        }
    }
}