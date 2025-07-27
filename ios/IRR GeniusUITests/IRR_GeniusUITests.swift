//
//  IRR_GeniusUITests.swift
//  IRR GeniusUITests
//

import XCTest

final class IRR_GeniusUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testTabNavigationFlow() throws {
        // Given: App is launched
        XCTAssertTrue(app.tabBars.firstMatch.exists)
        
        // Calculator tab should be selected by default
        let calculatorTab = app.tabBars.buttons["Calculator"]
        XCTAssertTrue(calculatorTab.exists)
        XCTAssertTrue(calculatorTab.isSelected)
        
        // When: Navigate to Saved tab
        let savedTab = app.tabBars.buttons["Saved"]
        savedTab.tap()
        
        // Then: Saved screen should be displayed
        XCTAssertTrue(app.navigationBars["Saved Calculations"].exists)
        XCTAssertTrue(savedTab.isSelected)
        
        // When: Navigate to Projects tab
        let projectsTab = app.tabBars.buttons["Projects"]
        projectsTab.tap()
        
        // Then: Projects screen should be displayed
        XCTAssertTrue(app.navigationBars["Projects"].exists)
        XCTAssertTrue(projectsTab.isSelected)
        
        // When: Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        
        // Then: Settings screen should be displayed
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(settingsTab.isSelected)
        
        // When: Navigate back to Calculator
        calculatorTab.tap()
        
