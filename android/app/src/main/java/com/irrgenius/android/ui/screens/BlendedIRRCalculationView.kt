package com.irrgenius.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.irrgenius.android.ui.components.*
import com.irrgenius.android.utils.NumberFormatter

@Composable
fun BlendedIRRCalculationView(
    uiState: MainUiState,
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    var showAddInvestment by remember { mutableStateOf(false) }
    
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        contentPadding = PaddingValues(bottom = 16.dp)
    ) {
        item {
            // Basic inputs
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                InputField(
                    label = "Initial Investment",
                    value = uiState.blendedInitialInvestment,
                    onValueChange = { viewModel.updateBlendedInputs(initial = it) },
                    fieldType = InputFieldType.CURRENCY,
                    isError = uiState.blendedInitialInvestment.isNotEmpty() && 
                              (uiState.blendedInitialInvestment.toDoubleOrNull() ?: 0.0) <= 0,
                    errorMessage = "Initial investment must be greater than 0"
                )
                
                InputField(
                    label = "Final Outcome",
                    value = uiState.blendedOutcome,
                    onValueChange = { viewModel.updateBlendedInputs(outcome = it) },
                    fieldType = InputFieldType.CURRENCY,
                    isError = uiState.blendedOutcome.isNotEmpty() && 
                              (uiState.blendedOutcome.toDoubleOrNull() ?: 0.0) <= 0,
                    errorMessage = "Final outcome must be greater than 0"
                )
                
                InputField(
                    label = "Total Years",
                    value = uiState.blendedYears,
                    onValueChange = { viewModel.updateBlendedInputs(years = it) },
                    fieldType = InputFieldType.NUMBER,
                    suffix = "years",
                    isError = uiState.blendedYears.isNotEmpty() && 
                              (uiState.blendedYears.toDoubleOrNull() ?: 0.0) <= 0,
                    errorMessage = "Years must be greater than 0"
                )
            }
        }
        
        item {
            // Follow-on investments section
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
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Follow-On Investments (${uiState.blendedFollowOnInvestments.size})",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium
                        )
                        
                        IconButton(
                            onClick = { showAddInvestment = true }
                        ) {
                            Icon(
                                Icons.Default.Add,
                                contentDescription = "Add follow-on investment",
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                    
                    if (uiState.blendedFollowOnInvestments.isEmpty()) {
                        Text(
                            text = "No follow-on investments added. Tap + to add investments at different times.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
        
        // Follow-on investment list
        items(uiState.blendedFollowOnInvestments) { investment ->
            FollowOnInvestmentRow(
                investment = investment,
                initialDate = uiState.blendedInitialDate,
                onDelete = { viewModel.removeFollowOnInvestment(investment.id) }
            )
        }
        
        item {
            // Calculate Button
            CalculateButton(
                text = "Calculate Blended IRR",
                onClick = { viewModel.calculate() },
                isLoading = uiState.isCalculating,
                enabled = uiState.blendedInitialInvestment.isNotEmpty() && 
                         uiState.blendedOutcome.isNotEmpty() && 
                         uiState.blendedYears.isNotEmpty() &&
                         (uiState.blendedInitialInvestment.toDoubleOrNull() ?: 0.0) > 0 &&
                         (uiState.blendedOutcome.toDoubleOrNull() ?: 0.0) > 0 &&
                         (uiState.blendedYears.toDoubleOrNull() ?: 0.0) > 0
            )
        }
        
        // Results
        uiState.blendedResult?.let { irr ->
            item {
                ResultCard(
                    label = "Blended IRR",
                    value = NumberFormatter.formatPercent(irr),
                    isHighlighted = true
                )
            }
            
            item {
                // Additional metrics
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val initial = uiState.blendedInitialInvestment.toDoubleOrNull() ?: 0.0
                    val outcome = uiState.blendedOutcome.toDoubleOrNull() ?: 0.0
                    val followOnTotal = uiState.blendedFollowOnInvestments
                        .filter { it.investmentType != com.irrgenius.android.data.models.InvestmentType.SELL }
                        .sumOf { it.amount }
                    val totalInvested = initial + followOnTotal
                    
                    val totalReturn = if (totalInvested > 0) (outcome - totalInvested) / totalInvested else 0.0
                    val multiple = if (totalInvested > 0) outcome / totalInvested else 0.0
                    
                    ResultCard(
                        label = "Total Invested",
                        value = NumberFormatter.formatCurrency(totalInvested),
                        modifier = Modifier.weight(1f)
                    )
                    
                    ResultCard(
                        label = "Multiple",
                        value = "${NumberFormatter.formatNumber(multiple)}x",
                        modifier = Modifier.weight(1f)
                    )
                }
            }
            
            item {
                // Growth Chart
                GrowthChartView(
                    growthPoints = uiState.growthPoints,
                    showFollowOnMarkers = uiState.blendedFollowOnInvestments.isNotEmpty(),
                    modifier = Modifier.padding(top = 8.dp)
                )
            }
        }
    }
    
    if (showAddInvestment) {
        AddFollowOnInvestmentView(
            onDismiss = { showAddInvestment = false },
            onAdd = { investment ->
                viewModel.addFollowOnInvestment(investment)
                showAddInvestment = false
            },
            initialDate = uiState.blendedInitialDate
        )
    }
}