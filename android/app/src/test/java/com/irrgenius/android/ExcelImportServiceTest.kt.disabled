package com.irrgenius.android

import com.irrgenius.android.data.import.*
import com.irrgenius.android.data.models.CalculationMode
import kotlinx.coroutines.test.runTest
import org.apache.poi.hssf.usermodel.HSSFWorkbook
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import org.junit.Test
import org.junit.Assert.*
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class ExcelImportServiceTest {
    
    private val excelImportService = ExcelImportService()
    
    @Test
    fun `importExcel should parse basic XLSX with headers`() = runTest {
        val workbook = XSSFWorkbook()
        val sheet = workbook.createSheet("Test Sheet")
        
        // Create header row
        val headerRow = sheet.createRow(0)
        headerRow.createCell(0).setCellValue("Name")
        headerRow.createCell(1).setCellValue("Initial Investment")
        headerRow.createCell(2).setCellValue("Outcome Amount")
        headerRow.createCell(3).setCellValue("Time in Months")
        headerRow.createCell(4).setCellValue("IRR")
        
        // Create data rows
        val dataRow1 = sheet.createRow(1)
        dataRow1.createCell(0).setCellValue("Test Calculation 1")
        dataRow1.createCell(1).setCellValue(10000.0)
        dataRow1.createCell(2).setCellValue(15000.0)
        dataRow1.createCell(3).setCellValue(12.0)
        dataRow1.createCell(4).setCellValue(20.5)
        
        val dataRow2 = sheet.createRow(2)
        dataRow2.createCell(0).setCellValue("Test Calculation 2")
        dataRow2.createCell(1).setCellValue(5000.0)
        dataRow2.createCell(2).setCellValue(8000.0)
        dataRow2.createCell(3).setCellValue(24.0)
        dataRow2.createCell(4).setCellValue(15.2)
        
        val outputStream = ByteArrayOutputStream()
        workbook.write(outputStream)
        workbook.close()
        
        val inputStream = ByteArrayInputStream(outputStream.toByteArray())
        val result = excelImportService.importExcel(inputStream, "test.xlsx", hasHeaders = true)
        
        assertEquals(5, result.headers.size)
        assertEquals("Name", result.headers[0])
        assertEquals("Initial Investment", result.headers[1])
        assertEquals(2, result.rows.size)
        assertEquals("Test Calculation 1", result.rows[0][0])
        assertEquals("10000", result.rows[0][1])
    }
    
    @Test
    fun `importExcel should parse basic XLS with headers`() = runTest {
        val workbook = HSSFWorkbook()
        val sheet = workbook.createSheet("Test Sheet")
        
        // Create header row
        val headerRow = sheet.createRow(0)
        headerRow.createCell(0).setCellValue("Name")
        headerRow.createCell(1).setCellValue("Initial Investment")
        headerRow.createCell(2).setCellValue("Outcome Amount")
        
        // Create data row
        val dataRow = sheet.createRow(1)
        dataRow.createCell(0).setCellValue("Test Calculation")
        dataRow.createCell(1).setCellValue(10000.0)
        dataRow.createCell(2).setCellValue(15000.0)
        
        val outputStream = ByteArrayOutputStream()
        workbook.write(outputStream)
        workbook.close()
        
        val inputStream = ByteArrayInputStream(outputStream.toByteArray())
        val result = excelImportService.importExcel(inputStream, "test.xls", hasHeaders = true)
        
        assertEquals(3, result.headers.size)
        assertEquals("Name", result.headers[0])
        assertEquals(1, result.rows.size)
        assertEquals("Test Calculation", result.rows[0][0])
    }
    
    @Test
    fun `importExcel should suggest correct column mappings`() = runTest {
        val workbook = XSSFWorkbook()
        val sheet = workbook.createSheet("Test Sheet")
        
        val headerRow = sheet.createRow(0)
        headerRow.createCell(0).setCellValue("Investment Name")
        headerRow.createCell(1).setCellValue("Initial Amount")
        headerRow.createCell(2).setCellValue("Exit Value")
        headerRow.createCell(3).setCellValue("Duration Months")
        headerRow.createCell(4).setCellValue("Return Rate")
        
        val dataRow = sheet.createRow(1)
        dataRow.createCell(0).setCellValue("Test")
        dataRow.createCell(1).setCellValue(10000.0)
        dataRow.createCell(2).setCellValue(15000.0)
        dataRow.createCell(3).setCellValue(12.0)
        dataRow.createCell(4).setCellValue(20.5)
        
        val outputStream = ByteArrayOutputStream()
        workbook.write(outputStream)
        workbook.close()
        
        val inputStream = ByteArrayInputStream(outputStream.toByteArray())
        val result = excelImportService.importExcel(inputStream, "test.xlsx", hasHeaders = true)
        
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
            detectedFormat = ImportFormat.Excel("Sheet1", true),
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
        
        val validationResult = excelImportService.validateAndConvert(
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
    fun `importExcel should handle numeric and formula cells`() = runTest {
        val workbook = XSSFWorkbook()
        val sheet = workbook.createSheet("Test Sheet")
        
        val headerRow = sheet.createRow(0)
        headerRow.createCell(0).setCellValue("Name")
        headerRow.createCell(1).setCellValue("Investment")
        headerRow.createCell(2).setCellValue("Calculated Value")
        
        val dataRow = sheet.createRow(1)
        dataRow.createCell(0).setCellValue("Test")
        dataRow.createCell(1).setCellValue(10000.0)
        // Create a formula cell
        dataRow.createCell(2).setCellFormula("B2*1.5")
        
        val outputStream = ByteArrayOutputStream()
        workbook.write(outputStream)
        workbook.close()
        
        val inputStream = ByteArrayInputStream(outputStream.toByteArray())
        val result = excelImportService.importExcel(inputStream, "test.xlsx", hasHeaders = true)
        
        assertEquals(3, result.headers.size)
        assertEquals(1, result.rows.size)
        assertEquals("Test", result.rows[0][0])
        assertEquals("10000", result.rows[0][1])
        // Formula should be evaluated or return empty string
        assertNotNull(result.rows[0][2])
    }
    
    @Test
    fun `importExcel should handle empty cells`() = runTest {
        val workbook = XSSFWorkbook()
        val sheet = workbook.createSheet("Test Sheet")
        
        val headerRow = sheet.createRow(0)
        headerRow.createCell(0).setCellValue("Name")
        headerRow.createCell(1).setCellValue("Investment")
        headerRow.createCell(2).setCellValue("Notes")
        
        val dataRow = sheet.createRow(1)
        dataRow.createCell(0).setCellValue("Test")
        dataRow.createCell(1).setCellValue(10000.0)
        // Cell 2 is intentionally left empty
        
        val outputStream = ByteArrayOutputStream()
        workbook.write(outputStream)
        workbook.close()
        
        val inputStream = ByteArrayInputStream(outputStream.toByteArray())
        val result = excelImportService.importExcel(inputStream, "test.xlsx", hasHeaders = true)
        
        assertEquals(3, result.headers.size)
        assertEquals(1, result.rows.size)
        assertEquals("Test", result.rows[0][0])
        assertEquals("10000", result.rows[0][1])
        assertEquals("", result.rows[0][2]) // Empty cell should return empty string
    }
    
    @Test
    fun `getSheetNames should return available sheets`() = runTest {
        val workbook = XSSFWorkbook()
        workbook.createSheet("Sheet1")
        workbook.createSheet("Data")
        workbook.createSheet("Summary")
        
        val outputStream = ByteArrayOutputStream()
        workbook.write(outputStream)
        workbook.close()
        
        val inputStream = ByteArrayInputStream(outputStream.toByteArray())
        val sheetNames = excelImportService.getSheetNames(inputStream, "test.xlsx")
        
        assertEquals(3, sheetNames.size)
        assertTrue(sheetNames.contains("Sheet1"))
        assertTrue(sheetNames.contains("Data"))
        assertTrue(sheetNames.contains("Summary"))
    }
    
    @Test
    fun `importExcel should handle unsupported file format`() = runTest {
        val inputStream = ByteArrayInputStream("not an excel file".toByteArray())
        
        try {
            excelImportService.importExcel(inputStream, "test.txt")
            fail("Expected ImportException")
        } catch (e: ImportException) {
            assertTrue(e.message?.contains("Unsupported file format") == true)
        }
    }
    
    @Test
    fun `importExcelWithRange should extract specified range`() = runTest {
        val workbook = XSSFWorkbook()
        val sheet = workbook.createSheet("Test Sheet")
        
        // Create a 5x5 grid of data
        for (row in 0..4) {
            val excelRow = sheet.createRow(row)
            for (col in 0..4) {
                excelRow.createCell(col).setCellValue("R${row}C${col}")
            }
        }
        
        val outputStream = ByteArrayOutputStream()
        workbook.write(outputStream)
        workbook.close()
        
        val inputStream = ByteArrayInputStream(outputStream.toByteArray())
        val result = excelImportService.importExcelWithRange(
            inputStream = inputStream,
            fileName = "test.xlsx",
            startRow = 1,
            endRow = 3,
            startColumn = 1,
            endColumn = 3,
            hasHeaders = false
        )
        
        assertEquals(3, result.headers.size) // Columns 1-3
        assertEquals(3, result.rows.size) // Rows 1-3
        assertEquals("R1C1", result.rows[0][0])
        assertEquals("R1C3", result.rows[0][2])
        assertEquals("R3C1", result.rows[2][0])
    }
}