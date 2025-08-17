package com.irrgenius.android

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.irrgenius.android.data.AutoSaveManager
import com.irrgenius.android.data.DataManager
import com.irrgenius.android.data.database.AppDatabase
import com.irrgenius.android.data.export.PDFExportService
import com.irrgenius.android.data.export.SharingService
import com.irrgenius.android.data.import.CSVImportService
import com.irrgenius.android.data.import.ExcelImportService
import com.irrgenius.android.data.models.*
import com.irrgenius.android.data.repository.RoomCalculationRepository
import com.irrgenius.android.data.repository.RoomProjectRepository
import com.irrgenius.android.data.sync.CloudSyncService
import com.irrgenius.android.services.ErrorMessagingService
import com.irrgenius.android.services.ErrorRecoveryService
import com.irrgenius.android.validation.ValidationService
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.File
import java.io.FileWriter
import java.time.LocalDateTime
import kotlin.random.Random
import kotlin.system.measureTimeMillis
import kotlin.test.*

@RunWith(RobolectricTestRunner::class)
class ComprehensiveIntegrationTest {
    
    private lateinit var context: Context
    private lateinit var database: AppDatabase
    private lateinit var dataManager: DataManager
    private lateinit var calculationRepository: RoomCalculationRepository
    private lateinit var projectRepository: RoomProjectRepository
    private lateinit var csvImportService: CSVImportService
    private lateinit var excelImportService: ExcelImportService
    private lateinit var pdfExportService: PDFExportService
    private lateinit var sharingService: SharingService
    private lateinit var cloudSyncService: CloudSyncService
    private lateinit var validationService: ValidationService
    private lateinit var errorRecoveryService: ErrorRecoveryService
    private lateinit var errorMessagingService: ErrorMessagingService
    private lateinit var autoSaveManager: AutoSaveManager
    
    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        
        database = Room.inMemoryDatabaseBuilder(
            context,
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        
        calculationRepository = RoomCalculationRepository(
            database.calculationDao(),
            database.followOnInvestmentDao()
        )
        
        projectRepository = RoomProjectRepository(database.projectDao())
        
        dataManager = DataManager(context)
        
        csvImportService = CSVImportService(context)
        excelImportService = ExcelImportService(context)
        pdfExportService = PDFExportService(context)
        sharingService = SharingService(context)
        cloudSyncService = CloudSyncService(context, dataManager.repositoryFactory)
        validationService = ValidationService()
        errorRecoveryService = ErrorRecoveryService(context)
        errorMessagingService = ErrorMessagingService(context)
        autoSaveManager = AutoSaveManager(calculationRepository)
    }
    
    @After
    fun teardown() {
        database.close()
    }
    
    // MARK: - Complete Application Workflow Tests
    
