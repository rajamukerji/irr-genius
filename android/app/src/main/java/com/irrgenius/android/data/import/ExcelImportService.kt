package com.irrgenius.android.data.import

import com.irrgenius.android.data.models.*
import org.apache.poi.hssf.usermodel.HSSFWorkbook
import org.apache.poi.ss.usermodel.*
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import java.io.InputStream
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

/**
 * Service for importing calculation data from Excel files (.xlsx and .xls)
 */
class ExcelImportService {
    
    companion object {
        private val DATE_FORMATTERS = listOf(
            DateTimeFormatter.ofPattern("yyyy-MM-dd"),
            DateTimeFormatter.ofPattern("MM/dd/yyyy"),
            DateTimeFormatter.ofPattern("dd/MM/yyyy"),
            DateTimeFormatter.ofPattern("yyyy/MM/dd")
        )
    }
    
    /**
     * Imports Excel data from an InputStream
     */
    suspend fun importExcel(
        inputStream: InputStream,
        fileName: String,
        sheetIndex: Int = 0,
        hasHeaders: Boolean = true
    ): ImportResult {
        return try {
            val workbook = createWorkbook(inputStream, fileName)
            val sheet = getSheet(workbook, sheetIndex)
            
            val parsedData = parseExcelSheet(sheet, hasHeaders)
            
            ImportResult(
                headers = parsedData.headers,
                rows = parsedData.rows,
                detectedFormat = ImportFormat.Excel(sheet.sheetName, hasHeaders),
                suggestedMapping = suggestColumnMapping(parsedData.headers),
                validationErrors = emptyList()
            )
        } catch (e: Exception) {
            throw ImportException("Failed to parse Excel file: ${e.message}", e)
        }
    }
    
    /**
     * Imports Excel data with sheet selection
     */
    suspend fun importExcelWithSheetSelection(
        inputStream: InputStream,
        fileName: String,
        sheetName: String,
        hasHeaders: Boolean = true
    ): ImportResult {
        return try {
            val workbook = createWorkbook(inputStream, fileName)
            val sheet = workbook.getSheet(sheetName)
                ?: throw ImportException("Sheet '$sheetName' not found in workbook")
            
            val parsedData = parseExcelSheet(sheet, hasHeaders)
            
            ImportResult(
                headers = parsedData.headers,
                rows = parsedData.rows,
                detectedFormat = ImportFormat.Excel(sheetName, hasHeaders),
                suggestedMapping = suggestColumnMapping(parsedData.headers),
                validationErrors = emptyList()
            )
        } catch (e: Exception) {
            throw ImportException("Failed to parse Excel file: ${e.message}", e)
        }
    }
    
    /**
     * Gets available sheet names from Excel file
     */
    suspend fun getSheetNames(inputStream: InputStream, fileName: String): List<String> {
        return try {
            val workbook = createWorkbook(inputStream, fileName)
            (0 until workbook.numberOfSheets).map { index ->
                workbook.getSheetAt(index).sheetName
            }
        } catch (e: Exception) {
            throw ImportException("Failed to read Excel file: ${e.message}", e)
        }
    }
    
    /**
     * Imports Excel data with range specification
     */
    suspend fun importExcelWithRange(
        inputStream: InputStream,
        fileName: String,
        sheetIndex: Int = 0,
        startRow: Int = 0,
        endRow: Int? = null,
        startColumn: Int = 0,
        endColumn: Int? = null,
        hasHeaders: Boolean = true
    ): ImportResult {
        return try {
            val workbook = createWorkbook(inputStream, fileName)
            val sheet = getSheet(workbook, sheetIndex)
            
            val parsedData = parseExcelSheetWithRange(
                sheet = sheet,
                startRow = startRow,
                endRow = endRow,
                startColumn = startColumn,
                endColumn = endColumn,
                hasHeaders = hasHeaders
            )
            
            ImportResult(
                headers = parsedData.headers,
                rows = parsedData.rows,
                detectedFormat = ImportFormat.Excel(sheet.sheetName, hasHeaders),
                suggestedMapping = suggestColumnMapping(parsedData.headers),
                validationErrors = emptyList()
            )
        } catch (e: Exception) {
            throw ImportException("Failed to parse Excel file: ${e.message}", e)
        }
    }
    
