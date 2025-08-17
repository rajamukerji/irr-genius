package com.irrgenius.android

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.irrgenius.android.data.database.AppDatabase
import com.irrgenius.android.data.models.*
import com.irrgenius.android.data.repository.RoomCalculationRepository
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDateTime
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@RunWith(RobolectricTestRunner::class)
class RoomCalculationRepositoryTest {
    
    private lateinit var database: AppDatabase
    private lateinit var repository: RoomCalculationRepository
    
    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        
        repository = RoomCalculationRepository(
            database.calculationDao(),
            database.followOnInvestmentDao()
        )
    }
    
    @After
    fun teardown() {
        database.close()
    }
    
    @Test
    fun saveAndLoadCalculation() = runTest {
        // Given
        val calculation = createTestCalculation()
        
        // When
        repository.saveCalculation(calculation)
        val loaded = repository.loadCalculation(calculation.id)
        
        // Then
        assertNotNull(loaded)
        assertEquals(calculation.id, loaded.id)
        assertEquals(calculation.name, loaded.name)
        assertEquals(calculation.calculationType, loaded.calculationType)
        assertEquals(calculation.initialInvestment, loaded.initialInvestment)
        assertEquals(calculation.calculatedResult, loaded.calculatedResult)
    }
    
    @Test
    fun loadAllCalculations() = runTest {
        // Given
        val calculation1 = createTestCalculation(name = "Test 1")
        val calculation2 = createTestCalculation(name = "Test 2")
        
        // When
        repository.saveCalculation(calculation1)
        repository.saveCalculation(calculation2)
        val calculations = repository.loadCalculations()
        
        // Then
        assertEquals(2, calculations.size)
        assertTrue(calculations.any { it.name == "Test 1" })
        assertTrue(calculations.any { it.name == "Test 2" })
    }
    
    @Test
    fun deleteCalculation() = runTest {
        // Given
        val calculation = createTestCalculation()
        repository.saveCalculation(calculation)
        
        // When
        repository.deleteCalculation(calculation.id)
        val loaded = repository.loadCalculation(calculation.id)
        
        // Then
        assertNull(loaded)
    }
    
    @Test
    fun searchCalculations() = runTest {
        // Given
        val calculation1 = createTestCalculation(name = "IRR Analysis")
        val calculation2 = createTestCalculation(name = "Outcome Calculation")
        val calculation3 = createTestCalculation(name = "Investment Study", notes = "IRR related")
        
        repository.saveCalculation(calculation1)
        repository.saveCalculation(calculation2)
        repository.saveCalculation(calculation3)
        
        // When
        val results = repository.searchCalculations("IRR")
        
        // Then
        assertEquals(2, results.size)
        assertTrue(results.any { it.name == "IRR Analysis" })
        assertTrue(results.any { it.name == "Investment Study" })
    }
    
    @Test
    fun loadCalculationsByProject() = runTest {
        // Given
        val projectId = "test-project-id"
        val calculation1 = createTestCalculation(name = "Test 1", projectId = projectId)
        val calculation2 = createTestCalculation(name = "Test 2", projectId = projectId)
        val calculation3 = createTestCalculation(name = "Test 3") // No project
        
        repository.saveCalculation(calculation1)
        repository.saveCalculation(calculation2)
        repository.saveCalculation(calculation3)
        
        // When
        val results = repository.loadCalculationsByProject(projectId)
        
        // Then
        assertEquals(2, results.size)
        assertTrue(results.any { it.name == "Test 1" })
        assertTrue(results.any { it.name == "Test 2" })
    }
    
    private fun createTestCalculation(
        name: String = "Test Calculation",
        projectId: String? = null,
        notes: String? = "Test calculation notes"
    ): SavedCalculation {
        return SavedCalculation(
            name = name,
            calculationType = CalculationMode.CALCULATE_IRR,
            createdDate = LocalDateTime.now(),
            modifiedDate = LocalDateTime.now(),
            projectId = projectId,
            initialInvestment = 100000.0,
            outcomeAmount = null,
            timeInMonths = 24.0,
            irr = null,
            unitPrice = null,
            successRate = null,
            outcomePerUnit = null,
            investorShare = null,
            feePercentage = null,
            calculatedResult = 15.5,
            growthPointsJson = """[{"month":0,"value":100000},{"month":12,"value":110000},{"month":24,"value":125000}]""",
            notes = notes,
            tags = """["test","calculation"]"""
        )
    }
}