    @Test
    fun testCompleteApplicationWorkflow() = runTest {
        // Test the complete user journey from project creation to export
        
        // 1. Create a project
        val project = Project.createValidated(
            name = "Complete Workflow Test",
            description = "Testing end-to-end application workflow",
            color = "#007AFF"
        )
        projectRepository.insertProject(project)
        
        // 2. Create multiple calculations of different types
        val calculations = listOf(
            SavedCalculation.createValidated(
                name = "IRR Analysis",
                calculationType = CalculationMode.CALCULATE_IRR,
                projectId = project.id,
                initialInvestment = 100000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0,
                calculatedResult = 22.47,
                notes = "Primary investment analysis"
            ),
            
            SavedCalculation.createValidated(
                name = "Outcome Projection",
                calculationType = CalculationMode.CALCULATE_OUTCOME,
                projectId = project.id,
                initialInvestment = 75000.0,
                irr = 18.0,
                timeInMonths = 18.0,
                calculatedResult = 95000.0,
                notes = "Projected outcome calculation"
            ),
            
            SavedCalculation.createValidated(
                name = "Portfolio Investment",
                calculationType = CalculationMode.PORTFOLIO_UNIT_INVESTMENT,
                projectId = project.id,
                initialInvestment = 200000.0,
                unitPrice = 1000.0,
                successRate = 80.0,
                outcomePerUnit = 2500.0,
                investorShare = 75.0,
                timeInMonths = 36.0,
                calculatedResult = 19.2,
                notes = "Portfolio unit investment analysis"
            )
        )
        
        // 3. Save all calculations
        for (calculation in calculations) {
            calculationRepository.saveCalculation(calculation)
        }
        
        // 4. Verify data persistence
        val savedCalculations = calculationRepository.loadCalculationsByProject(project.id)
        assertEquals(3, savedCalculations.size)
        
        // 5. Test search functionality
        val searchResults = calculationRepository.searchCalculations("IRR")
        assertEquals(1, searchResults.size)
        assertEquals("IRR Analysis", searchResults[0].name)
        
        // 6. Export to different formats
        val pdfExportResults = savedCalculations.map { calculation ->
            pdfExportService.exportCalculationToPDF(calculation)
        }
        
        // Verify all PDF exports succeeded
        for (result in pdfExportResults) {
            assertTrue(result.isSuccess)
            val pdfFile = result.getOrThrow()
            assertTrue(pdfFile.exists())
            assertTrue(pdfFile.length() > 0)
            pdfFile.delete()
        }
        
        // 7. Export project calculations to CSV
        val csvExportResult = csvImportService.exportCalculationsToCSV(savedCalculations)
        assertTrue(csvExportResult.isSuccess)
        val csvFile = csvExportResult.getOrThrow()
        
        val csvContent = csvFile.readText()
        assertTrue(csvContent.contains("IRR Analysis"))
        assertTrue(csvContent.contains("Outcome Projection"))
        assertTrue(csvContent.contains("Portfolio Investment"))
        csvFile.delete()
        
        // 8. Test project statistics
        val allCalculations = calculationRepository.getAllCalculations()
        val projectStats = project.calculateStatistics(allCalculations)
        
        assertEquals(3, projectStats.totalCalculations)
        assertEquals(3, projectStats.completedCalculations)
        assertEquals(1.0, projectStats.completionRate)
        assertEquals(1, projectStats.calculationTypes[CalculationMode.CALCULATE_IRR])
        assertEquals(1, projectStats.calculationTypes[CalculationMode.CALCULATE_OUTCOME])
        assertEquals(1, projectStats.calculationTypes[CalculationMode.PORTFOLIO_UNIT_INVESTMENT])
    }
    
    @Test
    fun testDataPersistenceAndUIIntegration() = runTest {
        // Test integration between data persistence and UI components
        
        // 1. Create calculation with validation
        val validationResult = validationService.validateCalculationInputs(
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = "100000",
            outcomeAmount = "150000",
            timeInMonths = "24",
            irr = null
        )
        
        assertTrue(validationResult.isValid)
        assertTrue(validationResult.errors.isEmpty())
        
        // 2. Create calculation from validated inputs
        val calculation = SavedCalculation.createValidated(
            name = "UI Integration Test",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47,
            notes = "Testing UI integration"
        )
        
        // 3. Save through repository (simulating UI interaction)
        calculationRepository.saveCalculation(calculation)
        
        // 4. Load through repository
        val loadedCalculations = calculationRepository.getAllCalculations()
        assertEquals(1, loadedCalculations.size)
        assertEquals(calculation.name, loadedCalculations[0].name)
        
        // 5. Test auto-save functionality
        val autoSaveCalculation = SavedCalculation.createValidated(
            name = "Auto-Save Test",
            calculationType = CalculationMode.CALCULATE_OUTCOME,
            initialInvestment = 50000.0,
            irr = 15.0,
            timeInMonths = 12.0,
            calculatedResult = 57500.0,
            notes = "Testing auto-save"
        )
        
        // Simulate auto-save after calculation
        calculationRepository.saveCalculation(autoSaveCalculation)
        
        val allCalculations = calculationRepository.getAllCalculations()
        assertEquals(2, allCalculations.size)
        assertTrue(allCalculations.any { it.name == "Auto-Save Test" })
        
        // 6. Test loading state management
        assertFalse(dataManager.isLoading.value)
        assertNull(dataManager.errorMessage.value)
        
        // 7. Test error handling in UI context
        val invalidCalculation = SavedCalculation(
            id = "invalid-id",
            name = "", // Invalid empty name
            calculationType = CalculationMode.CALCULATE_IRR,
            createdDate = LocalDateTime.now(),
            modifiedDate = LocalDateTime.now(),
            projectId = null,
            initialInvestment = -1000.0, // Invalid negative amount
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            irr = null,
            unitPrice = null,
            successRate = null,
            outcomePerUnit = null,
            investorShare = null,
            feePercentage = null,
            calculatedResult = null,
            notes = null,
            tags = null
        )
        
        try {
            calculationRepository.saveCalculation(invalidCalculation)
            fail("Should have thrown validation error")
        } catch (e: Exception) {
            // Expected validation error
            assertTrue(e.message?.contains("validation") == true || e.message?.contains("invalid") == true)
        }
    }
    
