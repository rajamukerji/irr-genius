package com.irrgenius.android

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.irrgenius.android.ui.theme.IRRGeniusTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class NavigationUITest {
    
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()
    
    @Test
    fun testTabNavigationFlow() {
        // Given: App is launched
        composeTestRule.setContent {
            IRRGeniusTheme {
                // Main app content would be here
            }
        }
        
        // When: Navigate to different tabs
        // Calculator tab should be selected by default
        composeTestRule.onNodeWithText("Calculator").assertIsDisplayed()
        
        // Navigate to Saved tab
        composeTestRule.onNodeWithText("Saved").performClick()
        composeTestRule.onNodeWithText("Saved Calculations").assertIsDisplayed()
        
        // Navigate to Projects tab
        composeTestRule.onNodeWithText("Projects").performClick()
        composeTestRule.onNodeWithText("Projects").assertIsDisplayed()
        
        // Navigate to Settings tab
        composeTestRule.onNodeWithText("Settings").performClick()
        composeTestRule.onNodeWithText("Settings").assertIsDisplayed()
        
        // Navigate back to Calculator
        composeTestRule.onNodeWithText("Calculator").performClick()
        composeTestRule.onNodeWithText("IRR Calculator").assertIsDisplayed()
    }
    
    @Test
    fun testCalculationModeSelection() {
        // Given: Calculator screen is displayed
        composeTestRule.onNodeWithText("Calculator").assertIsDisplayed()
        
        // When: Select different calculation modes
        composeTestRule.onNodeWithText("Calculate IRR").performClick()
        composeTestRule.onNodeWithText("Initial Investment").assertIsDisplayed()
        composeTestRule.onNodeWithText("Outcome Amount").assertIsDisplayed()
        composeTestRule.onNodeWithText("Time (Months)").assertIsDisplayed()
        
        // Switch to Calculate Outcome mode
        composeTestRule.onNodeWithContentDescription("Calculation Mode Selector").performClick()
        composeTestRule.onNodeWithText("Calculate Outcome").performClick()
        composeTestRule.onNodeWithText("Initial Investment").assertIsDisplayed()
        composeTestRule.onNodeWithText("IRR (%)").assertIsDisplayed()
        composeTestRule.onNodeWithText("Time (Months)").assertIsDisplayed()
        
        // Switch to Portfolio Unit Investment mode
        composeTestRule.onNodeWithContentDescription("Calculation Mode Selector").performClick()
        composeTestRule.onNodeWithText("Portfolio Unit Investment").performClick()
        composeTestRule.onNodeWithText("Investment Amount").assertIsDisplayed()
        composeTestRule.onNodeWithText("Unit Price").assertIsDisplayed()
        composeTestRule.onNodeWithText("Success Rate (%)").assertIsDisplayed()
        composeTestRule.onNodeWithText("Outcome Per Unit").assertIsDisplayed()
    }
    
    @Test
    fun testCalculationInputValidation() {
        // Given: Calculator screen with IRR mode
        composeTestRule.onNodeWithText("Calculate IRR").assertIsDisplayed()
        
        // When: Enter invalid inputs
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("-1000")
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("150000")
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("24")
        
        // Try to calculate
        composeTestRule.onNodeWithText("Calculate").performClick()
        
        // Then: Should show validation error
        composeTestRule.onNodeWithText("Initial investment must be positive").assertIsDisplayed()
        
        // When: Fix the input
        composeTestRule.onNodeWithText("Initial Investment").performTextClearance()
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("100000")
        
        // Try to calculate again
        composeTestRule.onNodeWithText("Calculate").performClick()
        
        // Then: Should show result
        composeTestRule.onNodeWithText("IRR Result").assertIsDisplayed()
    }
    
    @Test
    fun testSaveCalculationFlow() {
        // Given: A completed calculation
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("100000")
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("150000")
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("24")
        composeTestRule.onNodeWithText("Calculate").performClick()
        
        // When: Save the calculation
        composeTestRule.onNodeWithContentDescription("Save Calculation").performClick()
        
        // Then: Save dialog should appear
        composeTestRule.onNodeWithText("Save Calculation").assertIsDisplayed()
        composeTestRule.onNodeWithText("Calculation Name").assertIsDisplayed()
        
        // Enter calculation name
        composeTestRule.onNodeWithText("Calculation Name").performTextInput("Test Calculation")
        
        // Select project (optional)
        composeTestRule.onNodeWithText("Select Project").performClick()
        composeTestRule.onNodeWithText("No Project").performClick()
        
        // Save
        composeTestRule.onNodeWithText("Save").performClick()
        
        // Then: Should show success message
        composeTestRule.onNodeWithText("Calculation saved successfully").assertIsDisplayed()
    }
    
    @Test
    fun testLoadCalculationFlow() {
        // Given: Navigate to Saved tab
        composeTestRule.onNodeWithText("Saved").performClick()
        
        // When: Select a saved calculation (assuming one exists)
        composeTestRule.onNodeWithText("Test Calculation").performClick()
        
        // Then: Should navigate to calculator with loaded data
        composeTestRule.onNodeWithText("Calculator").assertIsDisplayed()
        composeTestRule.onNodeWithText("100000").assertIsDisplayed() // Initial investment
        composeTestRule.onNodeWithText("150000").assertIsDisplayed() // Outcome amount
        composeTestRule.onNodeWithText("24").assertIsDisplayed() // Time in months
    }
    
    @Test
    fun testSearchFunctionality() {
        // Given: Navigate to Saved tab
        composeTestRule.onNodeWithText("Saved").performClick()
        
        // When: Use search functionality
        composeTestRule.onNodeWithContentDescription("Search").performClick()
        composeTestRule.onNodeWithText("Search calculations...").performTextInput("Test")
        
        // Then: Should filter results
        composeTestRule.onNodeWithText("Test Calculation").assertIsDisplayed()
        
        // When: Clear search
        composeTestRule.onNodeWithContentDescription("Clear Search").performClick()
        
        // Then: Should show all calculations
        composeTestRule.onAllNodesWithTag("CalculationItem").assertCountEquals(1) // Assuming 1 calculation exists
    }
    
    @Test
    fun testProjectManagementFlow() {
        // Given: Navigate to Projects tab
        composeTestRule.onNodeWithText("Projects").performClick()
        
        // When: Create new project
        composeTestRule.onNodeWithContentDescription("Add Project").performClick()
        
        // Then: Project creation dialog should appear
        composeTestRule.onNodeWithText("Create Project").assertIsDisplayed()
        composeTestRule.onNodeWithText("Project Name").assertIsDisplayed()
        
        // Enter project details
        composeTestRule.onNodeWithText("Project Name").performTextInput("Test Project")
        composeTestRule.onNodeWithText("Description").performTextInput("Test project description")
        
        // Select color
        composeTestRule.onNodeWithContentDescription("Project Color").performClick()
        composeTestRule.onNodeWithContentDescription("Blue Color").performClick()
        
        // Create project
        composeTestRule.onNodeWithText("Create").performClick()
        
        // Then: Should show project in list
        composeTestRule.onNodeWithText("Test Project").assertIsDisplayed()
        composeTestRule.onNodeWithText("Test project description").assertIsDisplayed()
    }
    
    @Test
    fun testImportDataFlow() {
        // Given: Navigate to Settings tab
        composeTestRule.onNodeWithText("Settings").performClick()
        
        // When: Select import data option
        composeTestRule.onNodeWithText("Import Data").performClick()
        
        // Then: Import screen should appear
        composeTestRule.onNodeWithText("Import Calculations").assertIsDisplayed()
        composeTestRule.onNodeWithText("Select File").assertIsDisplayed()
        
        // When: Select file type
        composeTestRule.onNodeWithText("CSV File").performClick()
        composeTestRule.onNodeWithText("Select CSV File").performClick()
        
        // Then: File picker should open (simulated)
        // Note: Actual file picker testing would require additional setup
        composeTestRule.onNodeWithText("File selected").assertIsDisplayed()
        
        // When: Preview import
        composeTestRule.onNodeWithText("Preview").performClick()
        
        // Then: Should show import preview
        composeTestRule.onNodeWithText("Import Preview").assertIsDisplayed()
        composeTestRule.onNodeWithText("2 calculations found").assertIsDisplayed()
        
        // When: Confirm import
        composeTestRule.onNodeWithText("Import").performClick()
        
        // Then: Should show success message
        composeTestRule.onNodeWithText("Import completed successfully").assertIsDisplayed()
    }
    
    @Test
    fun testExportDataFlow() {
        // Given: Navigate to Saved tab with calculations
        composeTestRule.onNodeWithText("Saved").performClick()
        
        // When: Select calculations for export
        composeTestRule.onNodeWithContentDescription("Select All").performClick()
        composeTestRule.onNodeWithContentDescription("Export Selected").performClick()
        
        // Then: Export options should appear
        composeTestRule.onNodeWithText("Export Options").assertIsDisplayed()
        composeTestRule.onNodeWithText("PDF").assertIsDisplayed()
        composeTestRule.onNodeWithText("CSV").assertIsDisplayed()
        composeTestRule.onNodeWithText("Excel").assertIsDisplayed()
        
        // When: Select PDF export
        composeTestRule.onNodeWithText("PDF").performClick()
        
        // Then: Should show export progress
        composeTestRule.onNodeWithText("Generating PDF...").assertIsDisplayed()
        
        // When: Export completes
        composeTestRule.waitUntil(timeoutMillis = 5000) {
            composeTestRule.onAllNodesWithText("Export completed").fetchSemanticsNodes().isNotEmpty()
        }
        
        // Then: Should show share options
        composeTestRule.onNodeWithText("Share").assertIsDisplayed()
        composeTestRule.onNodeWithText("Save to Files").assertIsDisplayed()
    }
    
    @Test
    fun testErrorStateHandling() {
        // Given: Calculator screen
        composeTestRule.onNodeWithText("Calculator").assertIsDisplayed()
        
        // When: Trigger network error (simulated)
        composeTestRule.onNodeWithText("Settings").performClick()
        composeTestRule.onNodeWithText("Cloud Sync").performClick()
        composeTestRule.onNodeWithText("Enable Sync").performClick()
        
        // Then: Should show error state
        composeTestRule.onNodeWithText("Sync Error").assertIsDisplayed()
        composeTestRule.onNodeWithText("Unable to connect to cloud service").assertIsDisplayed()
        
        // When: Retry action
        composeTestRule.onNodeWithText("Retry").performClick()
        
        // Then: Should show loading state
        composeTestRule.onNodeWithText("Connecting...").assertIsDisplayed()
        
        // When: Error persists
        composeTestRule.waitUntil(timeoutMillis = 3000) {
            composeTestRule.onAllNodesWithText("Sync Error").fetchSemanticsNodes().isNotEmpty()
        }
        
        // Then: Should show error recovery options
        composeTestRule.onNodeWithText("Work Offline").assertIsDisplayed()
        composeTestRule.onNodeWithText("Check Settings").assertIsDisplayed()
    }
    
    @Test
    fun testFollowOnInvestmentFlow() {
        // Given: Calculator in Blended IRR mode
        composeTestRule.onNodeWithContentDescription("Calculation Mode Selector").performClick()
        composeTestRule.onNodeWithText("Calculate Blended IRR").performClick()
        
        // Enter initial values
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("100000")
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("300000")
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("36")
        
        // When: Add follow-on investment
        composeTestRule.onNodeWithText("Add Follow-on Investment").performClick()
        
        // Then: Follow-on investment dialog should appear
        composeTestRule.onNodeWithText("Add Follow-on Investment").assertIsDisplayed()
        composeTestRule.onNodeWithText("Investment Amount").assertIsDisplayed()
        
        // Enter follow-on details
        composeTestRule.onNodeWithText("Investment Amount").performTextInput("50000")
        composeTestRule.onNodeWithText("Timing").performClick()
        composeTestRule.onNodeWithText("12 months from initial").performClick()
        composeTestRule.onNodeWithText("Valuation Mode").performClick()
        composeTestRule.onNodeWithText("Tag Along").performClick()
        
        // Add the investment
        composeTestRule.onNodeWithText("Add").performClick()
        
        // Then: Should show in follow-on investments list
        composeTestRule.onNodeWithText("$50,000 at 12 months").assertIsDisplayed()
        
        // When: Calculate with follow-on investments
        composeTestRule.onNodeWithText("Calculate").performClick()
        
        // Then: Should show blended IRR result
        composeTestRule.onNodeWithText("Blended IRR Result").assertIsDisplayed()
    }
    
    @Test
    fun testAccessibilityFeatures() {
        // Given: Calculator screen
        composeTestRule.onNodeWithText("Calculator").assertIsDisplayed()
        
        // Test semantic labels
        composeTestRule.onNodeWithContentDescription("Initial Investment Input").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Outcome Amount Input").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Calculate Button").assertIsDisplayed()
        
        // Test focus navigation
        composeTestRule.onNodeWithContentDescription("Initial Investment Input").performClick()
        composeTestRule.onNodeWithContentDescription("Initial Investment Input").assertIsFocused()
        
        // Test screen reader announcements
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithContentDescription("Calculation completed. IRR is 22.47%").assertIsDisplayed()
        
        // Test high contrast mode support
        // Note: This would require additional setup for theme testing
        composeTestRule.onNodeWithText("Settings").performClick()
        composeTestRule.onNodeWithText("Accessibility").performClick()
        composeTestRule.onNodeWithText("High Contrast").performClick()
        
        // Verify high contrast theme is applied
        composeTestRule.onNodeWithText("Calculator").performClick()
        // Visual verification would be done through screenshot testing
    }
}