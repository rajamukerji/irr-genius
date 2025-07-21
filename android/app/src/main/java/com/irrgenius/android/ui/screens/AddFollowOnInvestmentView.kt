package com.irrgenius.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.irrgenius.android.data.models.*
import com.irrgenius.android.ui.components.InputField
import com.irrgenius.android.ui.components.InputFieldType
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddFollowOnInvestmentView(
    onDismiss: () -> Unit,
    onAdd: (FollowOnInvestment) -> Unit,
    initialDate: LocalDate
) {
    var amount by remember { mutableStateOf("") }
    var investmentType by remember { mutableStateOf(InvestmentType.BUY) }
    var timingType by remember { mutableStateOf(TimingType.RELATIVE) }
    var absoluteDate by remember { mutableStateOf(LocalDate.now()) }
    var relativeTime by remember { mutableStateOf("1") }
    var relativeTimeUnit by remember { mutableStateOf(TimeUnit.YEARS) }
    var valuationMode by remember { mutableStateOf(ValuationMode.TAG_ALONG) }
    var valuationType by remember { mutableStateOf(ValuationType.COMPUTED) }
    var customValuation by remember { mutableStateOf("") }
    
    var showDatePicker by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add Follow-On Investment") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            val investment = FollowOnInvestment(
                                amount = amount.toDoubleOrNull() ?: 0.0,
                                investmentType = investmentType,
                                timingType = timingType,
                                absoluteDate = absoluteDate,
                                relativeTime = relativeTime.toDoubleOrNull() ?: 1.0,
                                relativeTimeUnit = relativeTimeUnit,
                                valuationMode = valuationMode,
                                valuationType = valuationType,
                                customValuation = customValuation.toDoubleOrNull() ?: 0.0
                            )
                            onAdd(investment)
                        },
                        enabled = amount.isNotEmpty() && 
                                 (timingType == TimingType.ABSOLUTE || relativeTime.isNotEmpty()) &&
                                 (valuationMode == ValuationMode.TAG_ALONG || customValuation.isNotEmpty())
                    ) {
                        Text("Add")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Amount Input
            InputField(
                label = "Investment Amount",
                value = amount,
                onValueChange = { amount = it },
                fieldType = InputFieldType.CURRENCY
            )
            
            // Investment Type Selection
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Investment Type",
                        style = MaterialTheme.typography.titleSmall
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        InvestmentType.values().forEach { type ->
                            FilterChip(
                                selected = investmentType == type,
                                onClick = { investmentType = type },
                                label = {
                                    Text(
                                        when (type) {
                                            InvestmentType.BUY -> "Buy"
                                            InvestmentType.SELL -> "Sell"
                                            InvestmentType.BUY_SELL -> "Buy/Sell"
                                        }
                                    )
                                },
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            }
            
            // Timing Configuration
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Timing",
                        style = MaterialTheme.typography.titleSmall
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            selected = timingType == TimingType.RELATIVE,
                            onClick = { timingType = TimingType.RELATIVE },
                            label = { Text("Relative") },
                            modifier = Modifier.weight(1f)
                        )
                        FilterChip(
                            selected = timingType == TimingType.ABSOLUTE,
                            onClick = { timingType = TimingType.ABSOLUTE },
                            label = { Text("Absolute") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                    
                    if (timingType == TimingType.RELATIVE) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            InputField(
                                label = "Time",
                                value = relativeTime,
                                onValueChange = { relativeTime = it },
                                fieldType = InputFieldType.NUMBER,
                                modifier = Modifier.weight(1f)
                            )
                            Box(modifier = Modifier.weight(1f)) {
                                OutlinedTextField(
                                    value = when (relativeTimeUnit) {
                                        TimeUnit.DAYS -> "Days"
                                        TimeUnit.MONTHS -> "Months"
                                        TimeUnit.YEARS -> "Years"
                                    },
                                    onValueChange = { },
                                    readOnly = true,
                                    label = { Text("Unit") },
                                    modifier = Modifier.fillMaxWidth(),
                                    trailingIcon = {
                                        ExposedDropdownMenuDefaults.TrailingIcon(
                                            expanded = false
                                        )
                                    }
                                )
                                DropdownMenu(
                                    expanded = false,
                                    onDismissRequest = { }
                                ) {
                                    TimeUnit.values().forEach { unit ->
                                        DropdownMenuItem(
                                            text = {
                                                Text(
                                                    when (unit) {
                                                        TimeUnit.DAYS -> "Days"
                                                        TimeUnit.MONTHS -> "Months"
                                                        TimeUnit.YEARS -> "Years"
                                                    }
                                                )
                                            },
                                            onClick = { relativeTimeUnit = unit }
                                        )
                                    }
                                }
                            }
                        }
                    } else {
                        OutlinedButton(
                            onClick = { showDatePicker = true },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = absoluteDate.format(DateTimeFormatter.ofPattern("MMM d, yyyy"))
                            )
                        }
                    }
                }
            }
            
            // Valuation Configuration
            if (investmentType != InvestmentType.SELL) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Valuation",
                            style = MaterialTheme.typography.titleSmall
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            FilterChip(
                                selected = valuationMode == ValuationMode.TAG_ALONG,
                                onClick = { valuationMode = ValuationMode.TAG_ALONG },
                                label = { Text("Tag-Along") },
                                modifier = Modifier.weight(1f)
                            )
                            FilterChip(
                                selected = valuationMode == ValuationMode.CUSTOM,
                                onClick = { valuationMode = ValuationMode.CUSTOM },
                                label = { Text("Custom") },
                                modifier = Modifier.weight(1f)
                            )
                        }
                        
                        if (valuationMode == ValuationMode.CUSTOM) {
                            InputField(
                                label = "Custom Valuation",
                                value = customValuation,
                                onValueChange = { customValuation = it },
                                fieldType = InputFieldType.CURRENCY
                            )
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                FilterChip(
                                    selected = valuationType == ValuationType.COMPUTED,
                                    onClick = { valuationType = ValuationType.COMPUTED },
                                    label = { Text("Computed") },
                                    modifier = Modifier.weight(1f)
                                )
                                FilterChip(
                                    selected = valuationType == ValuationType.SPECIFIED,
                                    onClick = { valuationType = ValuationType.SPECIFIED },
                                    label = { Text("Specified") },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    if (showDatePicker) {
        DatePickerDialog(
            onDateSelected = { date ->
                absoluteDate = date
                showDatePicker = false
            },
            onDismiss = { showDatePicker = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DatePickerDialog(
    onDateSelected: (LocalDate) -> Unit,
    onDismiss: () -> Unit
) {
    val datePickerState = rememberDatePickerState()
    
    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(
                onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        val date = LocalDate.ofEpochDay(millis / (24 * 60 * 60 * 1000))
                        onDateSelected(date)
                    }
                }
            ) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    ) {
        DatePicker(state = datePickerState)
    }
}