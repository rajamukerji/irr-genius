package com.irrgenius.android

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.irrgenius.android.data.database.AppDatabase
import com.irrgenius.android.data.export.PDFExportService
import com.irrgenius.android.data.export.SharingService
import com.irrgenius.android.data.import.CSVImportService
import com.irrgenius.android.data.models.*
import com.irrgenius.android.data.repository.RoomCalculationRepository
import com.irrgenius.android.data.repository.RoomProjectRepository
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.File
import java.io.FileWriter
import java.time.LocalDateTime
import kotlin.test.*

@RunWith(RobolectricTestRunner::class)
class SaveLoadExportIntegrationTest {
    
    private lateinit var context: Context
    private lateinit var database: AppDatabase
    private lateinit var calculationRepository: RoomCalculationRepository
    private lateinit var projectRepository: RoomProjectRepository
    private lateinit var csvImportService: CSVImportService
    private lateinit var pdfExportService: PDFExportService
    private lateinit var sharingService: SharingService
    
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
        
        csvImportService = CSVImportService(context)
        pdfExportService = PDFExportService(context)
        sharingService = SharingService(context)
    }
    
    @After
    fun teardown() {
        database.close()
    }
    
    @Test
    fun testCompleteCalculationWorkflow() = runTest {
        // Given: Create a project
        val project = Project.createValidated(
            name = "Integration Test Project",
            description = "Testing complete workflow",
            color = "#007AFF"
        )
        projectRepository.insertProject(project)
        
        // When: Create and save a calculation
        val calculation = SavedCalculation.createValidated(
            name = "Integration Test Calculation",
            calculationType = CalculationMode.CALCULATE_IRR,
            projectId = project.id,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47,
            notes = "Complete workflow test"
        ).withTags(listOf("integration", "test", "workflow"))
        
        calculationRepository.saveCalculation(calculation)
        
        // Then: Load calculation back
        val loadedCalculation = calculationRepository.loadCalculation(calculation.id)
        assertNotNull(loadedCalculation)
        assertEquals(calculation.name, loadedCalculation.name)
        assertEquals(calculation.calculationType, loadedCalculation.calculationType)
        assertEquals(calculation.projectId, loadedCalculation.projectId)
        assertEquals(calculation.initialInvestment, loadedCalculation.initialInvestment)
        assertEquals(calculation.calculatedResult, loadedCalculation.calculatedResult)
        
        // Verify tags
        val tags = loadedCalculation.getTagsFromJson()
        assertEquals(3, tags.size)
        assertTrue(tags.contains("integration"))
        assertTrue(tags.contains("test"))
        assertTrue(tags.contains("workflow"))
        
        // When: Export to PDF
        val pdfResult = pdfExportService.exportCalculationToPDF(loadedCalculation)
        assertTrue(pdfResult.isSuccess)
        val pdfFile = pdfResult.getOrThrow()
        
        // Then: PDF should be created successfully
        assertTrue(pdfFile.exists())
        assertTrue(pdfFile.length() > 0)
        assertTrue(pdfFile.name.contains("Integration_Test_Calculation"))
        
        // When: Create sharing intent
        val shareResult = sharingService.shareCalculationAsPDF(loadedCalculation)
        assertTrue(shareResult.isSuccess)
        val shareIntent = shareResult.getOrThrow()
        
        // Then: Share intent should be valid
        assertEquals("android.intent.action.SEND", shareIntent.action)
        assertEquals("application/pdf", shareIntent.type)
        
        // Cleanup
        pdfFile.delete()
    }
    
    @Test
    fun testImportExportRoundTrip() = runTest {
        // Given: Create multiple calculations with different types
        val calculations = listOf(
            SavedCalculation.createValidated(
                name = "IRR Calculation",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 100000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0,
                calculatedResult = 22.47,
                notes = "IRR test calculation"
            ),
            SavedCalculation.createValidated(
                name = "Outcome Calculation",
                calculationType = CalculationMode.CALCULATE_OUTCOME,
                initialInvestment = 50000.0,
                irr = 15.0,
                timeInMonths = 12.0,
                calculatedResult = 57500.0,
                notes = "Outcome test calculation"
            ),
            SavedCalculation.createValidated(
                name = "Portfolio Investment",
                calculationType = CalculationMode.PORTFOLIO_UNIT_INVESTMENT,
                initialInvestment = 200000.0,
                unitPrice = 1000.0,
                successRate = 75.0,
                outcomePerUnit = 2500.0,
                investorShare = 80.0,
                timeInMonths = 36.0,
                calculatedResult = 18.5,
                notes = "Portfolio test calculation"
            )
        )
        
        // Save all calculations
        for (calculation in calculations) {
            calculationRepository.saveCalculation(calculation)
        }
        
        // When: Export to CSV
        val exportResult = csvImportService.exportCalculationsToCSV(calculations)
        assertTrue(exportResult.isSuccess)
        val csvFile = exportResult.getOrThrow()
        
        // Then: CSV should contain all calculations
        val csvContent = csvFile.readText()
        assertTrue(csvContent.contains("IRR Calculation"))
        assertTrue(csvContent.contains("Outcome Calculation"))
        assertTrue(csvContent.contains("Portfolio Investment"))
        assertTrue(csvContent.contains("CALCULATE_IRR"))
        assertTrue(csvContent.contains("CALCULATE_OUTCOME"))
        assertTrue(csvContent.contains("PORTFOLIO_UNIT_INVESTMENT"))
        
        // When: Clear database and import back
        database.clearAllTables()
        val importResult = csvImportService.importFromFile(csvFile.absolutePath)
        
        // Then: Import should succeed
        assertTrue(importResult.isSuccess)
        val importData = importResult.getOrThrow()
        assertEquals(3, importData.calculations.size)
        assertTrue(importData.validationErrors.isEmpty())
        
        // Verify imported calculations
        val importedCalcs = importData.calculations.sortedBy { it.name }
        
        val irrCalc = importedCalcs.find { it.name == "IRR Calculation" }
        assertNotNull(irrCalc)
        assertEquals(CalculationMode.CALCULATE_IRR, irrCalc.calculationType)
        assertEquals(100000.0, irrCalc.initialInvestment)
        assertEquals(150000.0, irrCalc.outcomeAmount)
        assertEquals(24.0, irrCalc.timeInMonths)
        assertEquals(22.47, irrCalc.calculatedResult)
        
        val outcomeCalc = importedCalcs.find { it.name == "Outcome Calculation" }
        assertNotNull(outcomeCalc)
        assertEquals(CalculationMode.CALCULATE_OUTCOME, outcomeCalc.calculationType)
        assertEquals(50000.0, outcomeCalc.initialInvestment)
        assertEquals(15.0, outcomeCalc.irr)
        assertEquals(12.0, outcomeCalc.timeInMonths)
        assertEquals(57500.0, outcomeCalc.calculatedResult)
        
        val portfolioCalc = importedCalcs.find { it.name == "Portfolio Investment" }
        assertNotNull(portfolioCalc)
        assertEquals(CalculationMode.PORTFOLIO_UNIT_INVESTMENT, portfolioCalc.calculationType)
        assertEquals(200000.0, portfolioCalc.initialInvestment)
        assertEquals(1000.0, portfolioCalc.unitPrice)
        assertEquals(75.0, portfolioCalc.successRate)
        assertEquals(2500.0, portfolioCalc.outcomePerUnit)
        assertEquals(80.0, portfolioCalc.investorShare)
        assertEquals(36.0, portfolioCalc.timeInMonths)
        assertEquals(18.5, portfolioCalc.calculatedResult)
        
        csvFile.delete()
    }
    
    @Test
    fun testProjectCalculationRelationshipWorkflow() = runTest {
        // Given: Create multiple projects
        val project1 = Project.createValidated(
            name = "Real Estate",
            description = "Real estate investments",
            color = "#34C759"
        )
        val project2 = Project.createValidated(
            name = "Stocks",
            description = "Stock market investments",
            color = "#FF9500"
        )
        
        projectRepository.insertProject(project1)
        projectRepository.insertProject(project2)
        
        // When: Create calculations for each project
        val realEstateCalcs = listOf(
            SavedCalculation.createValidated(
                name = "Property A",
                calculationType = CalculationMode.CALCULATE_IRR,
                projectId = project1.id,
                initialInvestment = 500000.0,
                outcomeAmount = 750000.0,
                timeInMonths = 60.0,
                calculatedResult = 8.45
            ),
            SavedCalculation.createValidated(
                name = "Property B",
                calculationType = CalculationMode.CALCULATE_IRR,
                projectId = project1.id,
                initialInvestment = 300000.0,
                outcomeAmount = 420000.0,
                timeInMonths = 36.0,
                calculatedResult = 11.23
            )
        )
        
        val stockCalcs = listOf(
            SavedCalculation.createValidated(
                name = "Tech Stock Portfolio",
                calculationType = CalculationMode.CALCULATE_OUTCOME,
                projectId = project2.id,
                initialInvestment = 100000.0,
                irr = 12.0,
                timeInMonths = 24.0,
                calculatedResult = 125440.0
            )
        )
        
        // Save all calculations
        for (calc in realEstateCalcs + stockCalcs) {
            calculationRepository.saveCalculation(calc)
        }
        
        // Then: Load calculations by project
        val realEstateResults = calculationRepository.loadCalculationsByProject(project1.id)
        assertEquals(2, realEstateResults.size)
        assertTrue(realEstateResults.all { it.projectId == project1.id })
        assertTrue(realEstateResults.any { it.name == "Property A" })
        assertTrue(realEstateResults.any { it.name == "Property B" })
        
        val stockResults = calculationRepository.loadCalculationsByProject(project2.id)
        assertEquals(1, stockResults.size)
        assertEquals(project2.id, stockResults[0].projectId)
        assertEquals("Tech Stock Portfolio", stockResults[0].name)
        
        // When: Calculate project statistics
        val allCalculations = calculationRepository.getAllCalculations()
        val realEstateStats = project1.calculateStatistics(allCalculations)
        val stockStats = project2.calculateStatistics(allCalculations)
        
        // Then: Statistics should be correct
        assertEquals(2, realEstateStats.totalCalculations)
        assertEquals(2, realEstateStats.completedCalculations)
        assertEquals(1.0, realEstateStats.completionRate)
        assertEquals(2, realEstateStats.calculationTypes[CalculationMode.CALCULATE_IRR])
        
        assertEquals(1, stockStats.totalCalculations)
        assertEquals(1, stockStats.completedCalculations)
        assertEquals(1.0, stockStats.completionRate)
        assertEquals(1, stockStats.calculationTypes[CalculationMode.CALCULATE_OUTCOME])
        
        // When: Export project calculations separately
        val realEstateExport = csvImportService.exportCalculationsToCSV(realEstateResults)
        val stockExport = csvImportService.exportCalculationsToCSV(stockResults)
        
        // Then: Both exports should succeed
        assertTrue(realEstateExport.isSuccess)
        assertTrue(stockExport.isSuccess)
        
        val realEstateCsv = realEstateExport.getOrThrow()
        val stockCsv = stockExport.getOrThrow()
        
        val realEstateContent = realEstateCsv.readText()
        assertTrue(realEstateContent.contains("Property A"))
        assertTrue(realEstateContent.contains("Property B"))
        assertFalse(realEstateContent.contains("Tech Stock Portfolio"))
        
        val stockContent = stockCsv.readText()
        assertTrue(stockContent.contains("Tech Stock Portfolio"))
        assertFalse(stockContent.contains("Property A"))
        assertFalse(stockContent.contains("Property B"))
        
        realEstateCsv.delete()
        stockCsv.delete()
    }
    
    @Test
    fun testErrorHandlingAndRecoveryWorkflow() = runTest {
        // Given: CSV with mixed valid and invalid data
        val csvContent = """
            Name,Type,Initial Investment,Outcome Amount,Time (Months),IRR,Notes
            "Valid Calculation","CALCULATE_IRR",100000,150000,24,,"Valid calculation"
            "","CALCULATE_IRR",100000,150000,24,,"Empty name - invalid"
            "Invalid Type","INVALID_TYPE",100000,150000,24,,"Invalid calculation type"
            "Negative Investment","CALCULATE_IRR",-1000,150000,24,,"Negative investment - invalid"
            "Missing Fields","CALCULATE_OUTCOME",100000,,,,"Missing required fields"
            "Another Valid","CALCULATE_OUTCOME",50000,,12,15,"Another valid calculation"
        """.trimIndent()
        
        val csvFile = createTempFile("error_test", ".csv")
        FileWriter(csvFile).use { it.write(csvContent) }
        
        // When: Import CSV with errors
        val importResult = csvImportService.importFromFile(csvFile.absolutePath)
        
        // Then: Import should succeed but with validation errors
        assertTrue(importResult.isSuccess)
        val importData = importResult.getOrThrow()
        
        // Should have some valid calculations
        assertTrue(importData.calculations.isNotEmpty())
        val validCalculations = importData.calculations.filter { it.isComplete }
        assertEquals(2, validCalculations.size) // "Valid Calculation" and "Another Valid"
        
        // Should have validation errors for invalid rows
        assertFalse(importData.validationErrors.isEmpty())
        assertTrue(importData.validationErrors.any { it.contains("empty") || it.contains("Empty name") })
        assertTrue(importData.validationErrors.any { it.contains("INVALID_TYPE") })
        assertTrue(importData.validationErrors.any { it.contains("positive") || it.contains("negative") })
        assertTrue(importData.validationErrors.any { it.contains("Missing required fields") })
        
        // When: Save only valid calculations
        for (calculation in validCalculations) {
            calculationRepository.saveCalculation(calculation)
        }
        
        // Then: Valid calculations should be saved successfully
        val savedCalculations = calculationRepository.getAllCalculations()
        assertEquals(2, savedCalculations.size)
        assertTrue(savedCalculations.any { it.name == "Valid Calculation" })
        assertTrue(savedCalculations.any { it.name == "Another Valid" })
        
        // When: Export saved calculations
        val exportResult = csvImportService.exportCalculationsToCSV(savedCalculations)
        assertTrue(exportResult.isSuccess)
        val exportedFile = exportResult.getOrThrow()
        
        // Then: Export should contain only valid data
        val exportedContent = exportedFile.readText()
        assertTrue(exportedContent.contains("Valid Calculation"))
        assertTrue(exportedContent.contains("Another Valid"))
        assertFalse(exportedContent.contains("INVALID_TYPE"))
        assertFalse(exportedContent.contains("-1000"))
        
        csvFile.delete()
        exportedFile.delete()
    }
    
    @Test
    fun testFollowOnInvestmentWorkflow() = runTest {
        // Given: Create calculation with follow-on investments
        val followOnInvestments = listOf(
            FollowOnInvestmentEntity(
                calculationId = "test-calc-id",
                amount = 50000.0,
                investmentType = InvestmentType.BUY,
                timingType = TimingType.RELATIVE,
                absoluteDate = null,
                relativeTime = 12.0,
                relativeTimeUnit = TimeUnit.MONTHS,
                valuationMode = ValuationMode.TAG_ALONG,
                valuationType = ValuationType.COMPUTED,
                customValuation = null,
                irr = 15.0
            ),
            FollowOnInvestmentEntity(
                calculationId = "test-calc-id",
                amount = 75000.0,
                investmentType = InvestmentType.BUY,
                timingType = TimingType.ABSOLUTE,
                absoluteDate = "2024-12-31",
                relativeTime = null,
                relativeTimeUnit = null,
                valuationMode = ValuationMode.CUSTOM,
                valuationType = ValuationType.SPECIFIED,
                customValuation = 200000.0,
                irr = null
            )
        )
        
        val calculation = SavedCalculation.createValidated(
            id = "test-calc-id",
            name = "Blended IRR with Follow-ons",
            calculationType = CalculationMode.CALCULATE_BLENDED,
            initialInvestment = 100000.0,
            outcomeAmount = 300000.0,
            timeInMonths = 36.0,
            calculatedResult = 25.8,
            notes = "Calculation with follow-on investments"
        )
        
        // When: Save calculation and follow-on investments
        calculationRepository.saveCalculation(calculation)
        for (followOn in followOnInvestments) {
            database.followOnInvestmentDao().insert(followOn)
        }
        
        // Then: Load calculation with follow-on investments
        val loadedCalculation = calculationRepository.loadCalculation(calculation.id)
        assertNotNull(loadedCalculation)
        
        val loadedFollowOns = database.followOnInvestmentDao().getByCalculationId(calculation.id)
        assertEquals(2, loadedFollowOns.size)
        
        val firstFollowOn = loadedFollowOns.find { it.amount == 50000.0 }
        assertNotNull(firstFollowOn)
        assertEquals(InvestmentType.BUY, firstFollowOn.investmentType)
        assertEquals(TimingType.RELATIVE, firstFollowOn.timingType)
        assertEquals(12.0, firstFollowOn.relativeTime)
        assertEquals(TimeUnit.MONTHS, firstFollowOn.relativeTimeUnit)
        assertEquals(ValuationMode.TAG_ALONG, firstFollowOn.valuationMode)
        assertEquals(15.0, firstFollowOn.irr)
        
        val secondFollowOn = loadedFollowOns.find { it.amount == 75000.0 }
        assertNotNull(secondFollowOn)
        assertEquals(InvestmentType.BUY, secondFollowOn.investmentType)
        assertEquals(TimingType.ABSOLUTE, secondFollowOn.timingType)
        assertEquals("2024-12-31", secondFollowOn.absoluteDate)
        assertEquals(ValuationMode.CUSTOM, secondFollowOn.valuationMode)
        assertEquals(200000.0, secondFollowOn.customValuation)
        
        // When: Export calculation (follow-on investments should be included in JSON)
        val exportResult = csvImportService.exportCalculationsToCSV(listOf(loadedCalculation))
        assertTrue(exportResult.isSuccess)
        val csvFile = exportResult.getOrThrow()
        
        // Then: CSV should contain calculation data
        val csvContent = csvFile.readText()
        assertTrue(csvContent.contains("Blended IRR with Follow-ons"))
        assertTrue(csvContent.contains("CALCULATE_BLENDED"))
        assertTrue(csvContent.contains("100000"))
        assertTrue(csvContent.contains("300000"))
        assertTrue(csvContent.contains("25.8"))
        
        csvFile.delete()
    }
    
    @Test
    fun testSearchAndFilterWorkflow() = runTest {
        // Given: Create calculations with various attributes
        val calculations = listOf(
            SavedCalculation.createValidated(
                name = "Real Estate Investment A",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 500000.0,
                outcomeAmount = 750000.0,
                timeInMonths = 60.0,
                notes = "Commercial real estate property"
            ).withTags(listOf("real-estate", "commercial", "long-term")),
            
            SavedCalculation.createValidated(
                name = "Stock Portfolio Analysis",
                calculationType = CalculationMode.CALCULATE_OUTCOME,
                initialInvestment = 100000.0,
                irr = 12.0,
                timeInMonths = 24.0,
                notes = "Diversified stock portfolio"
            ).withTags(listOf("stocks", "portfolio", "medium-term")),
            
            SavedCalculation.createValidated(
                name = "Real Estate Investment B",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 300000.0,
                outcomeAmount = 420000.0,
                timeInMonths = 36.0,
                notes = "Residential real estate flip"
            ).withTags(listOf("real-estate", "residential", "short-term")),
            
            SavedCalculation.createValidated(
                name = "Bond Investment",
                calculationType = CalculationMode.CALCULATE_INITIAL,
                outcomeAmount = 120000.0,
                irr = 8.0,
                timeInMonths = 120.0,
                notes = "Government bond investment"
            ).withTags(listOf("bonds", "government", "long-term"))
        )
        
        // Save all calculations
        for (calculation in calculations) {
            calculationRepository.saveCalculation(calculation)
        }
        
        // When: Search by name
        val realEstateResults = calculationRepository.searchCalculations("Real Estate")
        
        // Then: Should find real estate calculations
        assertEquals(2, realEstateResults.size)
        assertTrue(realEstateResults.all { it.name.contains("Real Estate") })
        
        // When: Search by notes
        val portfolioResults = calculationRepository.searchCalculations("portfolio")
        
        // Then: Should find portfolio-related calculations
        assertEquals(2, portfolioResults.size) // Stock portfolio and diversified portfolio
        assertTrue(portfolioResults.any { it.name.contains("Stock Portfolio") })
        assertTrue(portfolioResults.any { it.notes?.contains("portfolio") == true })
        
        // When: Filter by calculation type
        val allCalculations = calculationRepository.getAllCalculations()
        val irrCalculations = allCalculations.filter { it.calculationType == CalculationMode.CALCULATE_IRR }
        val outcomeCalculations = allCalculations.filter { it.calculationType == CalculationMode.CALCULATE_OUTCOME }
        val initialCalculations = allCalculations.filter { it.calculationType == CalculationMode.CALCULATE_INITIAL }
        
        // Then: Should have correct counts by type
        assertEquals(2, irrCalculations.size)
        assertEquals(1, outcomeCalculations.size)
        assertEquals(1, initialCalculations.size)
        
        // When: Filter by investment amount range
        val largeInvestments = allCalculations.filter { 
            (it.initialInvestment ?: 0.0) >= 300000.0 
        }
        val smallInvestments = allCalculations.filter { 
            (it.initialInvestment ?: 0.0) < 300000.0 && (it.initialInvestment ?: 0.0) > 0.0
        }
        
        // Then: Should have correct counts by investment size
        assertEquals(2, largeInvestments.size) // Real Estate A and B
        assertEquals(1, smallInvestments.size) // Stock Portfolio
        
        // When: Export filtered results
        val largeInvestmentExport = csvImportService.exportCalculationsToCSV(largeInvestments)
        assertTrue(largeInvestmentExport.isSuccess)
        val exportFile = largeInvestmentExport.getOrThrow()
        
        // Then: Export should contain only large investments
        val exportContent = exportFile.readText()
        assertTrue(exportContent.contains("Real Estate Investment A"))
        assertTrue(exportContent.contains("Real Estate Investment B"))
        assertFalse(exportContent.contains("Stock Portfolio Analysis"))
        assertFalse(exportContent.contains("Bond Investment"))
        
        exportFile.delete()
    }
    
    private fun createTempFile(prefix: String, suffix: String): File {
        return File.createTempFile(prefix, suffix, context.cacheDir)
    }
}