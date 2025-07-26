package com.irrgenius.android.data.import

import com.irrgenius.android.data.models.*
import java.io.BufferedReader
import java.io.InputStream
import java.io.InputStreamReader
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException
import java.util.*

/**
 * Service for importing calculation data from CSV files
 */
class CSVImportService {
    
    companion object {
        private val SUPPORTED_DELIMITERS = listOf(',', ';', '\t', '|')
        private val DATE_FORMATTERS = listOf(
            DateTimeFormatter.ofPattern("yyyy-MM-dd"),
            DateTimeFormatter.ofPattern("MM/dd/yyyy"),
            DateTimeFormatter.ofPattern("dd/MM/yyyy"),
            DateTimeFormatter.ofPattern("yyyy/MM/dd")
        )
    }
    
    /**
     * Imports CSV data from an InputStream
     */
    suspend fun importCSV(
        inputStream: InputStream,
        delimiter: Char = ',',
        hasHeaders: Boolean = true
    ): ImportResult {
        return try {
            val reader = BufferedReader(InputStreamReader(inputStream))
            val lines = reader.readLines()
            reader.close()
            
            if (lines.isEmpty()) {
                throw ImportException("File is empty")
            }
            
            val actualDelimiter = detectDelimiter(lines.first(), delimiter)
            val parsedData = parseCSVLines(lines, actualDelimiter, hasHeaders)
            
            ImportResult(
                headers = parsedData.headers,
                rows = parsedData.rows,
                detectedFormat = ImportFormat.CSV(actualDelimiter, hasHeaders),
                suggestedMapping = suggestColumnMapping(parsedData.headers),
                validationErrors = emptyList()
            )
        } catch (e: Exception) {
            throw ImportException("Failed to parse CSV: ${e.message}", e)
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
     * Detects the most likely delimiter in a CSV line
     */
    private fun detectDelimiter(line: String, preferredDelimiter: Char): Char {
        if (line.contains(preferredDelimiter)) {
            return preferredDelimiter
        }
        
        return SUPPORTED_DELIMITERS.maxByOrNull { delimiter ->
            line.count { it == delimiter }
        } ?: ','
    }
    
    /**
     * Parses CSV lines into headers and rows
     */
    private fun parseCSVLines(
        lines: List<String>,
        delimiter: Char,
        hasHeaders: Boolean
    ): ParsedCSVData {
        val headers = if (hasHeaders && lines.isNotEmpty()) {
            parseCSVLine(lines.first(), delimiter)
        } else {
            // Generate default headers if no headers provided
            val firstLine = lines.firstOrNull() ?: return ParsedCSVData(emptyList(), emptyList())
            val columnCount = parseCSVLine(firstLine, delimiter).size
            (1..columnCount).map { "Column $it" }
        }
        
        val dataStartIndex = if (hasHeaders) 1 else 0
        val rows = lines.drop(dataStartIndex).map { line ->
            parseCSVLine(line, delimiter)
        }.filter { it.isNotEmpty() } // Filter out empty rows
        
        return ParsedCSVData(headers, rows)
    }
    
    /**
     * Parses a single CSV line, handling quoted values
     */
    private fun parseCSVLine(line: String, delimiter: Char): List<String> {
        val result = mutableListOf<String>()
        val current = StringBuilder()
        var inQuotes = false
        var i = 0
        
        while (i < line.length) {
            val char = line[i]
            
            when {
                char == '"' -> {
                    if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
                        // Escaped quote
                        current.append('"')
                        i++ // Skip next quote
                    } else {
                        // Toggle quote state
                        inQuotes = !inQuotes
                    }
                }
                char == delimiter && !inQuotes -> {
                    result.add(current.toString().trim())
                    current.clear()
                }
                else -> {
                    current.append(char)
                }
            }
            i++
        }
        
        result.add(current.toString().trim())
        return result
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
     * Converts a CSV row to a SavedCalculation object
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
            } catch (e: DateTimeParseException) {
                // Try next formatter
            }
        }
        throw ImportException("Invalid date format in row $rowNumber: '$value'")
    }
    
    private fun DateTimeFormatter.withTime(time: java.time.LocalTime): DateTimeFormatter {
        return DateTimeFormatter.ofPattern("${this.toString()} HH:mm:ss")
    }
}

/**
 * Data class for parsed CSV data
 */
private data class ParsedCSVData(
    val headers: List<String>,
    val rows: List<List<String>>
)

/**
 * Enum representing calculation fields that can be imported
 */
enum class CalculationField(val displayName: String) {
    NAME("Calculation Name"),
    INITIAL_INVESTMENT("Initial Investment"),
    OUTCOME_AMOUNT("Outcome Amount"),
    TIME_IN_MONTHS("Time in Months"),
    IRR("IRR (%)"),
    UNIT_PRICE("Unit Price"),
    SUCCESS_RATE("Success Rate (%)"),
    OUTCOME_PER_UNIT("Outcome Per Unit"),
    INVESTOR_SHARE("Investor Share (%)"),
    FEE_PERCENTAGE("Fee Percentage (%)"),
    NOTES("Notes"),
    DATE("Date")
}

/**
 * Import format specification
 */
sealed class ImportFormat {
    data class CSV(val delimiter: Char, val hasHeaders: Boolean) : ImportFormat()
    data class Excel(val sheetName: String, val hasHeaders: Boolean) : ImportFormat()
}

/**
 * Result of CSV import operation
 */
data class ImportResult(
    val headers: List<String>,
    val rows: List<List<String>>,
    val detectedFormat: ImportFormat,
    val suggestedMapping: Map<String, CalculationField>,
    val validationErrors: List<ValidationError>
)

/**
 * Result of data validation
 */
data class ValidationResult(
    val validCalculations: List<SavedCalculation>,
    val validationErrors: List<ValidationError>,
    val totalRows: Int,
    val validRows: Int
) {
    val hasErrors: Boolean get() = validationErrors.isNotEmpty()
    val successRate: Double get() = if (totalRows > 0) validRows.toDouble() / totalRows else 0.0
}

/**
 * Validation error information
 */
data class ValidationError(
    val row: Int,
    val column: String?,
    val message: String,
    val severity: ValidationSeverity
)

/**
 * Severity levels for validation errors
 */
enum class ValidationSeverity {
    WARNING,
    ERROR
}

/**
 * Exception thrown during import operations
 */
class ImportException(message: String, cause: Throwable? = null) : Exception(message, cause)