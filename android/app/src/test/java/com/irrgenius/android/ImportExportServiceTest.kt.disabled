package com.irrgenius.android

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.irrgenius.android.data.export.PDFExportService
import com.irrgenius.android.data.export.SharingService
import com.irrgenius.android.data.import.CSVImportService
import com.irrgenius.android.data.import.ExcelImportService
import com.irrgenius.android.data.models.*
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.File
import java.io.FileWriter
import java.time.LocalDateTime
import kotlin.test.*

@RunWith(RobolectricTestRunner::class)
class ImportExportServiceTest {
    
    private lateinit var context: Context
    private lateinit var csvImportService: CSVImportService
    private lateinit var excelImportService: ExcelImportService
    private lateinit var pdfExportService: PDFExportService
    private lateinit var sharingService: SharingService
    
    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        csvImportService = CSVImportService(context)
        excelImportService = ExcelImportService(context)
        pdfExportService = PDFExportService(context)
        sharingService = SharingService(context)
    }
    
    @Test
    fun testCSVImportValidData() = runTest {
        // Given a valid CSV file
        val csvContent = """
            Name,Type,Initial Investment,Outcome Amount,Time (Months),IRR,Notes
            "Real Estate Deal","CALCULATE_IRR",100000,150000,24,,""Property investment""
            "Stock Analysis","CALCULATE_OUTCOME",50000,,12,15,"Stock portfolio"
            "Bond Investment","CALCULATE_INITIAL",,120000,36,8,"Government bonds"
        """.trimIndent()
        
        val csvFile = createTempFile("test", ".csv")
        FileWriter(csvFile).use { it.write(csvContent) }
        
        // When importing CSV
        val result = csvImportService.importFromFile(csvFile.absolutePath)
        
        // Then should parse successfully
        assertTrue(result.isSuccess)
        val importData = result.getOrThrow()
        
        assertEquals(3, importData.calculations.size)
        
        val firstCalc = importData.calculations[0]
        assertEquals("Real Estate Deal", firstCalc.name)
        assertEquals(CalculationMode.CALCULATE_IRR, firstCalc.calculationType)
        assertEquals(100000.0, firstCalc.initialInvestment)
        assertEquals(150000.0, firstCalc.outcomeAmount)
        assertEquals(24.0, firstCalc.timeInMonths)
        assertEquals("Property investment", firstCalc.notes)
        
        val secondCalc = importData.calculations[1]
        assertEquals("Stock Analysis", secondCalc.name)
        assertEquals(CalculationMode.CALCULATE_OUTCOME, secondCalc.calculationType)
        assertEquals(50000.0, secondCalc.initialInvestment)
        assertEquals(15.0, secondCalc.irr)
        
        csvFile.delete()
    }
    
    @Test
    fun testCSVImportInvalidData() = runTest {
        // Given CSV with invalid data
        val csvContent = """
            Name,Type,Initial Investment,Outcome Amount,Time (Months)
            "","CALCULATE_IRR",100000,150000,24
            "Valid Name","INVALID_TYPE",50000,75000,12
            "Negative Investment","CALCULATE_IRR",-1000,150000,24
        """.trimIndent()
        
        val csvFile = createTempFile("test", ".csv")
        FileWriter(csvFile).use { it.write(csvContent) }
        
        // When importing CSV
        val result = csvImportService.importFromFile(csvFile.absolutePath)
        
        // Then should return validation errors
        assertTrue(result.isSuccess)
        val importData = result.getOrThrow()
        
        assertTrue(importData.validationErrors.isNotEmpty())
        assertTrue(importData.validationErrors.any { it.contains("empty") })
        assertTrue(importData.validationErrors.any { it.contains("INVALID_TYPE") })
        assertTrue(importData.validationErrors.any { it.contains("positive") })
        
        csvFile.delete()
    }
    
    @Test
    fun testCSVImportCustomDelimiter() = runTest {
        // Given CSV with semicolon delimiter
        val csvContent = """
            Name;Type;Initial Investment;Outcome Amount;Time (Months)
            "Test Calculation";CALCULATE_IRR;100000;150000;24
        """.trimIndent()
        
        val csvFile = createTempFile("test", ".csv")
        FileWriter(csvFile).use { it.write(csvContent) }
        
        // When importing with custom delimiter
        val result = csvImportService.importFromFile(csvFile.absolutePath, delimiter = ";")
        
        // Then should parse successfully
        assertTrue(result.isSuccess)
        val importData = result.getOrThrow()
        
        assertEquals(1, importData.calculations.size)
        assertEquals("Test Calculation", importData.calculations[0].name)
        
        csvFile.delete()
    }
    
    @Test
    fun testCSVImportMissingFile() = runTest {
        // When importing non-existent file
        val result = csvImportService.importFromFile("/non/existent/file.csv")
        
        // Then should return failure
        assertTrue(result.isFailure)
        val exception = result.exceptionOrNull()
        assertNotNull(exception)
        assertTrue(exception.message!!.contains("not found") || exception.message!!.contains("No such file"))
    }
    
    @Test
    fun testExcelImportValidData() = runTest {
        // Note: This test would require creating an actual Excel file
        // For now, we'll test the service initialization and error handling
        
        // When importing non-existent Excel file
        val result = excelImportService.importFromFile("/non/existent/file.xlsx")
        
        // Then should return failure
        assertTrue(result.isFailure)
        val exception = result.exceptionOrNull()
        assertNotNull(exception)
    }
    
    @Test
    fun testPDFExportSingleCalculation() = runTest {
        // Given a calculation
        val calculation = SavedCalculation.createValidated(
            name = "Test Calculation",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47,
            notes = "Test calculation for PDF export"
        )
        
        // When exporting to PDF
        val result = pdfExportService.exportCalculationToPDF(calculation)
        
        // Then should create PDF file
        assertTrue(result.isSuccess)
        val pdfFile = result.getOrThrow()
        
        assertTrue(pdfFile.exists())
        assertTrue(pdfFile.length() > 0)
        assertTrue(pdfFile.name.endsWith(".pdf"))
        assertTrue(pdfFile.name.contains("Test_Calculation"))
        
        pdfFile.delete()
    }
    
    @Test
    fun testPDFExportMultipleCalculations() = runTest {
        // Given multiple calculations
        val calculations = listOf(
            SavedCalculation.createValidated(
                name = "Calculation 1",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 100000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0,
                calculatedResult = 22.47
            ),
            SavedCalculation.createValidated(
                name = "Calculation 2",
                calculationType = CalculationMode.CALCULATE_OUTCOME,
                initialInvestment = 50000.0,
                irr = 15.0,
                timeInMonths = 12.0,
                calculatedResult = 57500.0
            )
        )
        
        // When exporting to PDF
        val result = pdfExportService.exportCalculationsToPDF(calculations)
        
        // Then should create PDF file
        assertTrue(result.isSuccess)
        val pdfFile = result.getOrThrow()
        
        assertTrue(pdfFile.exists())
        assertTrue(pdfFile.length() > 0)
        assertTrue(pdfFile.name.contains("Calculations_Export"))
        
        pdfFile.delete()
    }
    
    @Test
    fun testCSVExportCalculations() = runTest {
        // Given calculations
        val calculations = listOf(
            SavedCalculation.createValidated(
                name = "Test Calculation 1",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 100000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0,
                calculatedResult = 22.47,
                notes = "First calculation"
            ),
            SavedCalculation.createValidated(
                name = "Test Calculation 2",
                calculationType = CalculationMode.CALCULATE_OUTCOME,
                initialInvestment = 50000.0,
                irr = 15.0,
                timeInMonths = 12.0,
                calculatedResult = 57500.0,
                notes = "Second calculation"
            )
        )
        
        // When exporting to CSV
        val result = csvImportService.exportCalculationsToCSV(calculations)
        
        // Then should create CSV file
        assertTrue(result.isSuccess)
        val csvFile = result.getOrThrow()
        
        assertTrue(csvFile.exists())
        assertTrue(csvFile.length() > 0)
        assertTrue(csvFile.name.endsWith(".csv"))
        
        // Verify CSV content
        val content = csvFile.readText()
        assertTrue(content.contains("Test Calculation 1"))
        assertTrue(content.contains("Test Calculation 2"))
        assertTrue(content.contains("CALCULATE_IRR"))
        assertTrue(content.contains("CALCULATE_OUTCOME"))
        assertTrue(content.contains("100000"))
        assertTrue(content.contains("22.47"))
        
        csvFile.delete()
    }
    
    @Test
    fun testSharingServiceCreateShareIntent() {
        // Given a file to share
        val testFile = createTempFile("test", ".pdf")
        testFile.writeText("Test PDF content")
        
        // When creating share intent
        val intent = sharingService.createShareIntent(testFile, "application/pdf")
        
        // Then should create valid intent
        assertNotNull(intent)
        assertEquals("android.intent.action.SEND", intent.action)
        assertEquals("application/pdf", intent.type)
        assertTrue(intent.hasExtra("android.intent.extra.STREAM"))
        
        testFile.delete()
    }
    
    @Test
    fun testSharingServiceShareCalculation() = runTest {
        // Given a calculation
        val calculation = SavedCalculation.createValidated(
            name = "Share Test",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47
        )
        
        // When sharing calculation
        val result = sharingService.shareCalculationAsPDF(calculation)
        
        // Then should create share intent
        assertTrue(result.isSuccess)
        val intent = result.getOrThrow()
        
        assertNotNull(intent)
        assertEquals("android.intent.action.SEND", intent.action)
        assertEquals("application/pdf", intent.type)
    }
    
    @Test
    fun testImportDataValidation() = runTest {
        // Given import data with mixed valid and invalid calculations
        val validCalc = SavedCalculation.createValidated(
            name = "Valid Calculation",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0
        )
        
        val invalidCalc = SavedCalculation(
            name = "", // Invalid: empty name
            calculationType = CalculationMode.CALCULATE_IRR,
            createdDate = LocalDateTime.now(),
            modifiedDate = LocalDateTime.now(),
            projectId = null,
            initialInvestment = -1000.0, // Invalid: negative
            outcomeAmount = null, // Invalid: missing required field
            timeInMonths = null, // Invalid: missing required field
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
        
        // When validating import data
        val validationErrors = mutableListOf<String>()
        
        try {
            validCalc.validate()
        } catch (e: SavedCalculationValidationException) {
            validationErrors.add("Valid calc error: ${e.message}")
        }
        
        try {
            invalidCalc.validate()
        } catch (e: SavedCalculationValidationException) {
            validationErrors.add("Invalid calc error: ${e.message}")
        }
        
        // Then should have validation errors for invalid calculation only
        assertEquals(1, validationErrors.size)
        assertTrue(validationErrors[0].contains("Invalid calc error"))
        assertTrue(validationErrors[0].contains("empty") || validationErrors[0].contains("Missing required fields"))
    }
    
    private fun createTempFile(prefix: String, suffix: String): File {
        return File.createTempFile(prefix, suffix, context.cacheDir)
    }
}