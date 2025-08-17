package com.irrgenius.android

import com.irrgenius.android.data.models.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDateTime
import kotlin.test.*

@RunWith(RobolectricTestRunner::class)
class SavedCalculationValidationTest {
    
    @Test
    fun testValidCalculationCreation() {
        // Given valid inputs
        val calculation = SavedCalculation.createValidated(
            name = "Test Calculation",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0
        )
        
        // Then calculation should be created successfully
        assertEquals("Test Calculation", calculation.name)
        assertEquals(CalculationMode.CALCULATE_IRR, calculation.calculationType)
        assertTrue(calculation.isComplete)
    }
    
    @Test
    fun testEmptyNameValidation() {
        // When creating calculation with empty name
        val exception = assertFailsWith<SavedCalculationValidationException> {
            SavedCalculation.createValidated(
                name = "",
                calculationType = CalculationMode.CALCULATE_IRR
            )
        }
        
        // Then should throw validation exception
        assertTrue(exception.message!!.contains("cannot be empty"))
    }
    
    @Test
    fun testLongNameValidation() {
        // Given name longer than 100 characters
        val longName = "a".repeat(101)
        
        // When creating calculation
        val exception = assertFailsWith<SavedCalculationValidationException> {
            SavedCalculation.createValidated(
                name = longName,
                calculationType = CalculationMode.CALCULATE_IRR
            )
        }
        
        // Then should throw validation exception
        assertTrue(exception.message!!.contains("too long"))
    }
    
    @Test
    fun testInvalidCharactersInName() {
        // Given name with invalid characters
        val invalidNames = listOf("test<name", "test>name", "test:name", "test\"name", "test/name")
        
        for (invalidName in invalidNames) {
            // When creating calculation
            val exception = assertFailsWith<SavedCalculationValidationException> {
                SavedCalculation.createValidated(
                    name = invalidName,
                    calculationType = CalculationMode.CALCULATE_IRR
                )
            }
            
            // Then should throw validation exception
            assertTrue(exception.message!!.contains("invalid characters"))
        }
    }
    
    @Test
    fun testCalculateIRRValidation() {
        // Test missing required fields
        val exception = assertFailsWith<SavedCalculationValidationException> {
            SavedCalculation.createValidated(
                name = "Test",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 100000.0
                // Missing outcomeAmount and timeInMonths
            )
        }
        
        assertTrue(exception.message!!.contains("Missing required fields"))
        assertTrue(exception.message!!.contains("Outcome Amount"))
        assertTrue(exception.message!!.contains("Time in Months"))
    }
    
    @Test
    fun testNegativeInvestmentValidation() {
        // When creating calculation with negative investment
        val exception = assertFailsWith<SavedCalculationValidationException> {
            SavedCalculation.createValidated(
                name = "Test",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = -1000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0
            )
        }
        
        // Then should throw validation exception
        assertTrue(exception.message!!.contains("must be positive"))
    }
    
    @Test
    fun testPortfolioUnitInvestmentValidation() {
        // Test all required fields for portfolio unit investment
        val calculation = SavedCalculation.createValidated(
            name = "Portfolio Test",
            calculationType = CalculationMode.PORTFOLIO_UNIT_INVESTMENT,
            initialInvestment = 100000.0,
            unitPrice = 1000.0,
            successRate = 75.0,
            outcomePerUnit = 2000.0,
            investorShare = 80.0,
            timeInMonths = 36.0
        )
        
        assertEquals(CalculationMode.PORTFOLIO_UNIT_INVESTMENT, calculation.calculationType)
        assertEquals(75.0, calculation.successRate)
        assertTrue(calculation.isComplete)
    }
    
    @Test
    fun testInvalidSuccessRate() {
        // Test success rate outside valid range
        val exception = assertFailsWith<SavedCalculationValidationException> {
            SavedCalculation.createValidated(
                name = "Test",
                calculationType = CalculationMode.PORTFOLIO_UNIT_INVESTMENT,
                initialInvestment = 100000.0,
                unitPrice = 1000.0,
                successRate = 150.0, // Invalid: > 100
                outcomePerUnit = 2000.0,
                investorShare = 80.0,
                timeInMonths = 36.0
            )
        }
        
        assertTrue(exception.message!!.contains("between 0 and 100"))
    }
    
    @Test
    fun testCalculationSummary() {
        // Test different calculation type summaries
        val irrCalc = SavedCalculation.createValidated(
            name = "IRR Test",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47
        )
        
        assertEquals("IRR: 22.47%", irrCalc.summary)
        
        val outcomeCalc = SavedCalculation.createValidated(
            name = "Outcome Test",
            calculationType = CalculationMode.CALCULATE_OUTCOME,
            initialInvestment = 100000.0,
            irr = 15.0,
            timeInMonths = 24.0,
            calculatedResult = 132500.0
        )
        
        assertEquals("Outcome: 132500.00", outcomeCalc.summary)
    }
    
    @Test
    fun testTagsSerialization() {
        // Test tags JSON serialization
        val calculation = SavedCalculation.createValidated(
            name = "Test",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0
        )
        
        val withTags = calculation.withTags(listOf("real-estate", "investment", "analysis"))
        val tags = withTags.getTagsFromJson()
        
        assertEquals(3, tags.size)
        assertTrue(tags.contains("real-estate"))
        assertTrue(tags.contains("investment"))
        assertTrue(tags.contains("analysis"))
    }
    
    @Test
    fun testGrowthPointsSerialization() {
        // Test growth points serialization
        val growthPoints = listOf(
            GrowthPoint(0, 100000.0),
            GrowthPoint(12, 110000.0),
            GrowthPoint(24, 125000.0)
        )
        
        val calculation = SavedCalculation.createValidated(
            name = "Test",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0
        )
        
        val withGrowthPoints = calculation.withGrowthPoints(growthPoints)
        val retrievedPoints = withGrowthPoints.getGrowthPoints()
        
        assertEquals(3, retrievedPoints.size)
        assertEquals(0, retrievedPoints[0].month)
        assertEquals(100000.0, retrievedPoints[0].value)
        assertEquals(24, retrievedPoints[2].month)
        assertEquals(125000.0, retrievedPoints[2].value)
    }
    
    @Test
    fun testModificationDateUpdate() {
        // Given a calculation
        val original = SavedCalculation.createValidated(
            name = "Test",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0
        )
        
        // Wait a bit to ensure different timestamp
        Thread.sleep(10)
        
        // When updating modification date
        val updated = original.withUpdatedModificationDate()
        
        // Then modification date should be newer
        assertTrue(updated.modifiedDate.isAfter(original.modifiedDate))
        assertEquals(original.id, updated.id)
        assertEquals(original.name, updated.name)
    }
}