    /**
     * Validates imported data and converts to SavedCalculation objects
     */
    suspend fun validateAndConvert(
        importResult: ImportResult,
        columnMapping: Map<String, CalculationField>,
        calculationType: CalculationMode,
        projectId: String? = null
    ): ValidationResult {
        val validationErrors = mutableListOf<ValidationError>()
        val validCalculations = mutableListOf<SavedCalculation>()
        
        importResult.rows.forEachIndexed { rowIndex, row ->
            try {
                val calculation = convertRowToCalculation(
                    row = row,
                    headers = importResult.headers,
                    columnMapping = columnMapping,
                    calculationType = calculationType,
                    projectId = projectId,
                    rowIndex = rowIndex
                )
                
                // Validate the calculation
                calculation.validate()
                validCalculations.add(calculation)
                
            } catch (e: Exception) {
                validationErrors.add(
                    ValidationError(
                        row = rowIndex + 1,
                        column = null,
                        message = e.message ?: "Unknown validation error",
                        severity = ValidationSeverity.ERROR
                    )
                )
            }
        }
        
        return ValidationResult(
            validCalculations = validCalculations,
            validationErrors = validationErrors,
            totalRows = importResult.rows.size,
            validRows = validCalculations.size
        )
    }
    
    /**
     * Creates appropriate workbook based on file extension
     */
    private fun createWorkbook(inputStream: InputStream, fileName: String): Workbook {
        return when {
            fileName.endsWith(".xlsx", ignoreCase = true) -> XSSFWorkbook(inputStream)
            fileName.endsWith(".xls", ignoreCase = true) -> HSSFWorkbook(inputStream)
            else -> throw ImportException("Unsupported file format. Only .xlsx and .xls files are supported.")
        }
    }
    
    /**
     * Gets sheet by index with error handling
     */
    private fun getSheet(workbook: Workbook, sheetIndex: Int): Sheet {
        if (sheetIndex < 0 || sheetIndex >= workbook.numberOfSheets) {
            throw ImportException("Sheet index $sheetIndex is out of range. Available sheets: 0-${workbook.numberOfSheets - 1}")
        }
        return workbook.getSheetAt(sheetIndex)
    }
    
    /**
     * Parses Excel sheet into headers and rows
     */
    private fun parseExcelSheet(sheet: Sheet, hasHeaders: Boolean): ParsedExcelData {
        val rows = sheet.toList().filter { row ->
            // Filter out completely empty rows
            row.any { cell -> !getCellValueAsString(cell).isBlank() }
        }
        
        if (rows.isEmpty()) {
            return ParsedExcelData(emptyList(), emptyList())
        }
        
        val headers = if (hasHeaders) {
            val headerRow = rows.first()
            (0 until getMaxColumnCount(rows)).map { columnIndex ->
                val cell = headerRow.getCell(columnIndex)
                getCellValueAsString(cell).ifBlank { "Column ${columnIndex + 1}" }
            }
        } else {
            // Generate default headers
            val maxColumns = getMaxColumnCount(rows)
            (1..maxColumns).map { "Column $it" }
        }
        
        val dataStartIndex = if (hasHeaders) 1 else 0
        val dataRows = rows.drop(dataStartIndex).map { row ->
            (0 until headers.size).map { columnIndex ->
                val cell = row.getCell(columnIndex)
                getCellValueAsString(cell)
            }
        }
        
        return ParsedExcelData(headers, dataRows)
    }
    
    /**
     * Parses Excel sheet with specified range
     */
    private fun parseExcelSheetWithRange(
        sheet: Sheet,
        startRow: Int,
        endRow: Int?,
        startColumn: Int,
        endColumn: Int?,
        hasHeaders: Boolean
    ): ParsedExcelData {
        val lastRowNum = endRow ?: sheet.lastRowNum
        val rows = (startRow..lastRowNum).mapNotNull { rowIndex ->
            sheet.getRow(rowIndex)
        }.filter { row ->
            // Filter out completely empty rows in the specified range
            val actualEndColumn = endColumn ?: (row.lastCellNum - 1).coerceAtLeast(startColumn)
            (startColumn..actualEndColumn).any { columnIndex ->
                val cell = row.getCell(columnIndex)
                !getCellValueAsString(cell).isBlank()
            }
        }
        
        if (rows.isEmpty()) {
            return ParsedExcelData(emptyList(), emptyList())
        }
        
        val actualEndColumn = endColumn ?: getMaxColumnCount(rows, startColumn) - 1
        val columnCount = (actualEndColumn - startColumn + 1).coerceAtLeast(1)
        
        val headers = if (hasHeaders && rows.isNotEmpty()) {
            val headerRow = rows.first()
            (startColumn..actualEndColumn).map { columnIndex ->
                val cell = headerRow.getCell(columnIndex)
                getCellValueAsString(cell).ifBlank { "Column ${columnIndex - startColumn + 1}" }
            }
        } else {
            (1..columnCount).map { "Column $it" }
        }
        
        val dataStartIndex = if (hasHeaders) 1 else 0
        val dataRows = rows.drop(dataStartIndex).map { row ->
            (startColumn..actualEndColumn).map { columnIndex ->
                val cell = row.getCell(columnIndex)
                getCellValueAsString(cell)
            }
        }
        
        return ParsedExcelData(headers, dataRows)
    }
    
