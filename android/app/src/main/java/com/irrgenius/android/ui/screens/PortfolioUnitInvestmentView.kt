package com.irrgenius.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.irrgenius.android.data.models.*
import com.irrgenius.android.ui.components.*
import com.irrgenius.android.utils.NumberFormatter

@Composable
fun PortfolioUnitInvestmentView(
    uiState: MainUiState,
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    var showingValidationDetails by remember { mutableStateOf(false) }
    
    // Enhanced validation function
    val validationErrors = remember(uiState) {
        validatePortfolioInputs(uiState)
    }
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Title
        Text(
            text = "Portfolio Unit Investment",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        
        // Initial Investment Section
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "Initial Investment",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
                
                // Investment Type Selector
                Text(
                    text = "Investment Type",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("litigation", "patent", "debt").forEach { type ->
                        Button(
                            onClick = { viewModel.updatePortfolioInputs(investmentType = type) },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (uiState.portfolioInvestmentType == type) 
                                    MaterialTheme.colorScheme.primary 
                                else 
                                    MaterialTheme.colorScheme.surfaceVariant,
                                contentColor = if (uiState.portfolioInvestmentType == type) 
                                    MaterialTheme.colorScheme.onPrimary 
                                else 
                                    MaterialTheme.colorScheme.onSurfaceVariant
                            ),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(
                                text = type.capitalize(),
                                style = MaterialTheme.typography.labelMedium
                            )
                        }
                    }
                }
                
                InputField(
                    label = "Initial Investment Amount",
                    value = uiState.portfolioInitialInvestment,
                    onValueChange = { viewModel.updatePortfolioInputs(initialInvestment = it) },
                    fieldType = InputFieldType.CURRENCY,
                    isError = uiState.portfolioInitialInvestment.isNotEmpty() && 
                              (uiState.portfolioInitialInvestment.toDoubleOrNull() ?: 0.0) <= 0,
                    errorMessage = "Initial investment must be greater than 0"
                )
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    InputField(
                        label = "Unit Price",
                        value = uiState.portfolioUnitPrice,
                        onValueChange = { viewModel.updatePortfolioInputs(unitPrice = it) },
                        fieldType = InputFieldType.CURRENCY,
                        modifier = Modifier.weight(1f),
                        isError = uiState.portfolioUnitPrice.isNotEmpty() && 
                                  (uiState.portfolioUnitPrice.toDoubleOrNull() ?: 0.0) <= 0,
                        errorMessage = "Unit price must be greater than 0"
                    )
                    
                    // Auto-calculated units display
                    Column(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = "Number of Units",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                            ),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = uiState.portfolioNumberOfUnits.ifEmpty { "0.00" },
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium,
                                modifier = Modifier.padding(12.dp),
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    InputField(
                        label = "Success Rate",
                        value = uiState.portfolioSuccessRate,
                        onValueChange = { viewModel.updatePortfolioInputs(successRate = it) },
                        fieldType = InputFieldType.NUMBER,
                        suffix = "%",
                        modifier = Modifier.weight(1f),
                        isError = uiState.portfolioSuccessRate.isNotEmpty() && 
                                  ((uiState.portfolioSuccessRate.toDoubleOrNull() ?: 0.0) <= 0 ||
                                   (uiState.portfolioSuccessRate.toDoubleOrNull() ?: 0.0) > 100),
                        errorMessage = "Success rate must be between 0 and 100"
                    )
                    
                    InputField(
                        label = "Time Period",
                        value = uiState.portfolioTimeInMonths,
                        onValueChange = { viewModel.updatePortfolioInputs(timeInMonths = it) },
                        fieldType = InputFieldType.NUMBER,
                        suffix = "months",
                        modifier = Modifier.weight(1f),
                        isError = uiState.portfolioTimeInMonths.isNotEmpty() && 
                                  (uiState.portfolioTimeInMonths.toDoubleOrNull() ?: 0.0) <= 0,
                        errorMessage = "Time period must be greater than 0"
                    )
                }
                
                // Dynamic label based on investment type
                val outcomeLabel = when (uiState.portfolioInvestmentType) {
                    "litigation" -> "Expected Settlement per Case"
                    "patent" -> "Revenue per Patent"
                    else -> "Outcome per Unit"
                }
                
                InputField(
                    label = outcomeLabel,
                    value = uiState.portfolioOutcomePerUnit,
                    onValueChange = { viewModel.updatePortfolioInputs(outcomePerUnit = it) },
                    fieldType = InputFieldType.CURRENCY,
                    isError = uiState.portfolioOutcomePerUnit.isNotEmpty() && 
                              (uiState.portfolioOutcomePerUnit.toDoubleOrNull() ?: 0.0) <= 0,
                    errorMessage = "Outcome per unit must be greater than 0"
                )
                
                // Fee Structure Section
                Text(
                    text = "Fee Structure",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(top = 8.dp)
                )
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val topLineFeeLabel = when (uiState.portfolioInvestmentType) {
                        "litigation" -> "MDL Committee Fee"
                        else -> "Top-Line Fee"
                    }
                    
                    InputField(
                        label = "$topLineFeeLabel (%)",
                        value = uiState.portfolioTopLineFees,
                        onValueChange = { viewModel.updatePortfolioInputs(topLineFees = it) },
                        fieldType = InputFieldType.NUMBER,
                        modifier = Modifier.weight(1f),
                        isError = uiState.portfolioTopLineFees.isNotEmpty() && 
                                  ((uiState.portfolioTopLineFees.toDoubleOrNull() ?: 0.0) < 0 ||
                                   (uiState.portfolioTopLineFees.toDoubleOrNull() ?: 0.0) > 100),
                        errorMessage = "Fee must be between 0 and 100"
                    )
                    
                    InputField(
                        label = "Plaintiff Counsel (%)",
                        value = uiState.portfolioManagementFees,
                        onValueChange = { viewModel.updatePortfolioInputs(managementFees = it) },
                        fieldType = InputFieldType.NUMBER,
                        modifier = Modifier.weight(1f),
                        isError = uiState.portfolioManagementFees.isNotEmpty() && 
                                  ((uiState.portfolioManagementFees.toDoubleOrNull() ?: 0.0) < 0 ||
                                   (uiState.portfolioManagementFees.toDoubleOrNull() ?: 0.0) > 100),
                        errorMessage = "Fee must be between 0 and 100"
                    )
                }
                
                InputField(
                    label = "Investor Share (%)",
                    value = uiState.portfolioInvestorShare,
                    onValueChange = { viewModel.updatePortfolioInputs(investorShare = it) },
                    fieldType = InputFieldType.NUMBER,
                    isError = uiState.portfolioInvestorShare.isNotEmpty() && 
                              ((uiState.portfolioInvestorShare.toDoubleOrNull() ?: 0.0) < 0 ||
                               (uiState.portfolioInvestorShare.toDoubleOrNull() ?: 0.0) > 100),
                    errorMessage = "Investor share must be between 0 and 100"
                )
            }
        }
        
        // Enhanced Portfolio Summary Card
        val totalUnits = calculateTotalUnits(uiState)
        val totalInvestment = calculateTotalInvestment(uiState)
        val totalFollowOnUnits = calculateTotalFollowOnUnits(uiState)
        val averageUnitPrice = calculateAverageUnitPrice(uiState, totalUnits, totalFollowOnUnits, totalInvestment)
        
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Portfolio Summary",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    if (validationErrors.isNotEmpty()) {
                        IconButton(
                            onClick = { showingValidationDetails = !showingValidationDetails }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add, // Would use warning icon in real app
                                contentDescription = "Show validation details",
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
                
                // Initial investment metrics
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Initial Units:")
                    Text(
                        text = NumberFormatter.formatNumber(uiState.portfolioNumberOfUnits.toDoubleOrNull() ?: 0.0),
                        fontWeight = FontWeight.Medium
                    )
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Expected Successful Units:")
                    Text(
                        text = NumberFormatter.formatNumber(totalUnits),
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                
                if (uiState.portfolioFollowOnInvestments.isNotEmpty()) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Follow-on Units:")
                        Text(
                            text = NumberFormatter.formatNumber(totalFollowOnUnits),
                            fontWeight = FontWeight.Medium
                        )
                    }
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Total Portfolio Units:")
                        Text(
                            text = NumberFormatter.formatNumber(totalUnits + totalFollowOnUnits),
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.secondary
                        )
                    }
                }
                
                Divider()
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Total Investment:")
                    Text(
                        text = NumberFormatter.formatCurrency(totalInvestment),
                        fontWeight = FontWeight.Medium
                    )
                }
                
                if (averageUnitPrice > 0) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Average Unit Price:")
                        Text(
                            text = NumberFormatter.formatCurrency(averageUnitPrice),
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
                
                if (uiState.portfolioFollowOnInvestments.isNotEmpty()) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Investment Batches:")
                        Text(
                            text = "${uiState.portfolioFollowOnInvestments.size + 1}",
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
        }
        
        // Follow-on Investments Section
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Follow-on Investment Batches",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    IconButton(
                        onClick = { viewModel.setShowingAddPortfolioInvestment(true) }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Add follow-on investment",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
                
                if (uiState.portfolioFollowOnInvestments.isEmpty()) {
                    Text(
                        text = "No follow-on investments added",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    uiState.portfolioFollowOnInvestments.forEachIndexed { index, investment ->
                        PortfolioFollowOnInvestmentRow(
                            investment = investment,
                            initialDate = uiState.portfolioInitialDate,
                            onDelete = { viewModel.removePortfolioFollowOnInvestment(investment.id) }
                        )
                    }
                }
            }
        }
        
        // Enhanced Validation Display
        if (validationErrors.isNotEmpty()) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Input Validation",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                        
                        TextButton(
                            onClick = { showingValidationDetails = !showingValidationDetails }
                        ) {
                            Text(
                                text = if (showingValidationDetails) "Hide Details" else "Show Details",
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                    
                    if (showingValidationDetails) {
                        validationErrors.forEach { error ->
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.Top
                            ) {
                                Text(
                                    text = "• ",
                                    color = MaterialTheme.colorScheme.onErrorContainer,
                                    style = MaterialTheme.typography.bodySmall
                                )
                                Text(
                                    text = error,
                                    color = MaterialTheme.colorScheme.onErrorContainer,
                                    style = MaterialTheme.typography.bodySmall,
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    } else {
                        Text(
                            text = "${validationErrors.size} validation issue${if (validationErrors.size == 1) "" else "s"} found",
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
        }
        
        // Calculate Button
        CalculateButton(
            text = "Calculate Portfolio IRR",
            onClick = { 
                if (validationErrors.isEmpty()) {
                    viewModel.calculate()
                } else {
                    showingValidationDetails = true
                }
            },
            isLoading = uiState.isCalculating,
            enabled = isPortfolioInputValid(uiState)
        )
        
        // Enhanced Results Display with Unit-Based Metrics
        uiState.portfolioResult?.let { result ->
            // Primary Result
            ResultCard(
                label = "Portfolio Unit IRR",
                value = NumberFormatter.formatPercent(result),
                isHighlighted = true
            )
            
            // Save Button
            Button(
                onClick = {
                    val calculation = createPortfolioCalculationFromInputs(uiState, result)
                    viewModel.autoSaveManager.showSaveDialog(calculation)
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Add, // Would use save icon in real app
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Save Calculation")
            }
            
            // Unit-Based Metrics Grid
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Unit-Based Performance Metrics",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    // First row of metrics
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        val totalPortfolioUnits = totalUnits + totalFollowOnUnits
                        val avgUnitReturn = if (totalPortfolioUnits > 0) result / totalPortfolioUnits else 0.0
                        
                        ResultCard(
                            label = "Avg Unit IRR",
                            value = NumberFormatter.formatPercent(avgUnitReturn),
                            modifier = Modifier.weight(1f)
                        )
                        
                        val costPerUnit = if (totalPortfolioUnits > 0) totalInvestment / totalPortfolioUnits else 0.0
                        ResultCard(
                            label = "Cost Per Unit",
                            value = NumberFormatter.formatCurrency(costPerUnit),
                            modifier = Modifier.weight(1f)
                        )
                    }
                    
                    // Second row of metrics
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        val successRateDecimal = (uiState.portfolioSuccessRate.toDoubleOrNull() ?: 100.0) / 100.0
                        val failureRate = (1.0 - successRateDecimal) * 100.0
                        
                        ResultCard(
                            label = "Success Rate",
                            value = "${NumberFormatter.formatNumber(successRateDecimal * 100)}%",
                            modifier = Modifier.weight(1f)
                        )
                        
                        ResultCard(
                            label = "Risk (Failure)",
                            value = "${NumberFormatter.formatNumber(failureRate)}%",
                            modifier = Modifier.weight(1f)
                        )
                    }
                    
                    // Third row - Investment efficiency metrics
                    if (uiState.portfolioFollowOnInvestments.isNotEmpty()) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            val initialInvestmentRatio = (uiState.portfolioInitialInvestment.toDoubleOrNull() ?: 0.0) / totalInvestment
                            val followOnRatio = 1.0 - initialInvestmentRatio
                            
                            ResultCard(
                                label = "Initial Investment",
                                value = "${NumberFormatter.formatNumber(initialInvestmentRatio * 100)}%",
                                modifier = Modifier.weight(1f)
                            )
                            
                            ResultCard(
                                label = "Follow-on Investment",
                                value = "${NumberFormatter.formatNumber(followOnRatio * 100)}%",
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            }
            
            // Portfolio Composition Summary
            if (uiState.portfolioFollowOnInvestments.isNotEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Investment Batch Breakdown",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Medium
                        )
                        
                        // Initial batch
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Initial Batch:")
                            Text(
                                text = "${NumberFormatter.formatNumber(totalUnits)} units (${NumberFormatter.formatCurrency(uiState.portfolioInitialInvestment.toDoubleOrNull() ?: 0.0)})",
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                        
                        // Follow-on batches
                        uiState.portfolioFollowOnInvestments.forEachIndexed { index, investment ->
                            val units = if (investment.customValuation > 0) investment.amount / investment.customValuation else 0.0
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Batch ${index + 2}:")
                                Text(
                                    text = "${NumberFormatter.formatNumber(units)} units (${NumberFormatter.formatCurrency(investment.amount)})",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                        
                        Divider()
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "Total Portfolio:",
                                fontWeight = FontWeight.Medium
                            )
                            Text(
                                text = "${NumberFormatter.formatNumber(totalUnits + totalFollowOnUnits)} units (${NumberFormatter.formatCurrency(totalInvestment)})",
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }
            }
            
            // Growth Chart
            GrowthChartView(
                growthPoints = uiState.growthPoints,
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}

@Composable
private fun PortfolioFollowOnInvestmentRow(
    investment: FollowOnInvestment,
    initialDate: java.time.LocalDate,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Investment Batch",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.primary
                )
                
                Button(
                    onClick = onDelete,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    ),
                    modifier = Modifier.size(40.dp),
                    contentPadding = PaddingValues(0.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Delete investment",
                        tint = MaterialTheme.colorScheme.onError,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
            
            // Unit details in a grid layout
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Units column
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    Text(
                        text = "Units",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    val units = if (investment.customValuation > 0) {
                        investment.amount / investment.customValuation
                    } else {
                        0.0
                    }
                    Text(
                        text = NumberFormatter.formatNumber(units),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                }
                
                // Unit Price column
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = "Unit Price",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = NumberFormatter.formatCurrency(investment.customValuation),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                }
                
                // Total Investment column
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = "Total Investment",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = NumberFormatter.formatCurrency(investment.amount),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
            
            // Timing information
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Add, // Would use calendar icon in real app
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = when (investment.timingType) {
                        TimingType.ABSOLUTE -> {
                            val formatter = java.time.format.DateTimeFormatter.ofPattern("MMM d, yyyy")
                            investment.absoluteDate.format(formatter)
                        }
                        TimingType.RELATIVE -> {
                            val timeStr = NumberFormatter.formatNumber(investment.relativeTime)
                            val unitStr = when (investment.relativeTimeUnit) {
                                TimeUnit.DAYS -> "day"
                                TimeUnit.MONTHS -> "month"
                                TimeUnit.YEARS -> "year"
                            }
                            val plural = if (investment.relativeTime != 1.0) "s" else ""
                            "$timeStr $unitStr$plural after initial"
                        }
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            // Investment type badge
            Row(
                modifier = Modifier.fillMaxWidth()
            ) {
                Surface(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    shape = RoundedCornerShape(4.dp)
                ) {
                    Text(
                        text = when (investment.investmentType) {
                            InvestmentType.BUY -> "Buy"
                            InvestmentType.SELL -> "Sell"
                            InvestmentType.BUY_SELL -> "Buy/Sell"
                        },
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                    )
                }
                
                Spacer(modifier = Modifier.weight(1f))
                
                Text(
                    text = "Delete",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}

private fun calculateTotalUnits(uiState: MainUiState): Double {
    val units = uiState.portfolioNumberOfUnits.toDoubleOrNull() ?: 0.0
    val successRate = (uiState.portfolioSuccessRate.toDoubleOrNull() ?: 100.0) / 100.0
    return units * successRate
}

private fun calculateTotalInvestment(uiState: MainUiState): Double {
    val initial = uiState.portfolioInitialInvestment.toDoubleOrNull() ?: 0.0
    val followOnTotal = uiState.portfolioFollowOnInvestments.sumOf { it.amount }
    return initial + followOnTotal
}

private fun calculateTotalFollowOnUnits(uiState: MainUiState): Double {
    return uiState.portfolioFollowOnInvestments.sumOf { investment ->
        if (investment.customValuation > 0) {
            investment.amount / investment.customValuation
        } else {
            0.0
        }
    }
}

private fun calculateAverageUnitPrice(
    uiState: MainUiState,
    totalUnits: Double,
    totalFollowOnUnits: Double,
    totalInvestment: Double
): Double {
    val totalUnitsIncludingFollowOn = totalUnits + totalFollowOnUnits
    return if (totalUnitsIncludingFollowOn > 0) {
        totalInvestment / totalUnitsIncludingFollowOn
    } else {
        0.0
    }
}

private fun validatePortfolioInputs(uiState: MainUiState): List<String> {
    val errors = mutableListOf<String>()
    
    if (uiState.portfolioInitialInvestment.isEmpty()) {
        errors.add("Initial investment amount is required")
    } else if ((uiState.portfolioInitialInvestment.toDoubleOrNull() ?: 0.0) <= 0) {
        errors.add("Initial investment must be greater than 0")
    }
    
    if (uiState.portfolioUnitPrice.isEmpty()) {
        errors.add("Unit price is required")
    } else if ((uiState.portfolioUnitPrice.toDoubleOrNull() ?: 0.0) <= 0) {
        errors.add("Unit price must be greater than 0")
    }
    
    if (uiState.portfolioOutcomePerUnit.isEmpty()) {
        errors.add("Outcome per unit is required")
    } else if ((uiState.portfolioOutcomePerUnit.toDoubleOrNull() ?: 0.0) <= 0) {
        errors.add("Outcome per unit must be greater than 0")
    }
    
    if (uiState.portfolioSuccessRate.isEmpty()) {
        errors.add("Success rate is required")
    } else {
        val rate = uiState.portfolioSuccessRate.toDoubleOrNull() ?: 0.0
        if (rate <= 0 || rate > 100) {
            errors.add("Success rate must be between 0 and 100")
        }
    }
    
    if (uiState.portfolioTimeInMonths.isEmpty()) {
        errors.add("Time period is required")
    } else if ((uiState.portfolioTimeInMonths.toDoubleOrNull() ?: 0.0) <= 0) {
        errors.add("Time period must be greater than 0")
    }
    
    // Validate fee structure
    val topLineFees = uiState.portfolioTopLineFees.toDoubleOrNull()
    if (topLineFees != null && (topLineFees < 0 || topLineFees > 100)) {
        errors.add("Top-line fees must be between 0 and 100")
    }
    
    val managementFees = uiState.portfolioManagementFees.toDoubleOrNull()
    if (managementFees != null && (managementFees < 0 || managementFees > 100)) {
        errors.add("Management fees must be between 0 and 100")
    }
    
    val investorShare = uiState.portfolioInvestorShare.toDoubleOrNull()
    if (investorShare != null && (investorShare < 0 || investorShare > 100)) {
        errors.add("Investor share must be between 0 and 100")
    }
    
    // Validate follow-on investments
    uiState.portfolioFollowOnInvestments.forEachIndexed { index, investment ->
        try {
            investment.validate(uiState.portfolioInitialDate)
        } catch (e: Exception) {
            errors.add("Follow-on investment #${index + 1}: ${e.message}")
        }
    }
    
    return errors
}

private fun isPortfolioInputValid(uiState: MainUiState): Boolean {
    return uiState.portfolioInitialInvestment.isNotEmpty() &&
           uiState.portfolioUnitPrice.isNotEmpty() &&
           uiState.portfolioOutcomePerUnit.isNotEmpty() &&
           uiState.portfolioSuccessRate.isNotEmpty() &&
           uiState.portfolioTimeInMonths.isNotEmpty() &&
           (uiState.portfolioInitialInvestment.toDoubleOrNull() ?: 0.0) > 0 &&
           (uiState.portfolioUnitPrice.toDoubleOrNull() ?: 0.0) > 0 &&
           (uiState.portfolioOutcomePerUnit.toDoubleOrNull() ?: 0.0) > 0 &&
           (uiState.portfolioSuccessRate.toDoubleOrNull() ?: 0.0) > 0 &&
           (uiState.portfolioSuccessRate.toDoubleOrNull() ?: 0.0) <= 100 &&
           (uiState.portfolioTimeInMonths.toDoubleOrNull() ?: 0.0) > 0 &&
           (uiState.portfolioTopLineFees.toDoubleOrNull() ?: 0.0) >= 0 &&
           (uiState.portfolioTopLineFees.toDoubleOrNull() ?: 0.0) <= 100 &&
           (uiState.portfolioManagementFees.toDoubleOrNull() ?: 0.0) >= 0 &&
           (uiState.portfolioManagementFees.toDoubleOrNull() ?: 0.0) <= 100 &&
           (uiState.portfolioInvestorShare.toDoubleOrNull() ?: 0.0) >= 0 &&
           (uiState.portfolioInvestorShare.toDoubleOrNull() ?: 0.0) <= 100
}

private fun createPortfolioCalculationFromInputs(uiState: MainUiState, result: Double): SavedCalculation {
    return SavedCalculation(
        id = java.util.UUID.randomUUID().toString(),
        name = "Untitled Portfolio Unit Investment",
        calculationType = CalculationMode.PORTFOLIO_UNIT_INVESTMENT,
        createdDate = java.time.LocalDateTime.now(),
        modifiedDate = java.time.LocalDateTime.now(),
        projectId = null,
        initialInvestment = uiState.portfolioInitialInvestment.toDoubleOrNull(),
        outcomeAmount = null,
        timeInMonths = uiState.portfolioTimeInMonths.toDoubleOrNull(),
        irr = null,
        unitPrice = uiState.portfolioUnitPrice.toDoubleOrNull(),
        successRate = uiState.portfolioSuccessRate.toDoubleOrNull(),
        outcomePerUnit = uiState.portfolioOutcomePerUnit.toDoubleOrNull(),
        investorShare = uiState.portfolioInvestorShare.toDoubleOrNull(),
        feePercentage = uiState.portfolioTopLineFees.toDoubleOrNull(),
        calculatedResult = result,
        growthPointsJson = null, // Could serialize uiState.growthPoints to JSON if needed
        notes = null,
        tags = null // Could serialize tags to JSON if needed
    )
}