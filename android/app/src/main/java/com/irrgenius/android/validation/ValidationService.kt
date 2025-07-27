package com.irrgenius.android.validation

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

// MARK: - Validation Models

enum class ValidationSeverity {
    ERROR,
    WARNING,
    INFO
}

data class ValidationError(
    val field: String,
    val message: String,
    val severity: ValidationSeverity = ValidationSeverity.ERROR
)

sealed class ValidationRule {
    abstract fun validate(value: String): ValidationError?
    
    data class Required(val message: String = "This field is required") : ValidationRule() {
        override fun validate(value: String): ValidationError? {
            return if (value.trim().isEmpty()) {
                ValidationError("", message, ValidationSeverity.ERROR)
            } else null
        }
    }
    
    data class MinLength(val min: Int, val message: String = "Must be at least $min characters") : ValidationRule() {
        override fun validate(value: String): ValidationError? {
            return if (value.length < min) {
                ValidationError("", message, ValidationSeverity.ERROR)
            } else null
        }
    }
    
    data class MaxLength(val max: Int, val message: String = "Must be no more than $max characters") : ValidationRule() {
        override fun validate(value: String): ValidationError? {
            return if (value.length > max) {
                ValidationError("", message, ValidationSeverity.ERROR)
            } else null
        }
    }
    
    data class Numeric(val message: String = "Must be a valid number") : ValidationRule() {
        override fun validate(value: String): ValidationError? {
            return if (value.isNotEmpty() && value.toDoubleOrNull() == null) {
                ValidationError("", message, ValidationSeverity.ERROR)
            } else null
        }
    }
    
    data class PositiveNumber(val message: String = "Must be a positive number") : ValidationRule() {
        override fun validate(value: String): ValidationError? {
            val number = value.toDoubleOrNull()
            return if (number != null && number <= 0) {
                ValidationError("", message, ValidationSeverity.ERROR)
            } else null
        }
    }
    
    data class Percentage(val message: String = "Must be between 0 and 100") : ValidationRule() {
        override fun validate(value: String): ValidationError? {
            val number = value.toDoubleOrNull()
            return if (number != null && (number < 0 || number > 100)) {
                ValidationError("", message, ValidationSeverity.ERROR)
            } else null
        }
    }
    
    data class Email(val message: String = "Must be a valid email address") : ValidationRule() {
        override fun validate(value: String): ValidationError? {
            val emailPattern = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            return if (value.isNotEmpty() && !value.matches(emailPattern.toRegex())) {
                ValidationError("", message, ValidationSeverity.ERROR)
            } else null
        }
    }
}

// MARK: - Validation Service

/**
 * Service for validating input fields
 */
object ValidationService {
    private val fieldRules = mutableMapOf<String, List<ValidationRule>>()
    
    private val _errors = MutableStateFlow<List<ValidationError>>(emptyList())
    val errors: StateFlow<List<ValidationError>> = _errors.asStateFlow()
    
    init {
        setupValidationRules()
    }
    
    /**
     * Validates a single field
     */
    fun validateField(fieldName: String, value: String): List<ValidationError> {
        val rules = fieldRules[fieldName] ?: return emptyList()
        return rules.mapNotNull { rule ->
            rule.validate(value)?.copy(field = fieldName)
        }
    }
    
    /**
     * Validates multiple fields
     */
    fun validateFields(fieldsToValidate: Map<String, String>): Map<String, List<ValidationError>> {
        val results = mutableMapOf<String, List<ValidationError>>()
        
        for ((fieldName, value) in fieldsToValidate) {
            val errors = validateField(fieldName, value)
            if (errors.isNotEmpty()) {
                results[fieldName] = errors
            }
        }
        
        return results
    }
    
    /**
     * Checks if all validation passes for the given fields
     */
    fun isValid(fieldsToValidate: Map<String, String>): Boolean {
        return validateFields(fieldsToValidate).isEmpty()
    }
    
    /**
     * Gets the most severe validation error level for a field
     */
    fun getSeverityLevel(fieldName: String, value: String): ValidationSeverity {
        val errors = validateField(fieldName, value)
        return when {
            errors.any { it.severity == ValidationSeverity.ERROR } -> ValidationSeverity.ERROR
            errors.any { it.severity == ValidationSeverity.WARNING } -> ValidationSeverity.WARNING
            else -> ValidationSeverity.INFO
        }
    }
    
    private fun setupValidationRules() {
        // Basic numeric validation
        fieldRules["initialInvestment"] = listOf(
            ValidationRule.Required("Initial investment is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Initial investment must be positive")
        )
        
        fieldRules["outcomeAmount"] = listOf(
            ValidationRule.Required("Outcome amount is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Outcome amount must be positive")
        )
        
        fieldRules["timeInMonths"] = listOf(
            ValidationRule.Required("Time period is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Time period must be positive")
        )
        
        // Portfolio validation
        fieldRules["numberOfUnits"] = listOf(
            ValidationRule.Required("Number of units is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Number of units must be positive")
        )
        
        fieldRules["unitPrice"] = listOf(
            ValidationRule.Required("Unit price is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Unit price must be positive")
        )
        
        fieldRules["successRate"] = listOf(
            ValidationRule.Required("Success rate is required"),
            ValidationRule.Numeric(),
            ValidationRule.Percentage("Success rate must be between 0 and 100")
        )
        
        fieldRules["outcomePerUnit"] = listOf(
            ValidationRule.Required("Outcome per unit is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Outcome per unit must be positive")
        )
        
        // IRR specific validation
        fieldRules["irr"] = listOf(
            ValidationRule.Required("IRR is required"),
            ValidationRule.Numeric()
        )
        
        // Date validation
        fieldRules["dateField"] = listOf(
            ValidationRule.Required("Date is required")
        )
        
        // String validation
        fieldRules["name"] = listOf(
            ValidationRule.Required("Name is required"),
            ValidationRule.MinLength(1, "Name cannot be empty")
        )
        
        fieldRules["notes"] = listOf(
            ValidationRule.MaxLength(1000, "Notes cannot exceed 1000 characters")
        )
        
        // Project validation
        fieldRules["projectName"] = listOf(
            ValidationRule.Required("Project name is required"),
            ValidationRule.MinLength(1),
            ValidationRule.MaxLength(50, "Project name must be no more than 50 characters")
        )
        
        fieldRules["projectDescription"] = listOf(
            ValidationRule.MaxLength(500, "Description must be no more than 500 characters")
        )
    }
}