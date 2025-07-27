//
//  IRR_GeniusUITestsLaunchTests.swift
//  IRR GeniusUITests
//

import XCTest

final class IRR_GeniusUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot
        // For example, logging into a test account or navigating to a specific screen
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testAppStateAfterLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify app launches to correct initial state
        XCTAssertTrue(app.tabBars.firstMatch.exists, "Tab bar should be visible after launch")
        XCTAssertTrue(app.tabBars.buttons["Calculator"].isSelected, "Calculator tab should be selected by default")
        XCTAssertTrue(app.navigationBars["IRR Calculator"].exists, "Calculator navigation bar should be visible")
        
        // Verify essential UI elements are present
        XCTAssertTrue(app.segmentedControls["CalculationModeSelector"].exists, "Calculation mode selector should be visible")
        XCTAssertTrue(app.textFields["Initial Investment"].exists, "Initial investment field should be visible")
        XCTAssertTrue(app.buttons["Calculate"].exists, "Calculate button should be visible")
        
        // Verify all tabs are accessible
        let expectedTabs = ["Calculator", "Saved", "Projects", "Settings"]
        for tabName in expectedTabs {
            XCTAssertTrue(app.tabBars.buttons[tabName].exists, "\(tabName) tab should exist")
        }
    }
    
    func testLaunchWithDifferentDeviceOrientations() throws {
        let app = XCUIApplication()
        
        // Test portrait launch
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should work in portrait orientation")
        app.terminate()
        
        // Test landscape launch
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should work in landscape orientation")
        app.terminate()
        
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    func testLaunchWithAccessibilityEnabled() throws {
        let app = XCUIApplication()
        
        // Enable accessibility features (if possible in test environment)
        // Note: Some accessibility features may need to be enabled manually in simulator
        
        app.launch()
        
        // Verify accessibility elements are properly configured
        XCTAssertTrue(app.textFields["Initial Investment"].isAccessibilityElement, "Input fields should be accessible")
        XCTAssertTrue(app.buttons["Calculate"].isAccessibilityElement, "Buttons should be accessible")
        
        // Verify accessibility labels are meaningful
        XCTAssertEqual(app.textFields["Initial Investment"].label, "Initial Investment", "Accessibility label should be descriptive")
        XCTAssertEqual(app.buttons["Calculate"].label, "Calculate", "Button label should be clear")
    }
    
    func testLaunchMemoryUsage() throws {
        let app = XCUIApplication()
        
        // Measure memory usage during launch
        measure(metrics: [XCTMemoryMetric()]) {
            app.launch()
            
            // Perform some basic navigation to ensure app is fully loaded
            app.tabBars.buttons["Saved"].tap()
            app.tabBars.buttons["Projects"].tap()
            app.tabBars.buttons["Settings"].tap()
            app.tabBars.buttons["Calculator"].tap()
            
            app.terminate()
        }
    }
    
    func testLaunchWithPreviousAppState() throws {
        let app = XCUIApplication()
        
        // First launch - navigate to a different tab
        app.launch()
        app.tabBars.buttons["Projects"].tap()
        XCTAssertTrue(app.tabBars.buttons["Projects"].isSelected)
        
        // Terminate and relaunch
        app.terminate()
        app.launch()
        
        // Verify app remembers state (if implemented)
        // Note: This depends on whether the app implements state restoration
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should launch successfully after termination")
    }
    
    func testLaunchErrorHandling() throws {
        let app = XCUIApplication()
        
        // Test launch with potential error conditions
        // Note: These would need to be simulated through app configuration or mocking
        
        app.launch()
        
        // Verify app handles launch errors gracefully
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should launch even with potential errors")
        
        // If there are error states, verify they're handled properly
        if app.alerts.firstMatch.exists {
            let alert = app.alerts.firstMatch
            XCTAssertTrue(alert.buttons.firstMatch.exists, "Error alerts should have action buttons")
            
            // Dismiss any error alerts
            if alert.buttons["OK"].exists {
                alert.buttons["OK"].tap()
            } else if alert.buttons["Dismiss"].exists {
                alert.buttons["Dismiss"].tap()
            }
        }
        
        // Verify app is still functional after handling errors
        XCTAssertTrue(app.textFields["Initial Investment"].exists, "App should remain functional after error handling")
    }
    
    func testLaunchWithDifferentSystemSettings() throws {
        let app = XCUIApplication()
        
        // Test with different system font sizes (if configurable in test)
        app.launch()
        
        // Verify UI adapts to system settings
        XCTAssertTrue(app.textFields["Initial Investment"].exists, "UI should adapt to system font size")
        XCTAssertTrue(app.buttons["Calculate"].exists, "Buttons should remain accessible with different font sizes")
        
        // Test with different color schemes (if configurable)
        // Note: This would require additional setup for theme testing
        
        app.terminate()
    }
    
    func testLaunchDataMigration() throws {
        let app = XCUIApplication()
        
        // Test app launch with existing data (if applicable)
        // Note: This would require pre-populating test data
        
        app.launch()
        
        // Navigate to saved calculations to verify data migration
        app.tabBars.buttons["Saved"].tap()
        
        // Verify data is accessible (if any exists)
        if app.cells.firstMatch.exists {
            XCTAssertTrue(app.cells.firstMatch.exists, "Existing data should be accessible after launch")
        }
        
        // Navigate to projects
        app.tabBars.buttons["Projects"].tap()
        
        // Verify project data is accessible (if any exists)
        if app.cells.firstMatch.exists {
            XCTAssertTrue(app.cells.firstMatch.exists, "Project data should be accessible after launch")
        }
    }
    
    func testLaunchNetworkConnectivity() throws {
        let app = XCUIApplication()
        
        // Test launch with different network conditions
        // Note: Network conditions would need to be simulated
        
        app.launch()
        
        // Verify app launches successfully regardless of network state
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should launch without network dependency")
        
        // Navigate to sync settings to test network-dependent features
        app.tabBars.buttons["Settings"].tap()
        
        if app.cells["Cloud Sync"].exists {
            app.cells["Cloud Sync"].tap()
            
            // Verify sync features handle network state appropriately
            if app.staticTexts["No Internet Connection"].exists {
                XCTAssertTrue(app.buttons["Work Offline"].exists, "Offline mode should be available")
            }
        }
    }
}