        // Then: Calculator screen should be displayed
        XCTAssertTrue(app.navigationBars["IRR Calculator"].exists)
        XCTAssertTrue(calculatorTab.isSelected)
    }
    
    func testCalculationModeSelection() throws {
        // Given: Calculator screen is displayed
        XCTAssertTrue(app.navigationBars["IRR Calculator"].exists)
        
        // When: Check default mode (Calculate IRR)
        let modeSelector = app.segmentedControls["CalculationModeSelector"]
        XCTAssertTrue(modeSelector.exists)
        XCTAssertTrue(modeSelector.buttons["Calculate IRR"].isSelected)
        
        // Verify IRR mode fields
        XCTAssertTrue(app.textFields["Initial Investment"].exists)
        XCTAssertTrue(app.textFields["Outcome Amount"].exists)
        XCTAssertTrue(app.textFields["Time (Months)"].exists)
        
        // When: Switch to Calculate Outcome mode
        modeSelector.buttons["Calculate Outcome"].tap()
        
        // Then: Outcome mode fields should be displayed
        XCTAssertTrue(app.textFields["Initial Investment"].exists)
        XCTAssertTrue(app.textFields["IRR (%)"].exists)
        XCTAssertTrue(app.textFields["Time (Months)"].exists)
        XCTAssertFalse(app.textFields["Outcome Amount"].exists)
        
        // When: Switch to Portfolio Unit Investment mode
        modeSelector.buttons["Portfolio Unit Investment"].tap()
        
        // Then: Portfolio mode fields should be displayed
        XCTAssertTrue(app.textFields["Investment Amount"].exists)
        XCTAssertTrue(app.textFields["Unit Price"].exists)
        XCTAssertTrue(app.textFields["Success Rate (%)"].exists)
        XCTAssertTrue(app.textFields["Outcome Per Unit"].exists)
        XCTAssertTrue(app.textFields["Investor Share (%)"].exists)
    }
    
    func testCalculationInputValidation() throws {
        // Given: Calculator screen with IRR mode
        XCTAssertTrue(app.segmentedControls["CalculationModeSelector"].buttons["Calculate IRR"].isSelected)
        
        // When: Enter invalid inputs
        let initialInvestmentField = app.textFields["Initial Investment"]
        initialInvestmentField.tap()
        initialInvestmentField.typeText("-1000")
        
        let outcomeAmountField = app.textFields["Outcome Amount"]
        outcomeAmountField.tap()
        outcomeAmountField.typeText("150000")
        
        let timeField = app.textFields["Time (Months)"]
        timeField.tap()
        timeField.typeText("24")
        
        // Try to calculate
        app.buttons["Calculate"].tap()
        
        // Then: Should show validation error
        XCTAssertTrue(app.alerts["Validation Error"].exists)
        XCTAssertTrue(app.staticTexts["Initial investment must be positive"].exists)
        
        // Dismiss alert
        app.alerts["Validation Error"].buttons["OK"].tap()
        
        // When: Fix the input
        initialInvestmentField.tap()
        initialInvestmentField.clearText()
        initialInvestmentField.typeText("100000")
        
        // Try to calculate again
        app.buttons["Calculate"].tap()
        
        // Then: Should show result
        XCTAssertTrue(app.staticTexts["IRR Result"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '22.47%'")).firstMatch.exists)
    }
    
    func testSaveCalculationFlow() throws {
        // Given: A completed calculation
        performBasicIRRCalculation()
        
        // When: Save the calculation
        app.buttons["Save Calculation"].tap()
        
        // Then: Save dialog should appear
        XCTAssertTrue(app.alerts["Save Calculation"].exists)
        
        let nameField = app.alerts["Save Calculation"].textFields["Calculation Name"]
        XCTAssertTrue(nameField.exists)
        
        // Enter calculation name
        nameField.tap()
        nameField.typeText("Test Calculation")
        
        // Save
        app.alerts["Save Calculation"].buttons["Save"].tap()
        
        // Then: Should show success message
        XCTAssertTrue(app.alerts["Success"].exists)
        XCTAssertTrue(app.staticTexts["Calculation saved successfully"].exists)
        
        app.alerts["Success"].buttons["OK"].tap()
    }
    
    func testLoadCalculationFlow() throws {
        // Given: Navigate to Saved tab
        app.tabBars.buttons["Saved"].tap()
        
        // When: Select a saved calculation (assuming one exists from previous test)
        let calculationCell = app.cells.containing(.staticText, identifier: "Test Calculation").firstMatch
        if calculationCell.exists {
            calculationCell.tap()
            
            // Then: Should navigate to calculator with loaded data
            XCTAssertTrue(app.navigationBars["IRR Calculator"].exists)
            XCTAssertEqual(app.textFields["Initial Investment"].value as? String, "100000")
            XCTAssertEqual(app.textFields["Outcome Amount"].value as? String, "150000")
            XCTAssertEqual(app.textFields["Time (Months)"].value as? String, "24")
        }
    }
    
    func testSearchFunctionality() throws {
        // Given: Navigate to Saved tab
        app.tabBars.buttons["Saved"].tap()
        
        // When: Use search functionality
        let searchField = app.searchFields["Search calculations..."]
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Test")
            
            // Then: Should filter results
            XCTAssertTrue(app.cells.containing(.staticText, identifier: "Test Calculation").firstMatch.exists)
            
            // When: Clear search
            searchField.buttons["Clear text"].tap()
            
            // Then: Should show all calculations
            let calculationCells = app.cells.matching(identifier: "CalculationCell")
            XCTAssertGreaterThanOrEqual(calculationCells.count, 1)
        }
    }
    
    func testProjectManagementFlow() throws {
        // Given: Navigate to Projects tab
        app.tabBars.buttons["Projects"].tap()
        
        // When: Create new project
        app.navigationBars["Projects"].buttons["Add"].tap()
        
        // Then: Project creation sheet should appear
        XCTAssertTrue(app.navigationBars["Create Project"].exists)
        
        // Enter project details
        let nameField = app.textFields["Project Name"]
        nameField.tap()
        nameField.typeText("Test Project")
        
        let descriptionField = app.textViews["Description"]
        descriptionField.tap()
        descriptionField.typeText("Test project description")
        
        // Select color
        app.buttons["Project Color"].tap()
        app.buttons["Blue Color"].tap()
        
        // Create project
        app.navigationBars["Create Project"].buttons["Save"].tap()
        
        // Then: Should show project in list
        XCTAssertTrue(app.cells.containing(.staticText, identifier: "Test Project").firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Test project description"].exists)
    }
    
    func testImportDataFlow() throws {
        // Given: Navigate to Settings tab
        app.tabBars.buttons["Settings"].tap()
        
        // When: Select import data option
        app.cells["Import Data"].tap()
        
        // Then: Import screen should appear
        XCTAssertTrue(app.navigationBars["Import Data"].exists)
        
        // When: Select file type
        app.segmentedControls["FileTypeSelector"].buttons["CSV"].tap()
        app.buttons["Select File"].tap()
        
        // Then: File picker should open (simulated)
        // Note: Actual file picker testing would require additional setup
        if app.alerts["File Selected"].exists {
            app.alerts["File Selected"].buttons["OK"].tap()
            
            // When: Preview import
            app.buttons["Preview"].tap()
            
            // Then: Should show import preview
            XCTAssertTrue(app.navigationBars["Import Preview"].exists)
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'calculations found'")).firstMatch.exists)
            
            // When: Confirm import
            app.buttons["Import"].tap()
            
            // Then: Should show success message
            XCTAssertTrue(app.alerts["Import Complete"].exists)
            app.alerts["Import Complete"].buttons["OK"].tap()
        }
    }
    
    func testExportDataFlow() throws {
        // Given: Navigate to Saved tab with calculations
        app.tabBars.buttons["Saved"].tap()
        
        // When: Select export option
        app.navigationBars["Saved Calculations"].buttons["More"].tap()
        app.buttons["Export All"].tap()
        
        // Then: Export options should appear
        XCTAssertTrue(app.actionSheets["Export Options"].exists)
        
        // When: Select PDF export
        app.actionSheets["Export Options"].buttons["PDF"].tap()
        
        // Then: Should show export progress
        XCTAssertTrue(app.staticTexts["Generating PDF..."].exists)
        
        // When: Export completes
        let exportCompleteAlert = app.alerts["Export Complete"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: exportCompleteAlert, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        // Then: Should show share options
        XCTAssertTrue(app.buttons["Share"].exists)
        XCTAssertTrue(app.buttons["Save to Files"].exists)
        
        exportCompleteAlert.buttons["OK"].tap()
    }
    
    func testErrorStateHandling() throws {
        // Given: Settings screen
        app.tabBars.buttons["Settings"].tap()
        
        // When: Try to enable cloud sync (simulated error)
        app.cells["Cloud Sync"].tap()
        app.switches["Enable Sync"].tap()
        
        // Then: Should show error state
        if app.alerts["Sync Error"].exists {
            XCTAssertTrue(app.staticTexts["Unable to connect to cloud service"].exists)
            
            // When: Retry action
            app.alerts["Sync Error"].buttons["Retry"].tap()
            
            // Then: Should show loading state
            XCTAssertTrue(app.staticTexts["Connecting..."].exists)
            
            // When: Error persists
            let errorAlert = app.alerts["Sync Error"]
            let exists = NSPredicate(format: "exists == true")
            expectation(for: exists, evaluatedWith: errorAlert, handler: nil)
            waitForExpectations(timeout: 5, handler: nil)
            
            // Then: Should show error recovery options
            XCTAssertTrue(app.buttons["Work Offline"].exists)
            XCTAssertTrue(app.buttons["Check Settings"].exists)
            
            errorAlert.buttons["Work Offline"].tap()
        }
    }
    
    func testFollowOnInvestmentFlow() throws {
        // Given: Calculator in Blended IRR mode
        let modeSelector = app.segmentedControls["CalculationModeSelector"]
        modeSelector.buttons["Calculate Blended IRR"].tap()
        
        // Enter initial values
        app.textFields["Initial Investment"].tap()
        app.textFields["Initial Investment"].typeText("100000")
        
        app.textFields["Outcome Amount"].tap()
        app.textFields["Outcome Amount"].typeText("300000")
        
        app.textFields["Time (Months)"].tap()
        app.textFields["Time (Months)"].typeText("36")
        
        // When: Add follow-on investment
        app.buttons["Add Follow-on Investment"].tap()
        
        // Then: Follow-on investment sheet should appear
        XCTAssertTrue(app.navigationBars["Add Follow-on Investment"].exists)
        
        // Enter follow-on details
        app.textFields["Investment Amount"].tap()
        app.textFields["Investment Amount"].typeText("50000")
        
        app.buttons["Timing"].tap()
        app.buttons["12 months from initial"].tap()
        
        app.buttons["Valuation Mode"].tap()
        app.buttons["Tag Along"].tap()
        
        // Add the investment
        app.navigationBars["Add Follow-on Investment"].buttons["Add"].tap()
        
        // Then: Should show in follow-on investments list
        XCTAssertTrue(app.staticTexts["$50,000 at 12 months"].exists)
        
        // When: Calculate with follow-on investments
        app.buttons["Calculate"].tap()
        
        // Then: Should show blended IRR result
        XCTAssertTrue(app.staticTexts["Blended IRR Result"].exists)
    }
    
    func testAccessibilityFeatures() throws {
        // Given: Calculator screen
        XCTAssertTrue(app.navigationBars["IRR Calculator"].exists)
        
        // Test accessibility labels
        XCTAssertTrue(app.textFields["Initial Investment"].exists)
        XCTAssertEqual(app.textFields["Initial Investment"].label, "Initial Investment")
        
        XCTAssertTrue(app.textFields["Outcome Amount"].exists)
        XCTAssertEqual(app.textFields["Outcome Amount"].label, "Outcome Amount")
        
        XCTAssertTrue(app.buttons["Calculate"].exists)
        XCTAssertEqual(app.buttons["Calculate"].label, "Calculate")
        
        // Test VoiceOver navigation
        if UIAccessibility.isVoiceOverRunning {
            // Test focus navigation
            app.textFields["Initial Investment"].tap()
            XCTAssertTrue(app.textFields["Initial Investment"].hasFocus)
            
            // Test accessibility announcements
            app.buttons["Calculate"].tap()
            // VoiceOver would announce the result
        }
        
        // Test Dynamic Type support
        // Note: This would require additional setup for font size testing
        
        // Test high contrast mode support
        app.tabBars.buttons["Settings"].tap()
        if app.cells["Accessibility"].exists {
            app.cells["Accessibility"].tap()
            
            if app.switches["Increase Contrast"].exists {
                app.switches["Increase Contrast"].tap()
                
                // Navigate back to calculator to verify contrast changes
                app.tabBars.buttons["Calculator"].tap()
                // Visual verification would be done through screenshot testing
            }
        }
    }
    
    func testPortfolioUnitInvestmentFlow() throws {
        // Given: Calculator in Portfolio Unit Investment mode
        let modeSelector = app.segmentedControls["CalculationModeSelector"]
        modeSelector.buttons["Portfolio Unit Investment"].tap()
        
        // When: Enter portfolio investment details
        app.textFields["Investment Amount"].tap()
        app.textFields["Investment Amount"].typeText("100000")
        
        app.textFields["Unit Price"].tap()
        app.textFields["Unit Price"].typeText("1000")
        
        app.textFields["Success Rate (%)"].tap()
        app.textFields["Success Rate (%)"].typeText("75")
        
        app.textFields["Outcome Per Unit"].tap()
        app.textFields["Outcome Per Unit"].typeText("2500")
        
        app.textFields["Investor Share (%)"].tap()
        app.textFields["Investor Share (%)"].typeText("80")
        
        app.textFields["Time (Months)"].tap()
        app.textFields["Time (Months)"].typeText("36")
        
        // When: Calculate
        app.buttons["Calculate"].tap()
        
        // Then: Should show portfolio IRR result
        XCTAssertTrue(app.staticTexts["Portfolio IRR Result"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch.exists)
        
        // When: Add follow-on batch
        app.buttons["Add Follow-on Batch"].tap()
        
        // Then: Follow-on batch sheet should appear
        XCTAssertTrue(app.navigationBars["Add Follow-on Batch"].exists)
        
        // Enter batch details
        app.textFields["Batch Amount"].tap()
        app.textFields["Batch Amount"].typeText("50000")
        
        app.textFields["Unit Price"].tap()
        app.textFields["Unit Price"].typeText("1200")
        
        app.buttons["Timing"].tap()
        app.buttons["18 months from initial"].tap()
        
        // Add the batch
        app.navigationBars["Add Follow-on Batch"].buttons["Add"].tap()
        
        // Then: Should show in batches list
        XCTAssertTrue(app.staticTexts["$50,000 batch at $1,200/unit"].exists)
        
        // When: Recalculate with batch
        app.buttons["Calculate"].tap()
        
        // Then: Should show updated blended result
        XCTAssertTrue(app.staticTexts["Blended Portfolio IRR"].exists)
    }
    
    // MARK: - Helper Methods
    
    private func performBasicIRRCalculation() {
        let initialInvestmentField = app.textFields["Initial Investment"]
        initialInvestmentField.tap()
        initialInvestmentField.typeText("100000")
        
        let outcomeAmountField = app.textFields["Outcome Amount"]
        outcomeAmountField.tap()
        outcomeAmountField.typeText("150000")
        
        let timeField = app.textFields["Time (Months)"]
        timeField.tap()
        timeField.typeText("24")
        
        app.buttons["Calculate"].tap()
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}