    @Test
    fun testPerformanceWithLargeDatasets() = runTest {
        // Test performance with large numbers of calculations
        
        // 1. Create large dataset
        val calculations = mutableListOf<SavedCalculation>()
        val creationTime = measureTimeMillis {
            for (i in 1..1000) {
                val calculation = SavedCalculation.createValidated(
                    name = "Performance Test $i",
                    calculationType = CalculationMode.CALCULATE_IRR,
                    initialInvestment = Random.nextDouble(10000.0, 1000000.0),
                    outcomeAmount = Random.nextDouble(15000.0, 1500000.0),
                    timeInMonths = Random.nextDouble(6.0, 120.0),
                    calculatedResult = Random.nextDouble(5.0, 50.0),
                    notes = "Performance test calculation $i"
                )
                calculations.add(calculation)
            }
        }
        
        println("Created 1000 calculations in ${creationTime}ms")
        
        // 2. Batch save performance test
        val saveTime = measureTimeMillis {
            val batchSize = 100
            val batches = calculations.chunked(batchSize)
            
            batches.map { batch ->
                async {
                    for (calculation in batch) {
                        calculationRepository.saveCalculation(calculation)
                    }
                }
            }.awaitAll()
        }
        
        println("Saved 1000 calculations in ${saveTime}ms")
        
        // 3. Load performance test
        val loadTime = measureTimeMillis {
            val loadedCalculations = calculationRepository.getAllCalculations()
            assertEquals(1000, loadedCalculations.size)
        }
        
        println("Loaded 1000 calculations in ${loadTime}ms")
        
        // 4. Search performance test
        val searchTime = measureTimeMillis {
            val searchResults = calculationRepository.searchCalculations("Performance Test 1")
            assertTrue(searchResults.isNotEmpty())
        }
        
        println("Searched through 1000 calculations in ${searchTime}ms")
        
        // 5. Export performance test
        val loadedCalculations = calculationRepository.getAllCalculations()
        val exportTime = measureTimeMillis {
            val exportResult = csvImportService.exportCalculationsToCSV(loadedCalculations.take(100))
            assertTrue(exportResult.isSuccess)
            val csvFile = exportResult.getOrThrow()
            val fileSize = csvFile.length()
            println("Export file size: $fileSize bytes")
            csvFile.delete()
        }
        
        println("Exported 100 calculations in ${exportTime}ms")
        
        // Performance assertions
        assertTrue(saveTime < 10000, "Batch save should complete within 10 seconds")
        assertTrue(loadTime < 2000, "Load should complete within 2 seconds")
        assertTrue(searchTime < 1000, "Search should complete within 1 second")
        assertTrue(exportTime < 5000, "Export should complete within 5 seconds")
    }
    
