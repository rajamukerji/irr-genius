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
    val hasErrors: Boolean get() = errors.isNotEmpty()
    val validRows: Int get() = 0 // Stub implementation
    val totalRows: Int get() = 0 // Stub implementation
    val successRate: Float get() = if (totalRows > 0) validRows.toFloat() / totalRows else 0f
    val validationErrors: List<ValidationError> get() = errors + warnings
}

// Validation error/warning
data class ValidationError(
    val message: String,
    val row: Int = -1,
    val field: CalculationField? = null,
    val severity: ValidationSeverity = ValidationSeverity.ERROR,
    val column: String = ""
)

// Validation severity levels
enum class ValidationSeverity {
    ERROR,
    WARNING,
    INFO
}

// Extension properties for display names
val CalculationField.displayName: String
    get() = when (this) {
        CalculationField.NAME -> "Name"
        CalculationField.INITIAL_INVESTMENT -> "Initial Investment"
        CalculationField.OUTCOME_VALUE -> "Outcome Value"
        CalculationField.INVESTMENT_PERIOD_YEARS -> "Investment Period (Years)"
        CalculationField.NOTES -> "Notes"
        CalculationField.TAGS -> "Tags"
        CalculationField.CALCULATION_MODE -> "Calculation Mode"
    }