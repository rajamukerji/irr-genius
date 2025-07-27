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

class ValidationService {
    private val _errors = MutableStateFlow<List<ValidationError>>(emptyList())
    val errors: StateFlow<List<ValidationError>> = _errors.asStateFlow()
    
    private val fieldRules = mutableMapOf<String, List<ValidationRule>>()
    
    fun registerField(fieldName: String, rules: List<ValidationRule>) {
        fieldRules[fieldName] = rules
    }
    
    fun validateField(fieldName: String, value: String): List<ValidationError> {
        val rules = fieldRules[fieldName] ?: return emptyList()
        return rules.mapNotNull { rule ->
            rule.validate(value)?.copy(field = fieldName)
        }
    }
    
    fun validateAllFields(fieldValues: Map<String, String>): List<ValidationError> {
        val allErrors = mutableListOf<ValidationError>()
        
        fieldValues.forEach { (fieldName, value) ->
            allErrors.addAll(validateField(fieldName, value))
        }
        
        _errors.value = allErrors
        return allErrors
    }
    
    fun clearErrors() {
        _errors.value = emptyList()
    }
    
    fun clearFieldErrors(fieldName: String) {
        _errors.value = _errors.value.filter { it.field != fieldName }
    }
    
    fun hasErrors(): Boolean = _errors.value.any { it.severity == ValidationSeverity.ERROR }
    
    fun getFieldErrors(fieldName: String): List<ValidationError> {
        return _errors.value.filter { it.field == fieldName }
    }
}

// MARK: - Calculation Validation Service

class CalculationValidationService : ValidationService() {
    
    init {
        setupCalculationRules()
    }
    
    private fun setupCalculationRules() {
        // IRR Calculation validation
        registerField("initialInvestment", listOf(
            ValidationRule.Required("Initial investment is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Initial investment must be positive")
        ))
        
        registerField("outcomeAmount", listOf(
            ValidationRule.Required("Outcome amount is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Outcome amount must be positive")
        ))
        
        registerField("timeInMonths", listOf(
            ValidationRule.Required("Time period is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Time period must be positive")
        ))
        
        // Portfolio validation
        registerField("numberOfUnits", listOf(
            ValidationRule.Required("Number of units is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Number of units must be positive")
        ))
        
        registerField("unitPrice", listOf(
            ValidationRule.Required("Unit price is required"),
            ValidationRule.Numeric(),
            ValidationRule.PositiveNumber("Unit price must be positive")
        ))
        
        registerField("successRate", listOf(
            ValidationRule.Required("Success rate is required"),
            ValidationRule.Numeric()
        ))
        
        // Project validation
        registerField("projectName", listOf(
            ValidationRule.Required("Project name is required"),
            ValidationRule.MinLength(1),
            ValidationRule.MaxLength(50, "Project name must be no more than 50 characters")
        ))
        
        registerField("projectDescription", listOf(
            ValidationRule.MaxLength(500, "Description must be no more than 500 characters")
        ))
    }
    
    fun validateSuccessRate(value: String): List<ValidationError> {
        val baseErrors = validateField("successRate", value)
        val number = value.toDoubleOrNull()
        
        return if (number != null && (number < 0 || number > 100)) {
            baseErrors + ValidationError("successRate", "Success rate must be between 0 and 100", ValidationSeverity.ERROR)
        } else {
            baseErrors
        }
    }
    
    fun validateIRR(value: String): List<ValidationError> {
        val baseErrors = validateField("irr", value)
        val number = value.toDoubleOrNull()
        
        return if (number != null && (number < -100 || number > 1000)) {
            baseErrors + ValidationError("irr", "IRR should be between -100% and 1000%", ValidationSeverity.WARNING)
        } else {
            baseErrors
        }
    }
}