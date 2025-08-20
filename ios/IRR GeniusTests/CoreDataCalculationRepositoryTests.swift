//
//  CoreDataCalculationRepositoryTests.swift
//  IRR GeniusTests
//
//

import CoreData
@testable import IRR_Genius
import XCTest

final class CoreDataCalculationRepositoryTests: XCTestCase {
    var repository: CoreDataCalculationRepository!
    var testContainer: NSPersistentContainer!

    override func setUp() {
        super.setUp()
        testContainer = CoreDataStack.createInMemoryContainer()
        repository = CoreDataCalculationRepository(container: testContainer)
    }

    override func tearDown() {
        repository = nil
        testContainer = nil
        super.tearDown()
    }

    func testSaveAndLoadCalculation() async throws {
        // Given
        let calculation = createTestCalculation()

        // When
        try await repository.saveCalculation(calculation)
        let loaded = try await repository.loadCalculation(id: calculation.id)

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, calculation.id)
        XCTAssertEqual(loaded?.name, calculation.name)
        XCTAssertEqual(loaded?.calculationType, calculation.calculationType)
        XCTAssertEqual(loaded?.initialInvestment, calculation.initialInvestment)
        XCTAssertEqual(loaded?.calculatedResult, calculation.calculatedResult)
    }

    func testLoadAllCalculations() async throws {
        // Given
        let calculation1 = createTestCalculation(name: "Test 1")
        let calculation2 = createTestCalculation(name: "Test 2")

        // When
        try await repository.saveCalculation(calculation1)
        try await repository.saveCalculation(calculation2)
        let calculations = try await repository.loadCalculations()

        // Then
        XCTAssertEqual(calculations.count, 2)
        XCTAssertTrue(calculations.contains { $0.name == "Test 1" })
        XCTAssertTrue(calculations.contains { $0.name == "Test 2" })
    }

    func testDeleteCalculation() async throws {
        // Given
        let calculation = createTestCalculation()
        try await repository.saveCalculation(calculation)

        // When
        try await repository.deleteCalculation(id: calculation.id)
        let loaded = try await repository.loadCalculation(id: calculation.id)

        // Then
        XCTAssertNil(loaded)
    }

    func testSearchCalculations() async throws {
        // Given
        let calculation1 = createTestCalculation(name: "IRR Analysis")
        let calculation2 = createTestCalculation(name: "Outcome Calculation")
        let calculation3 = createTestCalculation(name: "Investment Study")

        try await repository.saveCalculation(calculation1)
        try await repository.saveCalculation(calculation2)
        try await repository.saveCalculation(calculation3)

        // When
        let results = try await repository.searchCalculations(query: "IRR")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.name == "IRR Analysis" })
        XCTAssertTrue(results.contains { $0.name == "Investment Study" })
    }

    func testLoadCalculationsByProject() async throws {
        // Given
        let projectId = UUID()
        let calculation1 = createTestCalculation(name: "Test 1", projectId: projectId)
        let calculation2 = createTestCalculation(name: "Test 2", projectId: projectId)
        let calculation3 = createTestCalculation(name: "Test 3") // No project

        try await repository.saveCalculation(calculation1)
        try await repository.saveCalculation(calculation2)
        try await repository.saveCalculation(calculation3)

        // When
        let results = try await repository.loadCalculationsByProject(projectId: projectId)

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.name == "Test 1" })
        XCTAssertTrue(results.contains { $0.name == "Test 2" })
    }

    func testSaveCalculationWithFollowOnInvestments() async throws {
        // Given
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
        let calculation = createTestCalculation(followOnInvestments: [followOn])

        // When
        try await repository.saveCalculation(calculation)
        let loaded = try await repository.loadCalculation(id: calculation.id)

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertNotNil(loaded?.followOnInvestments)
        XCTAssertEqual(loaded?.followOnInvestments?.count, 1)
        XCTAssertEqual(loaded?.followOnInvestments?.first?.amount, "50000")
    }

    // MARK: - Helper Methods

    private func createTestCalculation(
        name: String = "Test Calculation",
        projectId: UUID? = nil,
        followOnInvestments: [FollowOnInvestment]? = nil
    ) -> SavedCalculation {
        return try! SavedCalculation(
            name: name,
            calculationType: .calculateIRR,
            projectId: projectId,
            initialInvestment: 100_000,
            timeInMonths: 24,
            followOnInvestments: followOnInvestments,
            calculatedResult: 15.5,
            growthPoints: [
                GrowthPoint(month: 0, value: 100_000),
                GrowthPoint(month: 12, value: 110_000),
                GrowthPoint(month: 24, value: 125_000),
            ],
            notes: "Test calculation notes"
        )
    }
}
