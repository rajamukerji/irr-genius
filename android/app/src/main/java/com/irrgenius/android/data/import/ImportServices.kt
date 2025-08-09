package com.irrgenius.android.data.import

import com.irrgenius.android.data.models.CalculationMode
import com.irrgenius.android.data.models.SavedCalculation
import java.io.InputStream

// CSV Import Service
class CSVImportService {
    
    suspend fun importCSV(inputStream: InputStream): ImportResultWithMapping {
        return try {
            val csvContent = inputStream.bufferedReader().readText()
            val lines = csvContent.split("\n").filter { it.trim().isNotEmpty() }
            
            if (lines.isEmpty()) {
                throw Exception("CSV file is empty")
            }
            
            val headers = lines.first().split(",").map { it.trim().removeSurrounding("\"") }
            val dataRows = lines.drop(1).map { line ->
                line.split(",").map { it.trim().removeSurrounding("\"") }
            }
            
            val suggestedMapping = detectColumnMapping(headers)
            
            ImportResultWithMapping(
                calculations = emptyList(), // Will be populated after validation
                validationResult = ValidationResult(emptyList(), emptyList()),
                suggestedMapping = suggestedMapping,
                headers = headers,
                rows = dataRows,
                detectedFormat = ImportFormat.CSV,
                validCalculations = emptyList()
            )
        } catch (e: Exception) {
            throw Exception("Failed to parse CSV: ${e.message}", e)
        }
    }
    
    suspend fun validateAndConvert(
        importResult: ImportResultWithMapping,
        columnMapping: Map<String, CalculationField>,
        calculationType: CalculationMode
    ): ValidationResult {
        val errors = mutableListOf<ValidationError>()
        val warnings = mutableListOf<ValidationError>()
        
        importResult.rows.forEachIndexed { rowIndex, row ->
            try {
                val calculation = convertRowToCalculation(row, importResult.headers, columnMapping, calculationType)
                if (calculation == null) {
                    warnings.add(ValidationError(
                        message = "Row contains insufficient data to create calculation",
                        row = rowIndex + 2, // +2 because we skip header and use 1-based indexing
                        severity = ValidationSeverity.WARNING
                    ))
                }
            } catch (e: Exception) {
                errors.add(ValidationError(
                    message = e.message ?: "Unknown error",
                    row = rowIndex + 2,
                    severity = ValidationSeverity.ERROR
                ))
            }
        }
        
        return ValidationResult(
            errors = errors,
            warnings = warnings
        )
    }
}

// Excel Import Service
class ExcelImportService {
    
    suspend fun importExcel(inputStream: InputStream, fileName: String): ImportResultWithMapping {
        // For now, Excel import is not fully implemented
        // This would require adding Apache POI library for Excel parsing
        throw Exception("Excel import not yet implemented. Please use CSV format for now.")
    }
    
    suspend fun validateAndConvert(
        importResult: ImportResultWithMapping,
        columnMapping: Map<String, CalculationField>,
        calculationType: CalculationMode
    ): ValidationResult {
        // Excel validation would be similar to CSV but with Excel-specific parsing
        throw Exception("Excel validation not yet implemented")
    }
}

// Extended import result with column mapping suggestions
data class ImportResultWithMapping(
    val calculations: List<SavedCalculation>,
    val validationResult: ValidationResult,
    val suggestedMapping: Map<String, CalculationField>,
    val headers: List<String> = emptyList(),
    val rows: List<List<String>> = emptyList(),
    val detectedFormat: ImportFormat = ImportFormat.GENERIC_CSV,
    val validCalculations: List<SavedCalculation> = emptyList()
)

// Helper functions for CSV import
private fun detectColumnMapping(headers: List<String>): Map<String, CalculationField> {
    val mapping = mutableMapOf<String, CalculationField>()
    
    headers.forEach { header ->
        val normalizedHeader = header.lowercase().replace(" ", "_")
        when {
            normalizedHeader.contains("name") || normalizedHeader.contains("title") -> 
                mapping[header] = CalculationField.NAME
            normalizedHeader.contains("initial") && normalizedHeader.contains("investment") -> 
                mapping[header] = CalculationField.INITIAL_INVESTMENT
            normalizedHeader.contains("outcome") && (normalizedHeader.contains("value") || normalizedHeader.contains("amount")) -> 
                mapping[header] = CalculationField.OUTCOME_VALUE
            normalizedHeader.contains("time") || normalizedHeader.contains("period") || normalizedHeader.contains("month") -> 
                mapping[header] = CalculationField.INVESTMENT_PERIOD_YEARS
            normalizedHeader.contains("note") -> 
                mapping[header] = CalculationField.NOTES
            normalizedHeader.contains("tag") -> 
                mapping[header] = CalculationField.TAGS
            normalizedHeader.contains("type") || normalizedHeader.contains("mode") -> 
                mapping[header] = CalculationField.CALCULATION_MODE
        }
    }
    
    return mapping
}

private fun convertRowToCalculation(
    row: List<String>,
    headers: List<String>,
    columnMapping: Map<String, CalculationField>,
    calculationType: CalculationMode
): SavedCalculation? {
    try {
        val fieldValues = mutableMapOf<CalculationField, String>()
        
        // Map row values to fields based on column mapping
        headers.forEachIndexed { index, header ->
            if (index < row.size) {
                columnMapping[header]?.let { field ->
                    fieldValues[field] = row[index].trim()
                }
            }
        }
        
        val name = fieldValues[CalculationField.NAME]?.takeIf { it.isNotBlank() } ?: return null
        val initialInvestment = fieldValues[CalculationField.INITIAL_INVESTMENT]?.toDoubleOrNull()
        val outcomeValue = fieldValues[CalculationField.OUTCOME_VALUE]?.toDoubleOrNull()
        val timePeriod = fieldValues[CalculationField.INVESTMENT_PERIOD_YEARS]?.toDoubleOrNull()
        
        // Basic validation - need at least name and one financial value
        if (initialInvestment == null && outcomeValue == null) {
            return null
        }
        
        return SavedCalculation(
            id = java.util.UUID.randomUUID().toString(),
            name = name,
            calculationType = calculationType,
            createdDate = java.time.LocalDateTime.now(),
            modifiedDate = java.time.LocalDateTime.now(),
            projectId = null,
            initialInvestment = initialInvestment,
            outcomeAmount = outcomeValue,
            timeInMonths = timePeriod,
            irr = null,
            unitPrice = null,
            successRate = null,
            outcomePerUnit = null,
            investorShare = null,
            feePercentage = null,
            calculatedResult = null,
            growthPointsJson = null,
            notes = fieldValues[CalculationField.NOTES],
            tags = fieldValues[CalculationField.TAGS]?.let { tags ->
                val tagList = tags.split(";", ",").map { it.trim() }.filter { it.isNotBlank() }
                "[\"${tagList.joinToString("\", \"")}\"]"
            }
        )
    } catch (e: Exception) {
        throw Exception("Error converting row to calculation: ${e.message}")
    }
}