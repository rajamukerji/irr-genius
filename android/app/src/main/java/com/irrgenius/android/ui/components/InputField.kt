package com.irrgenius.android.ui.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.VisualTransformation
import com.irrgenius.android.utils.NumberFormatter

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
    isError: Boolean = false,
    errorMessage: String? = null,
    enabled: Boolean = true,
    suffix: String? = null
) {
    var textFieldValue by remember(value) { mutableStateOf(value) }
    
    OutlinedTextField(
        value = textFieldValue,
        onValueChange = { newValue ->
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
        },
        label = { Text(label) },
        modifier = modifier.fillMaxWidth(),
        enabled = enabled,
        isError = isError,
        supportingText = if (isError && errorMessage != null) {
            { Text(errorMessage, color = MaterialTheme.colorScheme.error) }
        } else null,
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
        colors = OutlinedTextFieldDefaults.colors()
    )
}