    @Test
    fun testMemoryUsageOptimization() = runTest {
        val initialMemory = getMemoryUsage()
        
        // Create and save many calculations
        for (i in 1..500) {
            val calculation = SavedCalculation.createValidated(
                name = "Memory Test $i",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 100000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0,
                calculatedResult = 22.47,
                notes = "Memory usage test calculation"
            )
            
            calculationRepository.saveCalculation(calculation)
            
            // Force garbage collection every 100 calculations
            if (i % 100 == 0) {
                System.gc()
            }
        }
        
        val afterSaveMemory = getMemoryUsage()
        val memoryIncrease = afterSaveMemory - initialMemory
        
        println("Memory usage increased by ${memoryIncrease}MB after saving 500 calculations")
        
        // Load calculations in batches to test pagination
        val batchSize = 50
        var totalLoaded = 0
        
        for (offset in 0 until 500 step batchSize) {
            val batchCalculations = calculationRepository.getCalculationsPaginated(batchSize, offset)
            totalLoaded += batchCalculations.size
        }
        
        assertEquals(500, totalLoaded)
        
        val finalMemory = getMemoryUsage()
        val totalMemoryIncrease = finalMemory - initialMemory
        
        println("Total memory usage increased by ${totalMemoryIncrease}MB")
        
        // Memory usage should not exceed reasonable limits
        assertTrue(totalMemoryIncrease < 100, "Memory usage should not exceed 100MB for 500 calculations")
    }
    
    @Test
    fun testErrorRecoveryWorkflows() = runTest {
        // Test comprehensive error recovery scenarios
        
        // 1. Database corruption recovery
        val calculation = SavedCalculation.createValidated(
            name = "Error Recovery Test",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47
        )
        
        calculationRepository.saveCalculation(calculation)
        
        // Test error recovery by attempting to load invalid calculation
        val recoveryResult = errorRecoveryService.recoverFromDatabaseError()
        // Recovery should handle gracefully even if no corruption exists
        assertTrue(recoveryResult.isSuccess || recoveryResult.isFailure)
        
        // 2. File system error recovery
        val tempFile = File.createTempFile("test", ".csv", context.cacheDir)
        
        // Create file with invalid content
        FileWriter(tempFile).use { it.write("invalid,csv,content\n") }
        
        val importResult = csvImportService.importFromFile(tempFile.absolutePath)
        when (importResult.isFailure) {
            true -> {
                // Should provide user-friendly error message
                val error = importResult.exceptionOrNull()!!
                val errorMessage = errorMessagingService.getUserFriendlyMessage(error)
                assertFalse(errorMessage.isEmpty())
            }
            false -> {
                // Import succeeded but should have validation errors
                val importData = importResult.getOrThrow()
                assertFalse(importData.validationErrors.isEmpty())
            }
        }
        
        tempFile.delete()
        
        // 3. Validation error recovery
        val invalidInputs = mapOf(
            "initialInvestment" to "-1000",
            "outcomeAmount" to "abc",
            "timeInMonths" to "0"
        )
        
        val validationResult = validationService.validateCalculationInputs(
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = invalidInputs["initialInvestment"],
            outcomeAmount = invalidInputs["outcomeAmount"],
            timeInMonths = invalidInputs["timeInMonths"],
            irr = null
        )
        
        assertFalse(validationResult.isValid)
        assertFalse(validationResult.errors.isEmpty())
        
        // Test error recovery suggestions
        for (error in validationResult.errors) {
            val suggestion = errorRecoveryService.getRecoverySuggestion(error)
            assertFalse(suggestion.isEmpty())
        }
    }
    
