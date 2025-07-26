package com.irrgenius.android

import com.irrgenius.android.data.import.*
import com.irrgenius.android.data.models.CalculationMode
import kotlinx.coroutines.test.runTest
import org.junit.Test
import org.junit.Assert.*
import java.io.ByteArrayInputStream

class CSVImportServiceTest {
    
    private val csvImportService = CSVImportService()
    
    @Test
    fun `importCSV should parse basic CSV with headers`() = runTest {
        val csvContent = """
            Name,Initial Investment,Outcome Amount,Time in Months,IRR
            Test Calculation 1,10000,15000,12,20.5
            Test Calculation 2,5000,8000,24,15.2
        """.trimIndent()
        
        val inputStream = ByteArrayInputStream(csvContent.toByteArray())
        val result = csvImportService.importCSV(inputStream, hasHeaders = true)
        
        assertEquals(5, result.headers.size)
        assertEquals("Name", result.headers[0])
        assertEquals("Initial Investment", result.headers[1])
        assertEquals(2, result.rows.size)
        assertEquals("Test Calculation 1", result.rows[0][0])
        assertEquals("10000", result.rows[0][1])
    }
    
    @Test
    fun `importCSV should handle different delimiters`() = runTest {
        val csvContent = """
            Name;Initial Investment;Outcome Amount
            Test;10000;15000
        """.trimIndent()
        
        val inputStream = ByteArrayInputStream(csvContent.toByteArray())
        val result = csvImportService.importCSV(inputStream, delimiter = ';', hasHeaders = true)
        
        assertEquals(3, result.headers.size)
        assertEquals(1, result.rows.size)
        assertEquals("Test", result.rows[0][0])
    }
    
    @Test
    fun `importCSV should handle quoted values with commas`() = runTest {
        val csvContent = """
            Name,Notes
            "Test, with comma","This is a note, with comma"
        """.trimIndent()
        
        val inputStream = ByteArrayInputStream(csvContent.toByteArray())
        val result = csvImportService.importCSV(inputStream, hasHeaders = true)
        
        assertEquals("Test, with comma", result.rows[0][0])
        assertEquals("This is a note, with comma", result.rows[0][1])
    }
    
    @Test
    fun `importCSV should suggest correct column mappings`() = runTest {
        val csvContent = """
            Investment Name,Initial Amount,Exit Value,Duration Months,Return Rate
            Test,10000,15000,12,20.5
        """.trimIndent()
        
        val inputStream = ByteArrayInputStream(csvContent.toByteArray())
        val result = csvImportService.importCSV(inputStream, hasHeaders = true)
        
        val mapping = result.suggestedMapping
        assertEquals(CalculationField.NAME, mapping["Investment Name"])
        assertEquals(CalculationField.INITIAL_INVESTMENT, mapping["Initial Amount"])
        assertEquals(CalculationField.OUTCOME_AMOUNT, mapping["Exit Value"])
        assertEquals(CalculationField.TIME_IN_MONTHS, mapping["Duration Months"])
        assertEquals(CalculationField.IRR, mapping["Return Rate"])
    }
    
    @Test
    fun `validateAndConvert should create valid SavedCalculation objects`() = runTest {
        val importResult = ImportResult(
            headers = listOf("Name", "Initial Investment", "Outcome Amount", "Time in Months"),
            rows = listOf(
                listOf("Test Calculation", "10000", "15000", "12")
            ),
            detectedFormat = ImportFormat.CSV(',', true),
            suggestedMapping = mapOf(
                "Name" to CalculationField.NAME,
                "Initial Investment" to CalculationField.INITIAL_INVESTMENT,
                "Outcome Amount" to CalculationField.OUTCOME_AMOUNT,
                "Time in Months" to CalculationField.TIME_IN_MONTHS
            ),
            validationErrors = emptyList()
        )
        
        val columnMapping = mapOf(
            "Name" to CalculationField.NAME,
            "Initial Investment" to CalculationField.INITIAL_INVESTMENT,
            "Outcome Amount" to CalculationField.OUTCOME_AMOUNT,
            "Time in Months" to CalculationField.TIME_IN_MONTHS
        )
        
        val validationResult = csvImportService.validateAndConvert(
            importResult = importResult,
            columnMapping = columnMapping,
            calculationType = CalculationMode.CALCULATE_IRR
        )
        
        assertEquals(1, validationResult.validCalculations.size)
        assertEquals(0, validationResult.validationErrors.size)
        
        val calculation = validationResult.validCalculations[0]
        assertEquals("Test Calculation", calculation.name)
        assertEquals(10000.0, calculation.initialInvestment)
        assertEquals(15000.0, calculation.outcomeAmount)
        assertEquals(12.0, calculation.timeInMonths)
        assertEquals(CalculationMode.CALCULATE_IRR, calculation.calculationType)
    }
    
