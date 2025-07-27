//
//  SaveLoadExportIntegrationTests.swift
//  IRR GeniusTests
//

import XCTest
import CoreData
@testable import IRR_Genius

final class SaveLoadExportIntegrationTests: XCTestCase {
    
    var testContainer: NSPersistentContainer!
    var calculationRepository: CoreDataCalculationRepository!
    var projectRepository: CoreDataProjectRepository!
    var csvImportService: CSVImportService!
    var pdfExportService: PDFExportService!
    var csvExcelExportService: CSVExcelExportService!
    
    override func setUp() {
        super.setUp()
        
        testContainer = CoreDataStack.createInMemoryContainer()
        calculationRepository = CoreDataCalculationRepository(container: testContainer)
        projectRepository = CoreDataProjectRepository(container: testContainer)
        csvImportService = CSVImportService()
        pdfExportService = PDFExportService()
        csvExcelExportService = CSVExcelExportService()
    }
    
    override func tearDown() {
        testContainer = nil
        calculationRepository = nil
        projectRepository = nil
        csvImportService = nil
        pdfExportService = nil
        csvExcelExportService = nil
        super.tearDown()
    }
    
    func testCompleteCalculationWorkflow() async throws {
        // Given: Create a project
        let project = try Project(
            name: "Integration Test Project",
            description: "Testing complete workflow",
            color: "#007AFF"
        )
        try await projectRepository.saveProject(project)
        
        // When: Create and save a calculation
        let calculation = try SavedCalculation(
            name: "Integration Test Calculation",
            calculationType: .calculateIRR,
            projectId: project.id,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24,
            calculatedResult: 22.47,
            notes: "Complete workflow test",
            tags: ["integration", "test", "workflow"]
        )
        
        try await calculationRepository.saveCalculation(calculation)
        
        // Then: Load calculation back
        let loadedCalculation = try await calculationRepository.loadCalculation(id: calculation.id)
        XCTAssertNotNil(loadedCalculation)
        XCTAssertEqual(calculation.name, loadedCalculation?.name)
        XCTAssertEqual(calculation.calculationType, loadedCalculation?.calculationType)
        XCTAssertEqual(calculation.projectId, loadedCalculation?.projectId)
        XCTAssertEqual(calculation.initialInvestment, loadedCalculation?.initialInvestment)
        XCTAssertEqual(calculation.calculatedResult, loadedCalculation?.calculatedResult)
        
        // Verify tags
        XCTAssertEqual(3, loadedCalculation?.tags.count)
        XCTAssertTrue(loadedCalculation?.tags.contains("integration") ?? false)
        XCTAssertTrue(loadedCalculation?.tags.contains("test") ?? false)
        XCTAssertTrue(loadedCalculation?.tags.contains("workflow") ?? false)
        
        // When: Export to PDF
        let pdfResult = await pdfExportService.exportCalculationToPDF(loadedCalculation!)
        
        // Then: PDF should be created successfully
        switch pdfResult {
        case .success(let pdfURL):
            XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path))
            XCTAssertTrue(pdfURL.pathExtension == "pdf")
            XCTAssertTrue(pdfURL.lastPathComponent.contains("Integration_Test_Calculation"))
            
            // Verify file has content
            let fileSize = try FileManager.default.attributesOfItem(atPath: pdfURL.path)[.size] as? Int64
            XCTAssertNotNil(fileSize)
            XCTAssertGreaterThan(fileSize!, 0)
            
            // Cleanup
            try? FileManager.default.removeItem(at: pdfURL)
            
