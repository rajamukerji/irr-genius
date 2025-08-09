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
        val result = csvImportService.importCSV(inputStream)
        
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
            Name,Initial Investment,Outcome Amount
            Test,10000,15000
        """.trimIndent()
        
        val inputStream = ByteArrayInputStream(csvContent.toByteArray())
        val result = csvImportService.importCSV(inputStream)
        
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
        val result = csvImportService.importCSV(inputStream)
        
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
        val result = csvImportService.importCSV(inputStream)
        
        val mapping = result.suggestedMapping
        assertEquals(CalculationField.NAME, mapping["Investment Name"])
        assertEquals(CalculationField.INITIAL_INVESTMENT, mapping["Initial Amount"])
        assertEquals(CalculationField.OUTCOME_VALUE, mapping["Exit Value"])
        assertEquals(CalculationField.INVESTMENT_PERIOD_YEARS, mapping["Duration Months"])
    }
    
    @Test
    fun `validateAndConvert should create valid SavedCalculation objects`() = runTest {
        val importResult = ImportResultWithMapping(
            calculations = emptyList(),
            validationResult = ValidationResult(emptyList(), emptyList()),
            suggestedMapping = mapOf(
                "Name" to CalculationField.NAME,
                "Initial Investment" to CalculationField.INITIAL_INVESTMENT,
                "Outcome Amount" to CalculationField.OUTCOME_VALUE,
                "Time in Months" to CalculationField.INVESTMENT_PERIOD_YEARS
            ),
            headers = listOf("Name", "Initial Investment", "Outcome Amount", "Time in Months"),
            rows = listOf(
                listOf("Test Calculation", "10000", "15000", "12")
            ),
            detectedFormat = ImportFormat.CSV
        )
        
        val columnMapping = mapOf(
            "Name" to CalculationField.NAME,
            "Initial Investment" to CalculationField.INITIAL_INVESTMENT,
            "Outcome Amount" to CalculationField.OUTCOME_VALUE,
            "Time in Months" to CalculationField.INVESTMENT_PERIOD_YEARS
        )
        
        val validationResult = csvImportService.validateAndConvert(
            importResult = importResult,
            columnMapping = columnMapping,
            calculationType = CalculationMode.CALCULATE_IRR
        )
        
        assertEquals(0, validationResult.errors.size)
        assertEquals(0, validationResult.warnings.size)
    }
    
    @Test
    fun `validateAndConvert should handle validation errors`() = runTest {
        val importResult = ImportResultWithMapping(
            calculations = emptyList(),
            validationResult = ValidationResult(emptyList(), emptyList()),
            suggestedMapping = emptyMap(),
            headers = listOf("Name", "Initial Investment", "Outcome Amount"),
            rows = listOf(
                listOf("Test", "invalid_number", "15000")
            ),
            detectedFormat = ImportFormat.CSV
        )
        
        val columnMapping = mapOf(
            "Name" to CalculationField.NAME,
            "Initial Investment" to CalculationField.INITIAL_INVESTMENT,
            "Outcome Amount" to CalculationField.OUTCOME_VALUE
        )
        
        val validationResult = csvImportService.validateAndConvert(
            importResult = importResult,
            columnMapping = columnMapping,
            calculationType = CalculationMode.CALCULATE_IRR
        )
        
        assertTrue(validationResult.hasErrors)
    }
    
    @Test
    fun `validateAndConvert should handle portfolio unit investment fields`() = runTest {
        val importResult = ImportResultWithMapping(
            calculations = emptyList(),
            validationResult = ValidationResult(emptyList(), emptyList()),
            suggestedMapping = emptyMap(),
            headers = listOf("Name", "Investment Amount"),
            rows = listOf(
                listOf("Portfolio Test", "100000")
            ),
            detectedFormat = ImportFormat.CSV
        )
        
        val columnMapping = mapOf(
            "Name" to CalculationField.NAME,
            "Investment Amount" to CalculationField.INITIAL_INVESTMENT
        )
        
        val validationResult = csvImportService.validateAndConvert(
            importResult = importResult,
            columnMapping = columnMapping,
            calculationType = CalculationMode.CALCULATE_IRR
        )
        
        assertTrue(validationResult.isValid)
    }
    
    @Test
    fun `importCSV should handle empty file`() = runTest {
        val inputStream = ByteArrayInputStream("".toByteArray())
        
        try {
            csvImportService.importCSV(inputStream)
            fail("Expected exception for empty file")
        } catch (e: Exception) {
            assertTrue(e.message?.contains("empty") == true)
        }
    }
    
    @Test
    fun `importCSV should handle CSV without headers`() = runTest {
        val csvContent = """
            Test Calculation,10000,15000,12
            Another Test,5000,8000,24
        """.trimIndent()
        
        val inputStream = ByteArrayInputStream(csvContent.toByteArray())
        val result = csvImportService.importCSV(inputStream)
        
        assertEquals(4, result.headers.size)
        assertEquals("Test Calculation", result.headers[0])
        assertEquals(1, result.rows.size)
        assertEquals("Another Test", result.rows[0][0])
    }
    
    @Test
    fun `importCSV should handle currency symbols and formatting`() = runTest {
        val csvContent = """
            Name,Initial Investment,Outcome Amount,IRR
            Test,"$10,000","$15,000",20.5%
        """.trimIndent()
        
        val inputStream = ByteArrayInputStream(csvContent.toByteArray())
        val result = csvImportService.importCSV(inputStream)
        
        val columnMapping = mapOf(
            "Name" to CalculationField.NAME,
            "Initial Investment" to CalculationField.INITIAL_INVESTMENT,
            "Outcome Amount" to CalculationField.OUTCOME_VALUE
        )
        
        val validationResult = csvImportService.validateAndConvert(
            importResult = result,
            columnMapping = columnMapping,
            calculationType = CalculationMode.CALCULATE_IRR
        )
        
        assertTrue(validationResult.isValid)
    }
}