    /**
     * Gets the maximum column count across all rows
     */
    private fun getMaxColumnCount(rows: List<Row>, startColumn: Int = 0): Int {
        return rows.maxOfOrNull { row ->
            row.lastCellNum.coerceAtLeast(startColumn + 1)
        } ?: (startColumn + 1)
    }
    
    /**
     * Converts Excel cell value to string
     */
    private fun getCellValueAsString(cell: Cell?): String {
        if (cell == null) return ""
        
        return when (cell.cellType) {
            CellType.STRING -> cell.stringCellValue
            CellType.NUMERIC -> {
                if (DateUtil.isCellDateFormatted(cell)) {
                    // Handle date cells
                    val date = cell.dateCellValue
                    DateTimeFormatter.ofPattern("yyyy-MM-dd").format(
                        date.toInstant().atZone(java.time.ZoneId.systemDefault()).toLocalDate()
                    )
                } else {
                    // Handle numeric cells
                    val numericValue = cell.numericCellValue
                    if (numericValue == numericValue.toLong().toDouble()) {
                        // Integer value
                        numericValue.toLong().toString()
                    } else {
                        // Decimal value
                        numericValue.toString()
                    }
                }
            }
            CellType.BOOLEAN -> cell.booleanCellValue.toString()
            CellType.FORMULA -> {
                try {
                    // Try to evaluate formula
                    val evaluator = cell.sheet.workbook.creationHelper.createFormulaEvaluator()
                    val result = evaluator.evaluate(cell)
                    when (result.cellType) {
                        CellType.STRING -> result.stringValue
                        CellType.NUMERIC -> result.numberValue.toString()
                        CellType.BOOLEAN -> result.booleanValue.toString()
                        else -> ""
                    }
                } catch (e: Exception) {
                    // If formula evaluation fails, return empty string
                    ""
                }
            }
            else -> ""
        }
    }
    
    /**
     * Suggests column mapping based on header names
     */
    private fun suggestColumnMapping(headers: List<String>): Map<String, CalculationField> {
        val mapping = mutableMapOf<String, CalculationField>()
        
        headers.forEach { header ->
            val normalizedHeader = header.lowercase().replace(Regex("[^a-z0-9]"), "")
            
            val suggestedField = when {
                normalizedHeader.contains("initial") || normalizedHeader.contains("investment") -> CalculationField.INITIAL_INVESTMENT
                normalizedHeader.contains("outcome") || normalizedHeader.contains("exit") -> CalculationField.OUTCOME_AMOUNT
                normalizedHeader.contains("time") || normalizedHeader.contains("month") || normalizedHeader.contains("duration") -> CalculationField.TIME_IN_MONTHS
                normalizedHeader.contains("irr") || normalizedHeader.contains("return") -> CalculationField.IRR
                normalizedHeader.contains("name") || normalizedHeader.contains("title") -> CalculationField.NAME
                normalizedHeader.contains("note") || normalizedHeader.contains("comment") -> CalculationField.NOTES
                normalizedHeader.contains("date") || normalizedHeader.contains("created") -> CalculationField.DATE
                normalizedHeader.contains("unit") && normalizedHeader.contains("price") -> CalculationField.UNIT_PRICE
                normalizedHeader.contains("success") && normalizedHeader.contains("rate") -> CalculationField.SUCCESS_RATE
                normalizedHeader.contains("outcome") && normalizedHeader.contains("unit") -> CalculationField.OUTCOME_PER_UNIT
                normalizedHeader.contains("investor") && normalizedHeader.contains("share") -> CalculationField.INVESTOR_SHARE
                normalizedHeader.contains("fee") -> CalculationField.FEE_PERCENTAGE
                else -> null
            }
            
            suggestedField?.let { mapping[header] = it }
        }
        
        return mapping
    }
    