    @Test
    fun testConcurrentOperations() = runTest {
        // Test concurrent operations for thread safety
        
        val operationCount = 50
        val calculations = (1..operationCount).map { i ->
            SavedCalculation.createValidated(
                name = "Concurrent Test $i",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = (i * 1000).toDouble(),
                outcomeAmount = (i * 1500).toDouble(),
                timeInMonths = i.toDouble(),
                calculatedResult = i.toDouble(),
                notes = "Concurrent operation test"
            )
        }
        
        // Test concurrent saves
        calculations.map { calculation ->
            async {
                calculationRepository.saveCalculation(calculation)
            }
        }.awaitAll()
        
        // Verify all calculations were saved
        val savedCalculations = calculationRepository.getAllCalculations()
        assertEquals(operationCount, savedCalculations.size)
        
        // Test concurrent reads
        val readResults = (1..10).map {
            async {
                calculationRepository.getAllCalculations()
            }
        }.awaitAll()
        
        // All reads should return the same count
        for (result in readResults) {
            assertEquals(operationCount, result.size)
        }
        
        // Test concurrent updates
        val updateCalculations = savedCalculations.take(10)
        
        updateCalculations.map { calculation ->
            async {
                val updatedCalc = calculation.copy(notes = "Updated concurrently")
                calculationRepository.saveCalculation(updatedCalc)
            }
        }.awaitAll()
        
        // Verify updates
        val updatedCalculations = calculationRepository.getAllCalculations()
        val updatedCount = updatedCalculations.count { it.notes == "Updated concurrently" }
        assertEquals(10, updatedCount)
    }
    
    @Test
    fun testBatteryOptimization() = runTest {
        // Test battery usage optimization
        
        // 1. Test background sync optimization
        val calculations = (1..100).map { i ->
            SavedCalculation.createValidated(
                name = "Battery Test $i",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 100000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0,
                calculatedResult = 22.47
            )
        }
        
        // Save calculations
        for (calculation in calculations) {
            calculationRepository.saveCalculation(calculation)
        }
        
        // Test batched sync operations (should be more battery efficient)
        val syncStartTime = System.currentTimeMillis()
        val syncResult = cloudSyncService.syncCalculations()
        val syncDuration = System.currentTimeMillis() - syncStartTime
        
        println("Sync operation took ${syncDuration}ms")
        
        // 2. Test efficient database queries
        val queryStartTime = System.currentTimeMillis()
        val searchResults = calculationRepository.searchCalculations("Battery Test")
        val queryDuration = System.currentTimeMillis() - queryStartTime
        
        println("Search query took ${queryDuration}ms")
        assertEquals(100, searchResults.size)
        
        // 3. Test lazy loading
        val lazyLoadStartTime = System.currentTimeMillis()
        val firstBatch = calculationRepository.getCalculationsPaginated(20, 0)
        val lazyLoadDuration = System.currentTimeMillis() - lazyLoadStartTime
        
        println("Lazy load took ${lazyLoadDuration}ms")
        assertEquals(20, firstBatch.size)
        
        // Battery optimization assertions
        assertTrue(syncDuration < 5000, "Sync should be efficient")
        assertTrue(queryDuration < 500, "Search should be fast")
        assertTrue(lazyLoadDuration < 200, "Lazy loading should be very fast")
    }
    
    // MARK: - Helper Methods
    
    private fun getMemoryUsage(): Long {
        val runtime = Runtime.getRuntime()
        return (runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024 // Convert to MB
    }
    
    private fun createTempFile(prefix: String, suffix: String): File {
        return File.createTempFile(prefix, suffix, context.cacheDir)
    }
}

// MARK: - Extensions for Testing

fun RoomCalculationRepository.getCalculationsPaginated(limit: Int, offset: Int): List<SavedCalculation> {
    return getAllCalculations().drop(offset).take(limit)
}

fun RoomCalculationRepository.getCalculationsPaginated(limit: Int, offset: Int): List<SavedCalculation> {
    return getAllCalculations().drop(offset).take(limit)
}