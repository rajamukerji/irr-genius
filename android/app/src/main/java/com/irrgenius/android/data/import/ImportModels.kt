package com.irrgenius.android.data.import

import com.irrgenius.android.data.models.SavedCalculation

// Import file types
enum class ImportFileType {
    CSV,
    EXCEL
}

// Import result for parsed data
data class ImportResult(
    val calculations: List<SavedCalculation>,
    val validationResult: ValidationResult
)

// Import format specification
enum class ImportFormat {
    IRR_GENIUS_EXPORT,
    GENERIC_CSV,
    EXCEL_WORKBOOK,
    CSV,
    Excel
}

// Field mapping for import
enum class CalculationField {
    NAME,
    INITIAL_INVESTMENT,
    OUTCOME_VALUE,
    INVESTMENT_PERIOD_YEARS,
    NOTES,
    TAGS,
    CALCULATION_MODE
}

// Validation result for imported data
data class ValidationResult(
    val errors: List<ValidationError>,
    val warnings: List<ValidationError>
) {
    val isValid: Boolean get() = errors.isEmpty()
    val hasWarnings: Boolean get() = warnings.isNotEmpty()
}

// Validation error/warning
data class ValidationError(
    val message: String,
    val row: Int = -1,
    val field: CalculationField? = null,
    val severity: ValidationSeverity = ValidationSeverity.ERROR
)

// Validation severity levels
enum class ValidationSeverity {
    ERROR,
    WARNING,
    INFO
}