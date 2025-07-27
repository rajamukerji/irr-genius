package com.irrgenius.android

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class FormValidationUITest {
    
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()
    
    @Test
    fun testIRRCalculationValidation() {
        // Given: IRR calculation mode
        composeTestRule.onNodeWithText("Calculate IRR").assertIsDisplayed()
        
        // Test empty fields validation
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("Please fill in all required fields").assertIsDisplayed()
        
        // Test negative initial investment
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("-100000")
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("150000")
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("24")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("Initial investment must be positive").assertIsDisplayed()
        
        // Test zero outcome amount
        composeTestRule.onNodeWithText("Initial Investment").performTextClearance()
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("100000")
        composeTestRule.onNodeWithText("Outcome Amount").performTextClearance()
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("0")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("Outcome amount must be positive").assertIsDisplayed()
        
        // Test negative time
        composeTestRule.onNodeWithText("Outcome Amount").performTextClearance()
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("150000")
        composeTestRule.onNodeWithText("Time (Months)").performTextClearance()
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("-12")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("Time must be positive").assertIsDisplayed()
        
        // Test valid inputs
        composeTestRule.onNodeWithText("Time (Months)").performTextClearance()
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("24")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("IRR Result").assertIsDisplayed()
    }
    
    @Test
    fun testOutcomeCalculationValidation() {
        // Given: Outcome calculation mode
        composeTestRule.onNodeWithContentDescription("Calculation Mode Selector").performClick()
        composeTestRule.onNodeWithText("Calculate Outcome").performClick()
        
        // Test IRR range validation
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("100000")
        composeTestRule.onNodeWithText("IRR (%)").performTextInput("-150")
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("24")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("IRR must be between -100 and 1000").assertIsDisplayed()
        
        // Test extremely high IRR
        composeTestRule.onNodeWithText("IRR (%)").performTextClearance()
        composeTestRule.onNodeWithText("IRR (%)").performTextInput("1500")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("IRR must be between -100 and 1000").assertIsDisplayed()
        
        // Test valid IRR
        composeTestRule.onNodeWithText("IRR (%)").performTextClearance()
        composeTestRule.onNodeWithText("IRR (%)").performTextInput("15")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("Outcome Result").assertIsDisplayed()
    }
    
    @Test
    fun testPortfolioUnitInvestmentValidation() {
        // Given: Portfolio Unit Investment mode
        composeTestRule.onNodeWithContentDescription("Calculation Mode Selector").performClick()
        composeTestRule.onNodeWithText("Portfolio Unit Investment").performClick()
        
        // Test success rate validation
        composeTestRule.onNodeWithText("Investment Amount").performTextInput("100000")
        composeTestRule.onNodeWithText("Unit Price").performTextInput("1000")
        composeTestRule.onNodeWithText("Success Rate (%)").performTextInput("150")
        composeTestRule.onNodeWithText("Outcome Per Unit").performTextInput("2000")
        composeTestRule.onNodeWithText("Investor Share (%)").performTextInput("80")
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("36")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("Success rate must be between 0 and 100").assertIsDisplayed()
        
        // Test investor share validation
        composeTestRule.onNodeWithText("Success Rate (%)").performTextClearance()
        composeTestRule.onNodeWithText("Success Rate (%)").performTextInput("75")
        composeTestRule.onNodeWithText("Investor Share (%)").performTextClearance()
        composeTestRule.onNodeWithText("Investor Share (%)").performTextInput("120")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("Investor share must be between 0 and 100").assertIsDisplayed()
        
        // Test zero unit price
        composeTestRule.onNodeWithText("Investor Share (%)").performTextClearance()
        composeTestRule.onNodeWithText("Investor Share (%)").performTextInput("80")
        composeTestRule.onNodeWithText("Unit Price").performTextClearance()
        composeTestRule.onNodeWithText("Unit Price").performTextInput("0")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("Unit price must be positive").assertIsDisplayed()
        
        // Test valid inputs
        composeTestRule.onNodeWithText("Unit Price").performTextClearance()
        composeTestRule.onNodeWithText("Unit Price").performTextInput("1000")
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("Portfolio IRR Result").assertIsDisplayed()
    }
    
    @Test
    fun testFollowOnInvestmentValidation() {
        // Given: Blended IRR mode with follow-on investment
        composeTestRule.onNodeWithContentDescription("Calculation Mode Selector").performClick()
        composeTestRule.onNodeWithText("Calculate Blended IRR").performClick()
        
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("100000")
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("300000")
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("36")
        
        composeTestRule.onNodeWithText("Add Follow-on Investment").performClick()
        
        // Test negative follow-on amount
        composeTestRule.onNodeWithText("Investment Amount").performTextInput("-50000")
        composeTestRule.onNodeWithText("Add").performClick()
        composeTestRule.onNodeWithText("Investment amount must be positive").assertIsDisplayed()
        
        // Test invalid timing
        composeTestRule.onNodeWithText("Investment Amount").performTextClearance()
        composeTestRule.onNodeWithText("Investment Amount").performTextInput("50000")
        composeTestRule.onNodeWithText("Timing").performClick()
        composeTestRule.onNodeWithText("Custom").performClick()
        composeTestRule.onNodeWithText("Months from Initial").performTextInput("-6")
        composeTestRule.onNodeWithText("Add").performClick()
        composeTestRule.onNodeWithText("Timing must be positive").assertIsDisplayed()
        
        // Test invalid custom valuation
        composeTestRule.onNodeWithText("Months from Initial").performTextClearance()
        composeTestRule.onNodeWithText("Months from Initial").performTextInput("12")
        composeTestRule.onNodeWithText("Valuation Mode").performClick()
        composeTestRule.onNodeWithText("Custom").performClick()
        composeTestRule.onNodeWithText("Custom Valuation").performTextInput("-100000")
        composeTestRule.onNodeWithText("Add").performClick()
        composeTestRule.onNodeWithText("Custom valuation must be positive").assertIsDisplayed()
        
        // Test valid follow-on investment
        composeTestRule.onNodeWithText("Custom Valuation").performTextClearance()
        composeTestRule.onNodeWithText("Custom Valuation").performTextInput("200000")
        composeTestRule.onNodeWithText("Add").performClick()
        composeTestRule.onNodeWithText("$50,000 at 12 months").assertIsDisplayed()
    }
    
    @Test
    fun testSaveCalculationValidation() {
        // Given: A completed calculation
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("100000")
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("150000")
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("24")
        composeTestRule.onNodeWithText("Calculate").performClick()
        
        composeTestRule.onNodeWithContentDescription("Save Calculation").performClick()
        
        // Test empty name validation
        composeTestRule.onNodeWithText("Save").performClick()
        composeTestRule.onNodeWithText("Calculation name cannot be empty").assertIsDisplayed()
        
        // Test name length validation
        val longName = "a".repeat(101)
        composeTestRule.onNodeWithText("Calculation Name").performTextInput(longName)
        composeTestRule.onNodeWithText("Save").performClick()
        composeTestRule.onNodeWithText("Name too long (max 100 characters)").assertIsDisplayed()
        
        // Test invalid characters in name
        composeTestRule.onNodeWithText("Calculation Name").performTextClearance()
        composeTestRule.onNodeWithText("Calculation Name").performTextInput("Test<Calculation>")
        composeTestRule.onNodeWithText("Save").performClick()
        composeTestRule.onNodeWithText("Name contains invalid characters").assertIsDisplayed()
        
        // Test valid name
        composeTestRule.onNodeWithText("Calculation Name").performTextClearance()
        composeTestRule.onNodeWithText("Calculation Name").performTextInput("Valid Calculation Name")
        composeTestRule.onNodeWithText("Save").performClick()
        composeTestRule.onNodeWithText("Calculation saved successfully").assertIsDisplayed()
    }
    
    @Test
    fun testProjectCreationValidation() {
        // Given: Projects screen
        composeTestRule.onNodeWithText("Projects").performClick()
        composeTestRule.onNodeWithContentDescription("Add Project").performClick()
        
        // Test empty name validation
        composeTestRule.onNodeWithText("Create").performClick()
        composeTestRule.onNodeWithText("Project name cannot be empty").assertIsDisplayed()
        
        // Test name length validation
        val longName = "a".repeat(51)
        composeTestRule.onNodeWithText("Project Name").performTextInput(longName)
        composeTestRule.onNodeWithText("Create").performClick()
        composeTestRule.onNodeWithText("Name too long (max 50 characters)").assertIsDisplayed()
        
        // Test description length validation
        composeTestRule.onNodeWithText("Project Name").performTextClearance()
        composeTestRule.onNodeWithText("Project Name").performTextInput("Valid Project")
        val longDescription = "a".repeat(501)
        composeTestRule.onNodeWithText("Description").performTextInput(longDescription)
        composeTestRule.onNodeWithText("Create").performClick()
        composeTestRule.onNodeWithText("Description too long (max 500 characters)").assertIsDisplayed()
        
        // Test valid project creation
        composeTestRule.onNodeWithText("Description").performTextClearance()
        composeTestRule.onNodeWithText("Description").performTextInput("Valid project description")
        composeTestRule.onNodeWithText("Create").performClick()
        composeTestRule.onNodeWithText("Valid Project").assertIsDisplayed()
    }
    
    @Test
    fun testImportDataValidation() {
        // Given: Import screen
        composeTestRule.onNodeWithText("Settings").performClick()
        composeTestRule.onNodeWithText("Import Data").performClick()
        
        // Test no file selected
        composeTestRule.onNodeWithText("Import").performClick()
        composeTestRule.onNodeWithText("Please select a file to import").assertIsDisplayed()
        
        // Test invalid file format (simulated)
        composeTestRule.onNodeWithText("Select File").performClick()
        // Simulate selecting invalid file
        composeTestRule.onNodeWithText("Invalid file format. Please select CSV or Excel file").assertIsDisplayed()
        
        // Test corrupted file (simulated)
        composeTestRule.onNodeWithText("Select File").performClick()
        // Simulate selecting corrupted file
        composeTestRule.onNodeWithText("File appears to be corrupted or unreadable").assertIsDisplayed()
        
        // Test valid file with validation errors
        composeTestRule.onNodeWithText("Select File").performClick()
        // Simulate selecting valid file with data errors
        composeTestRule.onNodeWithText("Preview").performClick()
        composeTestRule.onNodeWithText("Import Preview").assertIsDisplayed()
        composeTestRule.onNodeWithText("3 validation errors found").assertIsDisplayed()
        composeTestRule.onNodeWithText("Row 2: Empty calculation name").assertIsDisplayed()
        composeTestRule.onNodeWithText("Row 4: Invalid calculation type").assertIsDisplayed()
        composeTestRule.onNodeWithText("Row 6: Negative investment amount").assertIsDisplayed()
        
        // Import with errors
        composeTestRule.onNodeWithText("Import Anyway").performClick()
        composeTestRule.onNodeWithText("Import completed with 2 valid calculations").assertIsDisplayed()
    }
    
    @Test
    fun testRealTimeValidationFeedback() {
        // Given: Calculator screen
        composeTestRule.onNodeWithText("Calculator").assertIsDisplayed()
        
        // Test real-time validation as user types
        val initialInvestmentField = composeTestRule.onNodeWithText("Initial Investment")
        
        // Type negative value
        initialInvestmentField.performTextInput("-")
        composeTestRule.onNodeWithText("Must be positive").assertIsDisplayed()
        
        // Continue typing to make it valid
        initialInvestmentField.performTextInput("100000")
        composeTestRule.onNodeWithText("Must be positive").assertDoesNotExist()
        
        // Test outcome amount validation
        val outcomeAmountField = composeTestRule.onNodeWithText("Outcome Amount")
        outcomeAmountField.performTextInput("0")
        composeTestRule.onNodeWithText("Must be greater than 0").assertIsDisplayed()
        
        outcomeAmountField.performTextClearance()
        outcomeAmountField.performTextInput("150000")
        composeTestRule.onNodeWithText("Must be greater than 0").assertDoesNotExist()
        
        // Test time validation
        val timeField = composeTestRule.onNodeWithText("Time (Months)")
        timeField.performTextInput("0")
        composeTestRule.onNodeWithText("Must be positive").assertIsDisplayed()
        
        timeField.performTextClearance()
        timeField.performTextInput("24")
        composeTestRule.onNodeWithText("Must be positive").assertDoesNotExist()
        
        // All fields valid - calculate button should be enabled
        composeTestRule.onNodeWithText("Calculate").assertIsEnabled()
    }
    
    @Test
    fun testValidationErrorRecovery() {
        // Given: Calculator with validation errors
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("-1000")
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("0")
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("-12")
        
        composeTestRule.onNodeWithText("Calculate").performClick()
        
        // Multiple validation errors should be displayed
        composeTestRule.onNodeWithText("Please fix the following errors:").assertIsDisplayed()
        composeTestRule.onNodeWithText("• Initial investment must be positive").assertIsDisplayed()
        composeTestRule.onNodeWithText("• Outcome amount must be positive").assertIsDisplayed()
        composeTestRule.onNodeWithText("• Time must be positive").assertIsDisplayed()
        
        // Fix errors one by one
        composeTestRule.onNodeWithText("Initial Investment").performTextClearance()
        composeTestRule.onNodeWithText("Initial Investment").performTextInput("100000")
        composeTestRule.onNodeWithText("• Initial investment must be positive").assertDoesNotExist()
        
        composeTestRule.onNodeWithText("Outcome Amount").performTextClearance()
        composeTestRule.onNodeWithText("Outcome Amount").performTextInput("150000")
        composeTestRule.onNodeWithText("• Outcome amount must be positive").assertDoesNotExist()
        
        composeTestRule.onNodeWithText("Time (Months)").performTextClearance()
        composeTestRule.onNodeWithText("Time (Months)").performTextInput("24")
        composeTestRule.onNodeWithText("• Time must be positive").assertDoesNotExist()
        
        // Error summary should disappear
        composeTestRule.onNodeWithText("Please fix the following errors:").assertDoesNotExist()
        
        // Calculate should now work
        composeTestRule.onNodeWithText("Calculate").performClick()
        composeTestRule.onNodeWithText("IRR Result").assertIsDisplayed()
    }
}