    @Test
    fun `validateAndConvert should handle validation errors`() = runTest {
        val importResult = ImportResult(
            headers = listOf("Name", "Initial Investment", "Outcome Amount"),
            rows = listOf(
                listOf("Test", "invalid_number", "15000")
            ),
            detectedFormat = ImportFormat.CSV(',', true),
            suggestedMapping = emptyMap(),
            validationErrors = emptyList()
        )
        
        val columnMapping = mapOf(
            "Name" to CalculationField.NAME,
            "Initial Investment" to CalculationField.INITIAL_INVESTMENT,
            "Outcome Amount" to CalculationField.OUTCOME_AMOUNT
        )
        
        val validationResult = csvImportService.validateAndConvert(
            importResult = importResult,
            columnMapping = columnMapping,
            calculationType = CalculationMode.CALCULATE_IRR
        )
        
        assertEquals(0, validationResult.validCalculations.size)
        assertEquals(1, validationResult.validationErrors.size)
        assertTrue(validationResult.validationErrors[0].message.contains("Invalid number format"))
    }
    
    @Test
    fun `validateAndConvert should handle portfolio unit investment fields`() = runTest {
        val importResult = ImportResult(
            headers = listOf("Name", "Investment Amount", "Unit Price", "Success Rate", "Outcome Per Unit", "Investor Share", "Time in Months"),
            rows = listOf(
                listOf("Portfolio Test", "100000", "1000", "75", "2500", "80", "36")
            ),
            detectedFormat = ImportFormat.CSV(',', true),
            suggestedMapping = emptyMap(),
            validationErrors = emptyList()
        )
        
        val columnMapping = mapOf(
            "Name" to CalculationField.NAME,
            "Investment Amount" to CalculationField.INITIAL_INVESTMENT,
            "Unit Price" to CalculationField.UNIT_PRICE,
            "Success Rate" to CalculationField.SUCCESS_RATE,
            "Outcome Per Unit" to CalculationField.OUTCOME_PER_UNIT,
            "Investor Share" to CalculationField.INVESTOR_SHARE,
            "Time in Months" to CalculationField.TIME_IN_MONTHS
        )
        
        val validationResult = csvImportService.validateAndConvert(
            importResult = importResult,
            columnMapping = columnMapping,
            calculationType = CalculationMode.PORTFOLIO_UNIT_INVESTMENT
        )
        
        assertEquals(1, validationResult.validCalculations.size)
        assertEquals(0, validationResult.validationErrors.size)
        
        val calculation = validationResult.validCalculations[0]
        assertEquals("Portfolio Test", calculation.name)
        assertEquals(100000.0, calculation.initialInvestment)
        assertEquals(1000.0, calculation.unitPrice)
        assertEquals(75.0, calculation.successRate)
        assertEquals(2500.0, calculation.outcomePerUnit)
        assertEquals(80.0, calculation.investorShare)
        assertEquals(36.0, calculation.timeInMonths)
    }
    
    @Test
    fun `importCSV should handle empty file`() = runTest {
        val inputStream = ByteArrayInputStream("".toByteArray())
        
        try {
            csvImportService.importCSV(inputStream)
            fail("Expected ImportException")
        } catch (e: ImportException) {
            assertTrue(e.message?.contains("File is empty") == true)
        }
    }
    
    @Test
    fun `importCSV should handle CSV without headers`() = runTest {
        val csvContent = """
            Test Calculation,10000,15000,12
            Another Test,5000,8000,24
        """.trimIndent()
        
        val inputStream = ByteArrayInputStream(csvContent.toByteArray())
        val result = csvImportService.importCSV(inputStream, hasHeaders = false)
        
        assertEquals(4, result.headers.size)
        assertEquals("Column 1", result.headers[0])
        assertEquals("Column 2", result.headers[1])
        assertEquals(2, result.rows.size)
        assertEquals("Test Calculation", result.rows[0][0])
    }
    
    @Test
    fun `importCSV should handle currency symbols and formatting`() = runTest {
        val csvContent = """
            Name,Initial Investment,Outcome Amount,IRR
            Test,"$10,000","$15,000",20.5%
        """.trimIndent()
        
        val inputStream = ByteArrayInputStream(csvContent.toByteArray())
        val result = csvImportService.importCSV(inputStream, hasHeaders = true)
        
        val columnMapping = mapOf(
            "Name" to CalculationField.NAME,
            "Initial Investment" to CalculationField.INITIAL_INVESTMENT,
            "Outcome Amount" to CalculationField.OUTCOME_AMOUNT,
            "IRR" to CalculationField.IRR
        )
        
        val validationResult = csvImportService.validateAndConvert(
            importResult = result,
            columnMapping = columnMapping,
            calculationType = CalculationMode.CALCULATE_IRR
        )
        
        assertEquals(1, validationResult.validCalculations.size)
        val calculation = validationResult.validCalculations[0]
        assertEquals(10000.0, calculation.initialInvestment)
        assertEquals(15000.0, calculation.outcomeAmount)
        assertEquals(20.5, calculation.irr)
    }
}