    /**
     * Converts an Excel row to a SavedCalculation object
     */
    private fun convertRowToCalculation(
        row: List<String>,
        headers: List<String>,
        columnMapping: Map<String, CalculationField>,
        calculationType: CalculationMode,
        projectId: String?,
        rowIndex: Int
    ): SavedCalculation {
        val fieldValues = mutableMapOf<CalculationField, String>()
        
        // Map row values to calculation fields
        headers.forEachIndexed { index, header ->
            if (index < row.size) {
                columnMapping[header]?.let { field ->
                    fieldValues[field] = row[index]
                }
            }
        }
        
        // Extract and validate field values
        val name = fieldValues[CalculationField.NAME]?.takeIf { it.isNotBlank() }
            ?: "Imported Calculation ${rowIndex + 1}"
        
        val initialInvestment = fieldValues[CalculationField.INITIAL_INVESTMENT]?.let { 
            parseDouble(it, "Initial Investment", rowIndex + 1)
        }
        
        val outcomeAmount = fieldValues[CalculationField.OUTCOME_AMOUNT]?.let {
            parseDouble(it, "Outcome Amount", rowIndex + 1)
        }
        
        val timeInMonths = fieldValues[CalculationField.TIME_IN_MONTHS]?.let {
            parseDouble(it, "Time in Months", rowIndex + 1)
        }
        
        val irr = fieldValues[CalculationField.IRR]?.let {
            parseDouble(it, "IRR", rowIndex + 1)
        }
        
        val unitPrice = fieldValues[CalculationField.UNIT_PRICE]?.let {
            parseDouble(it, "Unit Price", rowIndex + 1)
        }
        
        val successRate = fieldValues[CalculationField.SUCCESS_RATE]?.let {
            parseDouble(it, "Success Rate", rowIndex + 1)
        }
        
        val outcomePerUnit = fieldValues[CalculationField.OUTCOME_PER_UNIT]?.let {
            parseDouble(it, "Outcome Per Unit", rowIndex + 1)
        }
        
        val investorShare = fieldValues[CalculationField.INVESTOR_SHARE]?.let {
            parseDouble(it, "Investor Share", rowIndex + 1)
        }
        
        val feePercentage = fieldValues[CalculationField.FEE_PERCENTAGE]?.let {
            parseDouble(it, "Fee Percentage", rowIndex + 1)
        }
        
        val notes = fieldValues[CalculationField.NOTES]
        
        val createdDate = fieldValues[CalculationField.DATE]?.let { 
            parseDate(it, rowIndex + 1) 
        } ?: LocalDateTime.now()
        
        return SavedCalculation.createValidated(
            name = name,
            calculationType = calculationType,
            createdDate = createdDate,
            modifiedDate = LocalDateTime.now(),
            projectId = projectId,
            initialInvestment = initialInvestment,
            outcomeAmount = outcomeAmount,
            timeInMonths = timeInMonths,
            irr = irr,
            unitPrice = unitPrice,
            successRate = successRate,
            outcomePerUnit = outcomePerUnit,
            investorShare = investorShare,
            feePercentage = feePercentage,
            notes = notes
        )
    }
    
    /**
     * Parses a string to Double with error handling
     */
    private fun parseDouble(value: String, fieldName: String, rowNumber: Int): Double {
        return try {
            // Remove common currency symbols and formatting
            val cleanValue = value.replace(Regex("[$,€£¥%\\s]"), "")
            cleanValue.toDouble()
        } catch (e: NumberFormatException) {
            throw ImportException("Invalid number format in row $rowNumber for field '$fieldName': '$value'")
        }
    }
    
    /**
     * Parses a string to LocalDateTime with error handling
     */
    private fun parseDate(value: String, rowNumber: Int): LocalDateTime {
        for (formatter in DATE_FORMATTERS) {
            try {
                return LocalDateTime.parse(value, formatter.withTime(java.time.LocalTime.MIDNIGHT))
            } catch (e: java.time.format.DateTimeParseException) {
                // Try next formatter
            }
        }
        throw ImportException("Invalid date format in row $rowNumber: '$value'")
    }
    
    private fun java.time.format.DateTimeFormatter.withTime(time: java.time.LocalTime): java.time.format.DateTimeFormatter {
        return java.time.format.DateTimeFormatter.ofPattern("${this.toString()} HH:mm:ss")
    }
}

/**
 * Data class for parsed Excel data
 */
private data class ParsedExcelData(
    val headers: List<String>,
    val rows: List<List<String>>
)

/**
 * Sheet information for Excel files
 */
data class ExcelSheetInfo(
    val name: String,
    val index: Int,
    val rowCount: Int,
    val columnCount: Int
)