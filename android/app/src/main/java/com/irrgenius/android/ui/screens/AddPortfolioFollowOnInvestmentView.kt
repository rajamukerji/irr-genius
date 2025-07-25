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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.irrgenius.android.data.models.*
import com.irrgenius.android.ui.components.InputField
import com.irrgenius.android.ui.components.InputFieldType
import com.irrgenius.android.utils.NumberFormatter
import java.time.LocalDate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddPortfolioFollowOnInvestmentView(
    onDismiss: () -> Unit,
    onAdd: (FollowOnInvestment) -> Unit,
    initialInvestmentDate: LocalDate,
    modifier: Modifier = Modifier
) {
    var investmentType by remember { mutableStateOf(InvestmentType.BUY) }
    var unitPrice by remember { mutableStateOf("") }
    var numberOfUnits by remember { mutableStateOf("") }
    var timingType by remember { mutableStateOf(TimingType.ABSOLUTE) }
    var absoluteDate by remember { mutableStateOf(LocalDate.now().plusMonths(6)) }
    var relativeTime by remember { mutableStateOf("1") }
    var relativeTimeUnit by remember { mutableStateOf(TimeUnit.YEARS) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    // Computed values
    val calculatedAmount = remember(unitPrice, numberOfUnits) {
        val units = numberOfUnits.toDoubleOrNull() ?: 0.0
        val price = unitPrice.toDoubleOrNull() ?: 0.0
        units * price
    }
    
    val isValidInput = remember(unitPrice, numberOfUnits, timingType, absoluteDate, relativeTime) {
        val units = numberOfUnits.toDoubleOrNull() ?: 0.0
        val price = unitPrice.toDoubleOrNull() ?: 0.0
        val validBasics = units > 0 && price > 0
        
        val validTiming = when (timingType) {
            TimingType.ABSOLUTE -> absoluteDate.isAfter(initialInvestmentDate)
            TimingType.RELATIVE -> (relativeTime.toDoubleOrNull() ?: 0.0) > 0
        }
        
        validBasics && validTiming
    }
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Add Portfolio Investment",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            
            IconButton(onClick = onDismiss) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Close"
                )
            }
        }
        
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Investment Type
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Investment Type",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        InvestmentType.values().forEach { type ->
                            FilterChip(
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
                                selected = investmentType == type,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            }
            
            // Investment Details
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Investment Details",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    InputField(
                        label = "Unit Price",
                        value = unitPrice,
                        onValueChange = { unitPrice = it },
                        fieldType = InputFieldType.CURRENCY,
                        isError = unitPrice.isNotEmpty() && (unitPrice.toDoubleOrNull() ?: 0.0) <= 0,
                        errorMessage = "Unit price must be greater than 0"
                    )
                    
                    InputField(
                        label = "Number of Units",
                        value = numberOfUnits,
                        onValueChange = { numberOfUnits = it },
                        fieldType = InputFieldType.NUMBER,
                        isError = numberOfUnits.isNotEmpty() && (numberOfUnits.toDoubleOrNull() ?: 0.0) <= 0,
                        errorMessage = "Number of units must be greater than 0"
                    )
                    
                    // Total Amount Display
                    Card(
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.primaryContainer
                        )
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Total Investment Amount:",
                                style = MaterialTheme.typography.titleSmall
                            )
                            Text(
                                text = NumberFormatter.formatCurrency(calculatedAmount),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
            
            // Timing
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Timing",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            onClick = { timingType = TimingType.ABSOLUTE },
                            label = { Text("Specific Date") },
                            selected = timingType == TimingType.ABSOLUTE,
                            modifier = Modifier.weight(1f)
                        )
                        FilterChip(
                            onClick = { timingType = TimingType.RELATIVE },
                            label = { Text("Relative Time") },
                            selected = timingType == TimingType.RELATIVE,
                            modifier = Modifier.weight(1f)
                        )
                    }
                    
                    when (timingType) {
                        TimingType.ABSOLUTE -> {
                            // Date picker would go here - simplified for now
                            Text(
                                text = "Investment Date: ${absoluteDate}",
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        TimingType.RELATIVE -> {
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
                                    modifier = Modifier.weight(1f),
                                    isError = relativeTime.isNotEmpty() && (relativeTime.toDoubleOrNull() ?: 0.0) <= 0,
                                    errorMessage = "Time must be greater than 0"
                                )
                                
                                // Time unit selector - simplified
                                Text(
                                    text = when (relativeTimeUnit) {
                                        TimeUnit.DAYS -> "days"
                                        TimeUnit.MONTHS -> "months"
                                        TimeUnit.YEARS -> "years"
                                    },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                            
                            Text(
                                text = "after initial investment",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
            
            // Error message
            errorMessage?.let { message ->
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = message,
                        modifier = Modifier.padding(12.dp),
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
            
            // Add Button
            Button(
                onClick = {
                    try {
                        val investment = FollowOnInvestment.createValidated(
                            amount = calculatedAmount,
                            investmentType = investmentType,
                            timingType = timingType,
                            absoluteDate = absoluteDate,
                            relativeTime = relativeTime.toDoubleOrNull() ?: 1.0,
                            relativeTimeUnit = relativeTimeUnit,
                            valuationMode = ValuationMode.CUSTOM,
                            valuationType = ValuationType.SPECIFIED,
                            customValuation = unitPrice.toDoubleOrNull() ?: 0.0,
                            initialInvestmentDate = initialInvestmentDate
                        )
                        onAdd(investment)
                    } catch (e: Exception) {
                        errorMessage = e.message
                    }
                },
                enabled = isValidInput,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Add Investment Batch")
            }
        }
    }
}