        case .failure(let error):
            XCTFail("PDF export should succeed: \(error)")
        }
    }
    
    func testImportExportRoundTrip() async throws {
        // Given: Create multiple calculations with different types
        let calculations = [
            try SavedCalculation(
                name: "IRR Calculation",
                calculationType: .calculateIRR,
                initialInvestment: 100000,
                outcomeAmount: 150000,
                timeInMonths: 24,
                calculatedResult: 22.47,
                notes: "IRR test calculation"
            ),
            try SavedCalculation(
                name: "Outcome Calculation",
                calculationType: .calculateOutcome,
                initialInvestment: 50000,
                irr: 15,
                timeInMonths: 12,
                calculatedResult: 57500,
                notes: "Outcome test calculation"
            ),
            try SavedCalculation(
                name: "Portfolio Investment",
                calculationType: .portfolioUnitInvestment,
                initialInvestment: 200000,
                timeInMonths: 36,
                unitPrice: 1000,
                successRate: 75,
                outcomePerUnit: 2500,
                investorShare: 80,
                calculatedResult: 18.5,
                notes: "Portfolio test calculation"
            )
        ]
        
        // Save all calculations
        for calculation in calculations {
            try await calculationRepository.saveCalculation(calculation)
        }
        
        // When: Export to CSV
        let exportResult = await csvExcelExportService.exportCalculationsToCSV(calculations)
        
        // Then: CSV should contain all calculations
        switch exportResult {
        case .success(let csvURL):
            let csvContent = try String(contentsOf: csvURL)
            XCTAssertTrue(csvContent.contains("IRR Calculation"))
            XCTAssertTrue(csvContent.contains("Outcome Calculation"))
            XCTAssertTrue(csvContent.contains("Portfolio Investment"))
            XCTAssertTrue(csvContent.contains("calculateIRR"))
            XCTAssertTrue(csvContent.contains("calculateOutcome"))
            XCTAssertTrue(csvContent.contains("portfolioUnitInvestment"))
            
            // When: Clear database and import back
            try clearAllCalculations()
            let importResult = await csvImportService.importFromFile(url: csvURL)
            
            // Then: Import should succeed
            switch importResult {
            case .success(let importData):
                XCTAssertEqual(3, importData.calculations.count)
                XCTAssertTrue(importData.validationErrors.isEmpty)
                
                // Verify imported calculations
                let importedCalcs = importData.calculations.sorted { $0.name < $1.name }
                
                let irrCalc = importedCalcs.first { $0.name == "IRR Calculation" }
                XCTAssertNotNil(irrCalc)
                XCTAssertEqual(.calculateIRR, irrCalc?.calculationType)
                XCTAssertEqual(100000, irrCalc?.initialInvestment)
                XCTAssertEqual(150000, irrCalc?.outcomeAmount)
                XCTAssertEqual(24, irrCalc?.timeInMonths)
                XCTAssertEqual(22.47, irrCalc?.calculatedResult)
                
                let outcomeCalc = importedCalcs.first { $0.name == "Outcome Calculation" }
                XCTAssertNotNil(outcomeCalc)
                XCTAssertEqual(.calculateOutcome, outcomeCalc?.calculationType)
                XCTAssertEqual(50000, outcomeCalc?.initialInvestment)
                XCTAssertEqual(15, outcomeCalc?.irr)
                XCTAssertEqual(12, outcomeCalc?.timeInMonths)
                XCTAssertEqual(57500, outcomeCalc?.calculatedResult)
                
                let portfolioCalc = importedCalcs.first { $0.name == "Portfolio Investment" }
                XCTAssertNotNil(portfolioCalc)
                XCTAssertEqual(.portfolioUnitInvestment, portfolioCalc?.calculationType)
                XCTAssertEqual(200000, portfolioCalc?.initialInvestment)
                XCTAssertEqual(1000, portfolioCalc?.unitPrice)
                XCTAssertEqual(75, portfolioCalc?.successRate)
                XCTAssertEqual(2500, portfolioCalc?.outcomePerUnit)
                XCTAssertEqual(80, portfolioCalc?.investorShare)
                XCTAssertEqual(36, portfolioCalc?.timeInMonths)
                XCTAssertEqual(18.5, portfolioCalc?.calculatedResult)
                
            case .failure(let error):
                XCTFail("Import should succeed: \(error)")
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: csvURL)
            
        case .failure(let error):
            XCTFail("Export should succeed: \(error)")
        }
    }
    
    func testProjectCalculationRelationshipWorkflow() async throws {
        // Given: Create multiple projects
        let project1 = try Project(
            name: "Real Estate",
            description: "Real estate investments",
            color: "#34C759"
        )
        let project2 = try Project(
            name: "Stocks",
            description: "Stock market investments",
            color: "#FF9500"
        )
        
        try await projectRepository.saveProject(project1)
        try await projectRepository.saveProject(project2)
        
        // When: Create calculations for each project
        let realEstateCalcs = [
            try SavedCalculation(
                name: "Property A",
                calculationType: .calculateIRR,
                projectId: project1.id,
                initialInvestment: 500000,
                outcomeAmount: 750000,
                timeInMonths: 60,
                calculatedResult: 8.45
            ),
            try SavedCalculation(
                name: "Property B",
                calculationType: .calculateIRR,
                projectId: project1.id,
                initialInvestment: 300000,
                outcomeAmount: 420000,
                timeInMonths: 36,
                calculatedResult: 11.23
            )
        ]
        
        let stockCalcs = [
            try SavedCalculation(
                name: "Tech Stock Portfolio",
                calculationType: .calculateOutcome,
                projectId: project2.id,
                initialInvestment: 100000,
                irr: 12,
                timeInMonths: 24,
                calculatedResult: 125440
            )
        ]
        
        // Save all calculations
        for calc in realEstateCalcs + stockCalcs {
            try await calculationRepository.saveCalculation(calc)
        }
        
        // Then: Load calculations by project
        let realEstateResults = try await calculationRepository.loadCalculationsByProject(projectId: project1.id)
        XCTAssertEqual(2, realEstateResults.count)
        XCTAssertTrue(realEstateResults.allSatisfy { $0.projectId == project1.id })
        XCTAssertTrue(realEstateResults.contains { $0.name == "Property A" })
        XCTAssertTrue(realEstateResults.contains { $0.name == "Property B" })
        
        let stockResults = try await calculationRepository.loadCalculationsByProject(projectId: project2.id)
        XCTAssertEqual(1, stockResults.count)
        XCTAssertEqual(project2.id, stockResults[0].projectId)
        XCTAssertEqual("Tech Stock Portfolio", stockResults[0].name)
        
        // When: Calculate project statistics
        let allCalculations = try await calculationRepository.loadCalculations()
        let realEstateStats = project1.calculateStatistics(from: allCalculations)
        let stockStats = project2.calculateStatistics(from: allCalculations)
        
        // Then: Statistics should be correct
        XCTAssertEqual(2, realEstateStats.totalCalculations)
        XCTAssertEqual(2, realEstateStats.completedCalculations)
        XCTAssertEqual(1.0, realEstateStats.completionRate)
        XCTAssertEqual(2, realEstateStats.calculationTypes[.calculateIRR])
        
        XCTAssertEqual(1, stockStats.totalCalculations)
        XCTAssertEqual(1, stockStats.completedCalculations)
        XCTAssertEqual(1.0, stockStats.completionRate)
        XCTAssertEqual(1, stockStats.calculationTypes[.calculateOutcome])
        
        // When: Export project calculations separately
        let realEstateExport = await csvExcelExportService.exportCalculationsToCSV(realEstateResults)
        let stockExport = await csvExcelExportService.exportCalculationsToCSV(stockResults)
        
        // Then: Both exports should succeed
        switch (realEstateExport, stockExport) {
        case (.success(let realEstateCsv), .success(let stockCsv)):
            let realEstateContent = try String(contentsOf: realEstateCsv)
            XCTAssertTrue(realEstateContent.contains("Property A"))
            XCTAssertTrue(realEstateContent.contains("Property B"))
            XCTAssertFalse(realEstateContent.contains("Tech Stock Portfolio"))
            
            let stockContent = try String(contentsOf: stockCsv)
            XCTAssertTrue(stockContent.contains("Tech Stock Portfolio"))
            XCTAssertFalse(stockContent.contains("Property A"))
            XCTAssertFalse(stockContent.contains("Property B"))
            
            // Cleanup
            try? FileManager.default.removeItem(at: realEstateCsv)
            try? FileManager.default.removeItem(at: stockCsv)
            
        default:
            XCTFail("Both exports should succeed")
        }
    }
    
    func testErrorHandlingAndRecoveryWorkflow() async throws {
        // Given: CSV with mixed valid and invalid data
        let csvContent = """
        Name,Type,Initial Investment,Outcome Amount,Time (Months),IRR,Notes
        "Valid Calculation","calculateIRR",100000,150000,24,,"Valid calculation"
        "","calculateIRR",100000,150000,24,,"Empty name - invalid"
        "Invalid Type","invalidType",100000,150000,24,,"Invalid calculation type"
        "Negative Investment","calculateIRR",-1000,150000,24,,"Negative investment - invalid"
        "Missing Fields","calculateOutcome",100000,,,,"Missing required fields"
        "Another Valid","calculateOutcome",50000,,12,15,"Another valid calculation"
        """
        
        let csvURL = createTempFile(with: csvContent, extension: "csv")
        
        // When: Import CSV with errors
        let importResult = await csvImportService.importFromFile(url: csvURL)
        
        // Then: Import should succeed but with validation errors
        switch importResult {
        case .success(let importData):
            // Should have some valid calculations
            XCTAssertFalse(importData.calculations.isEmpty)
            let validCalculations = importData.calculations.filter { $0.isComplete }
            XCTAssertEqual(2, validCalculations.count) // "Valid Calculation" and "Another Valid"
            
            // Should have validation errors for invalid rows
            XCTAssertFalse(importData.validationErrors.isEmpty)
            XCTAssertTrue(importData.validationErrors.contains { $0.contains("empty") || $0.contains("Empty name") })
            XCTAssertTrue(importData.validationErrors.contains { $0.contains("invalidType") })
            XCTAssertTrue(importData.validationErrors.contains { $0.contains("positive") || $0.contains("negative") })
            XCTAssertTrue(importData.validationErrors.contains { $0.contains("Missing required fields") })
            
            // When: Save only valid calculations
            for calculation in validCalculations {
                try await calculationRepository.saveCalculation(calculation)
            }
            
            // Then: Valid calculations should be saved successfully
            let savedCalculations = try await calculationRepository.loadCalculations()
            XCTAssertEqual(2, savedCalculations.count)
            XCTAssertTrue(savedCalculations.contains { $0.name == "Valid Calculation" })
            XCTAssertTrue(savedCalculations.contains { $0.name == "Another Valid" })
            
            // When: Export saved calculations
            let exportResult = await csvExcelExportService.exportCalculationsToCSV(savedCalculations)
            
            switch exportResult {
            case .success(let exportedURL):
                // Then: Export should contain only valid data
                let exportedContent = try String(contentsOf: exportedURL)
                XCTAssertTrue(exportedContent.contains("Valid Calculation"))
                XCTAssertTrue(exportedContent.contains("Another Valid"))
                XCTAssertFalse(exportedContent.contains("invalidType"))
                XCTAssertFalse(exportedContent.contains("-1000"))
                
                // Cleanup
                try? FileManager.default.removeItem(at: exportedURL)
                
            case .failure(let error):
                XCTFail("Export should succeed: \(error)")
            }
            
        case .failure(let error):
            XCTFail("Import should succeed but with validation errors: \(error)")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: csvURL)
    }
    
    func testFollowOnInvestmentWorkflow() async throws {
        // Given: Create calculation with follow-on investments
        let followOn1 = FollowOnInvestment(
            timingType: .relativeTime,
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
        
        let followOn2 = FollowOnInvestment(
            timingType: .absoluteDate,
            date: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
            relativeAmount: "24",
            relativeUnit: .months,
            investmentType: .buy,
            amount: "75000",
            valuationMode: .custom,
            valuationType: .specified,
            valuation: "200000",
            irr: "0",
            initialInvestmentDate: Date()
        )
        
        let calculation = try SavedCalculation(
            name: "Blended IRR with Follow-ons",
            calculationType: .calculateBlendedIRR,
            initialInvestment: 100000,
            outcomeAmount: 300000,
            timeInMonths: 36,
            followOnInvestments: [followOn1, followOn2],
            calculatedResult: 25.8,
            notes: "Calculation with follow-on investments"
        )
        
        // When: Save calculation
        try await calculationRepository.saveCalculation(calculation)
        
        // Then: Load calculation with follow-on investments
        let loadedCalculation = try await calculationRepository.loadCalculation(id: calculation.id)
        XCTAssertNotNil(loadedCalculation)
        XCTAssertEqual(2, loadedCalculation?.followOnInvestments?.count)
        
        let loadedFollowOns = loadedCalculation?.followOnInvestments ?? []
        
        let firstFollowOn = loadedFollowOns.first { $0.amount == "50000" }
        XCTAssertNotNil(firstFollowOn)
        XCTAssertEqual(.relativeTime, firstFollowOn?.timingType)
        XCTAssertEqual("12", firstFollowOn?.relativeAmount)
        XCTAssertEqual(.months, firstFollowOn?.relativeUnit)
        XCTAssertEqual(.buy, firstFollowOn?.investmentType)
        XCTAssertEqual(.tagAlong, firstFollowOn?.valuationMode)
        XCTAssertEqual("15.0", firstFollowOn?.irr)
        
        let secondFollowOn = loadedFollowOns.first { $0.amount == "75000" }
        XCTAssertNotNil(secondFollowOn)
        XCTAssertEqual(.absoluteDate, secondFollowOn?.timingType)
        XCTAssertEqual(.buy, secondFollowOn?.investmentType)
        XCTAssertEqual(.custom, secondFollowOn?.valuationMode)
        XCTAssertEqual(.specified, secondFollowOn?.valuationType)
        XCTAssertEqual("200000", secondFollowOn?.valuation)
        
        // When: Export calculation (follow-on investments should be included)
        let exportResult = await csvExcelExportService.exportCalculationsToCSV([loadedCalculation!])
        
        switch exportResult {
        case .success(let csvURL):
            // Then: CSV should contain calculation data
            let csvContent = try String(contentsOf: csvURL)
            XCTAssertTrue(csvContent.contains("Blended IRR with Follow-ons"))
            XCTAssertTrue(csvContent.contains("calculateBlendedIRR"))
            XCTAssertTrue(csvContent.contains("100000"))
            XCTAssertTrue(csvContent.contains("300000"))
            XCTAssertTrue(csvContent.contains("25.8"))
            
            // Cleanup
            try? FileManager.default.removeItem(at: csvURL)
            
        case .failure(let error):
            XCTFail("Export should succeed: \(error)")
        }
    }
    
    func testSearchAndFilterWorkflow() async throws {
        // Given: Create calculations with various attributes
        let calculations = [
            try SavedCalculation(
                name: "Real Estate Investment A",
                calculationType: .calculateIRR,
                initialInvestment: 500000,
                outcomeAmount: 750000,
                timeInMonths: 60,
                notes: "Commercial real estate property",
                tags: ["real-estate", "commercial", "long-term"]
            ),
            
            try SavedCalculation(
                name: "Stock Portfolio Analysis",
                calculationType: .calculateOutcome,
                initialInvestment: 100000,
                irr: 12,
                timeInMonths: 24,
                notes: "Diversified stock portfolio",
                tags: ["stocks", "portfolio", "medium-term"]
            ),
            
            try SavedCalculation(
                name: "Real Estate Investment B",
                calculationType: .calculateIRR,
                initialInvestment: 300000,
                outcomeAmount: 420000,
                timeInMonths: 36,
                notes: "Residential real estate flip",
                tags: ["real-estate", "residential", "short-term"]
            ),
            
            try SavedCalculation(
                name: "Bond Investment",
                calculationType: .calculateInitial,
                outcomeAmount: 120000,
                irr: 8,
                timeInMonths: 120,
                notes: "Government bond investment",
                tags: ["bonds", "government", "long-term"]
            )
        ]
        
        // Save all calculations
        for calculation in calculations {
            try await calculationRepository.saveCalculation(calculation)
        }
        
        // When: Search by name
        let realEstateResults = try await calculationRepository.searchCalculations(query: "Real Estate")
        
        // Then: Should find real estate calculations
        XCTAssertEqual(2, realEstateResults.count)
        XCTAssertTrue(realEstateResults.allSatisfy { $0.name.contains("Real Estate") })
        
        // When: Search by notes
        let portfolioResults = try await calculationRepository.searchCalculations(query: "portfolio")
        
        // Then: Should find portfolio-related calculations
        XCTAssertEqual(2, portfolioResults.count) // Stock portfolio and diversified portfolio
        XCTAssertTrue(portfolioResults.contains { $0.name.contains("Stock Portfolio") })
        XCTAssertTrue(portfolioResults.contains { $0.notes?.contains("portfolio") == true })
        
        // When: Filter by calculation type
        let allCalculations = try await calculationRepository.loadCalculations()
        let irrCalculations = allCalculations.filter { $0.calculationType == .calculateIRR }
        let outcomeCalculations = allCalculations.filter { $0.calculationType == .calculateOutcome }
        let initialCalculations = allCalculations.filter { $0.calculationType == .calculateInitial }
        
        // Then: Should have correct counts by type
        XCTAssertEqual(2, irrCalculations.count)
        XCTAssertEqual(1, outcomeCalculations.count)
        XCTAssertEqual(1, initialCalculations.count)
        
        // When: Filter by investment amount range
        let largeInvestments = allCalculations.filter { 
            ($0.initialInvestment ?? 0) >= 300000
        }
        let smallInvestments = allCalculations.filter { 
            ($0.initialInvestment ?? 0) < 300000 && ($0.initialInvestment ?? 0) > 0
        }
        
        // Then: Should have correct counts by investment size
        XCTAssertEqual(2, largeInvestments.count) // Real Estate A and B
        XCTAssertEqual(1, smallInvestments.count) // Stock Portfolio
        
        // When: Export filtered results
        let largeInvestmentExport = await csvExcelExportService.exportCalculationsToCSV(largeInvestments)
        
        switch largeInvestmentExport {
        case .success(let exportURL):
            // Then: Export should contain only large investments
            let exportContent = try String(contentsOf: exportURL)
            XCTAssertTrue(exportContent.contains("Real Estate Investment A"))
            XCTAssertTrue(exportContent.contains("Real Estate Investment B"))
            XCTAssertFalse(exportContent.contains("Stock Portfolio Analysis"))
            XCTAssertFalse(exportContent.contains("Bond Investment"))
            
            // Cleanup
            try? FileManager.default.removeItem(at: exportURL)
            
        case .failure(let error):
            XCTFail("Export should succeed: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTempFile(with content: String, extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Failed to create temp file: \(error)")
        }
        
        return tempURL
    }
    
    private func clearAllCalculations() throws {
        let context = testContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SavedCalculationEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        try context.save()
    }
}