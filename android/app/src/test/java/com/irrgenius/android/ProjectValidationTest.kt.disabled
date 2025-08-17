package com.irrgenius.android

import com.irrgenius.android.data.models.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDateTime
import kotlin.test.*

@RunWith(RobolectricTestRunner::class)
class ProjectValidationTest {
    
    @Test
    fun testValidProjectCreation() {
        // Given valid inputs
        val project = Project.createValidated(
            name = "Real Estate Portfolio",
            description = "Investment properties analysis",
            color = "#007AFF"
        )
        
        // Then project should be created successfully
        assertEquals("Real Estate Portfolio", project.name)
        assertEquals("Investment properties analysis", project.description)
        assertEquals("#007AFF", project.color)
        assertTrue(project.isValid)
    }
    
    @Test
    fun testEmptyNameValidation() {
        // When creating project with empty name
        val exception = assertFailsWith<ProjectValidationException> {
            Project.createValidated(name = "")
        }
        
        // Then should throw validation exception
        assertTrue(exception.message!!.contains("cannot be empty"))
    }
    
    @Test
    fun testLongNameValidation() {
        // Given name longer than 50 characters
        val longName = "a".repeat(51)
        
        // When creating project
        val exception = assertFailsWith<ProjectValidationException> {
            Project.createValidated(name = longName)
        }
        
        // Then should throw validation exception
        assertTrue(exception.message!!.contains("too long"))
    }
    
    @Test
    fun testInvalidCharactersInName() {
        // Given name with invalid characters
        val invalidNames = listOf("test<name", "test>name", "test:name", "test\"name", "test/name")
        
        for (invalidName in invalidNames) {
            // When creating project
            val exception = assertFailsWith<ProjectValidationException> {
                Project.createValidated(name = invalidName)
            }
            
            // Then should throw validation exception
            assertTrue(exception.message!!.contains("invalid characters"))
        }
    }
    
    @Test
    fun testLongDescriptionValidation() {
        // Given description longer than 500 characters
        val longDescription = "a".repeat(501)
        
        // When creating project
        val exception = assertFailsWith<ProjectValidationException> {
            Project.createValidated(
                name = "Test Project",
                description = longDescription
            )
        }
        
        // Then should throw validation exception
        assertTrue(exception.message!!.contains("too long"))
    }
    
    @Test
    fun testInvalidColorValidation() {
        // Given invalid color formats
        val invalidColors = listOf("FF0000", "#GG0000", "#12345", "#1234567", "red", "")
        
        for (invalidColor in invalidColors) {
            // When creating project
            val exception = assertFailsWith<ProjectValidationException> {
                Project.createValidated(
                    name = "Test Project",
                    color = invalidColor
                )
            }
            
            // Then should throw validation exception
            assertTrue(exception.message!!.contains("valid hex color"))
        }
    }
    
    @Test
    fun testValidColorFormats() {
        // Given valid color formats
        val validColors = listOf("#FF0000", "#00FF00", "#0000FF", "#FFF", "#000", "#123ABC")
        
        for (validColor in validColors) {
            // When creating project
            val project = Project.createValidated(
                name = "Test Project",
                color = validColor
            )
            
            // Then should be created successfully
            assertEquals(validColor, project.color)
            assertTrue(project.isValid)
        }
    }
    
    @Test
    fun testDefaultColors() {
        // Test that default colors are valid
        for (color in Project.defaultColors) {
            assertDoesNotThrow {
                Project.validateColor(color)
            }
        }
        
        // Test that we have expected number of default colors
        assertEquals(10, Project.defaultColors.size)
        assertTrue(Project.defaultColors.contains("#007AFF")) // Blue
        assertTrue(Project.defaultColors.contains("#34C759")) // Green
    }
    
    @Test
    fun testProjectStatistics() {
        // Given a project and calculations
        val project = Project.createValidated(
            name = "Test Project"
        )
        
        val calculations = listOf(
            createTestCalculation(projectId = project.id, isComplete = true, type = CalculationMode.CALCULATE_IRR),
            createTestCalculation(projectId = project.id, isComplete = false, type = CalculationMode.CALCULATE_OUTCOME),
            createTestCalculation(projectId = project.id, isComplete = true, type = CalculationMode.CALCULATE_IRR),
            createTestCalculation(projectId = "other-project", isComplete = true, type = CalculationMode.CALCULATE_INITIAL)
        )
        
        // When calculating statistics
        val stats = project.calculateStatistics(calculations)
        
        // Then should return correct statistics
        assertEquals(3, stats.totalCalculations) // Only calculations for this project
        assertEquals(2, stats.completedCalculations)
        assertEquals(0.67, stats.completionRate, 0.01)
        assertEquals(2, stats.calculationTypes[CalculationMode.CALCULATE_IRR])
        assertEquals(1, stats.calculationTypes[CalculationMode.CALCULATE_OUTCOME])
        assertNull(stats.calculationTypes[CalculationMode.CALCULATE_INITIAL]) // Not in this project
    }
    
    @Test
    fun testProjectStatisticsEmptyCalculations() {
        // Given a project with no calculations
        val project = Project.createValidated(name = "Empty Project")
        
        // When calculating statistics
        val stats = project.calculateStatistics(emptyList())
        
        // Then should return zero statistics
        assertEquals(0, stats.totalCalculations)
        assertEquals(0, stats.completedCalculations)
        assertEquals(0.0, stats.completionRate)
        assertTrue(stats.calculationTypes.isEmpty())
        assertNull(stats.lastModified)
    }
    
    @Test
    fun testModificationDateUpdate() {
        // Given a project
        val original = Project.createValidated(
            name = "Test Project",
            description = "Original description"
        )
        
        // Wait a bit to ensure different timestamp
        Thread.sleep(10)
        
        // When updating modification date
        val updated = original.withUpdatedModificationDate()
        
        // Then modification date should be newer
        assertTrue(updated.modifiedDate.isAfter(original.modifiedDate))
        assertEquals(original.id, updated.id)
        assertEquals(original.name, updated.name)
        assertEquals(original.description, updated.description)
    }
    
    @Test
    fun testProjectValidation() {
        // Given a valid project
        val project = Project.createValidated(
            name = "Valid Project",
            description = "Valid description",
            color = "#FF0000"
        )
        
        // When validating
        assertDoesNotThrow {
            project.validate()
        }
        
        assertTrue(project.isValid)
    }
    
    private fun createTestCalculation(
        projectId: String,
        isComplete: Boolean,
        type: CalculationMode
    ): SavedCalculation {
        return if (isComplete) {
            SavedCalculation.createValidated(
                name = "Test Calculation",
                calculationType = type,
                projectId = projectId,
                initialInvestment = 100000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0,
                calculatedResult = 22.47
            )
        } else {
            SavedCalculation(
                name = "Incomplete Calculation",
                calculationType = type,
                createdDate = LocalDateTime.now(),
                modifiedDate = LocalDateTime.now(),
                projectId = projectId,
                initialInvestment = null, // Missing required field
                outcomeAmount = null,
                timeInMonths = null,
                irr = null,
                unitPrice = null,
                successRate = null,
                outcomePerUnit = null,
                investorShare = null,
                feePercentage = null,
                calculatedResult = null,
                growthPointsJson = null,
                notes = null,
                tags = null
            )
        }
    }
}