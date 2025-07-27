package com.irrgenius.android.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.irrgenius.android.utils.NumberFormatter
import com.irrgenius.android.validation.ValidationError
import com.irrgenius.android.validation.ValidationService
import com.irrgenius.android.validation.ValidationSeverity

enum class InputFieldType {
    CURRENCY,
    NUMBER,
    NONE
}

@Composable
fun InputField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    fieldType: InputFieldType = InputFieldType.NUMBER,
    fieldName: String? = null,
    validationService: ValidationService? = null,
    isRequired: Boolean = false,
    enabled: Boolean = true,
    suffix: String? = null,
    isError: Boolean = false,
    errorMessage: String? = null
) {
    var textFieldValue by remember(value) { mutableStateOf(value) }
    var hasBeenEdited by remember { mutableStateOf(false) }
    var validationErrors by remember { mutableStateOf<List<ValidationError>>(emptyList()) }
    
    // Update validation errors when validation service changes
    LaunchedEffect(validationService, fieldName, value) {
        if (fieldName != null && validationService != null && value.isNotEmpty()) {
            validationErrors = validationService.validateField(fieldName, value)
        } else {
            validationErrors = emptyList()
        }
    }
    
    // Use legacy error parameters if provided, otherwise use validation service
    val hasErrors = if (isError && errorMessage != null) {
        true
    } else {
        validationErrors.isNotEmpty()
    }
    
    val displayErrorMessage = if (isError && errorMessage != null) {
        errorMessage
    } else {
        validationErrors.firstOrNull()?.message
    }
    
    val isValid = hasBeenEdited && !hasErrors && value.isNotEmpty()
    
    Column(modifier = modifier) {
        // Label with required indicator
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row {
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Medium
                )
                if (isRequired) {
                    Text(
                        text = " *",
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.labelMedium
                    )
                }
            }
            
            if (isValid) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = "Valid",
                    tint = Color(0xFF4CAF50),
                    modifier = Modifier.size(16.dp)
                )
            }
        }
        
        Spacer(modifier = Modifier.height(4.dp))
        
        OutlinedTextField(
            value = textFieldValue,
            onValueChange = { newValue ->
                hasBeenEdited = true
                
                when (fieldType) {
                    InputFieldType.CURRENCY, InputFieldType.NUMBER -> {
                        // Allow only numbers, decimal point, and commas
                        val filtered = newValue.filter { it.isDigit() || it == '.' || it == ',' }
                        
                        // Format the input
                        val parsed = NumberFormatter.parseDouble(filtered)
                        if (parsed != null) {
                            textFieldValue = NumberFormatter.formatInputText(filtered, fieldType == InputFieldType.CURRENCY)
                            onValueChange(parsed.toString())
                        } else if (filtered.isEmpty()) {
                            textFieldValue = ""
                            onValueChange("")
                        }
                    }
                    InputFieldType.NONE -> {
                        textFieldValue = newValue
                        onValueChange(newValue)
                    }
                }
                
                // Validate if validation service is provided
                if (fieldName != null && validationService != null) {
                    validationErrors = validationService.validateField(fieldName, textFieldValue)
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = enabled,
            isError = hasErrors,
            keyboardOptions = KeyboardOptions(
                keyboardType = when (fieldType) {
                    InputFieldType.CURRENCY, InputFieldType.NUMBER -> KeyboardType.Decimal
                    InputFieldType.NONE -> KeyboardType.Text
                }
            ),
            prefix = if (fieldType == InputFieldType.CURRENCY) {
                { Text("$") }
            } else null,
            suffix = if (suffix != null) {
                { Text(suffix) }
            } else null,
            singleLine = true,
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = when {
                    hasErrors -> MaterialTheme.colorScheme.error
                    isValid -> Color(0xFF4CAF50)
                    else -> MaterialTheme.colorScheme.primary
                },
                unfocusedBorderColor = when {
                    hasErrors -> MaterialTheme.colorScheme.error
                    isValid -> Color(0xFF4CAF50)
                    else -> MaterialTheme.colorScheme.outline
                }
            )
        )
        
        // Error messages
        if (hasErrors && displayErrorMessage != null) {
            Spacer(modifier = Modifier.height(4.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Start,
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error,
                    modifier = Modifier.size(12.dp)
                )
                
                Spacer(modifier = Modifier.width(4.dp))
                
                Text(
                    text = displayErrorMessage,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}