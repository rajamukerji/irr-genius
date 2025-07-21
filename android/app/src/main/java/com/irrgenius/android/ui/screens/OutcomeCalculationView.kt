package com.irrgenius.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.irrgenius.android.ui.components.*
import com.irrgenius.android.utils.NumberFormatter

@Composable
fun OutcomeCalculationView(
    uiState: MainUiState,
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Input Fields
        InputField(
            label = "Initial Investment",
            value = uiState.outcomeInitialInvestment,
            onValueChange = { viewModel.updateOutcomeInputs(initial = it) },
            fieldType = InputFieldType.CURRENCY,
            isError = uiState.outcomeInitialInvestment.isNotEmpty() && 
                      (uiState.outcomeInitialInvestment.toDoubleOrNull() ?: 0.0) <= 0,
            errorMessage = "Initial investment must be greater than 0"
        )
        
        InputField(
            label = "Target IRR",
            value = uiState.outcomeIRR,
            onValueChange = { viewModel.updateOutcomeInputs(irr = it) },
            fieldType = InputFieldType.NUMBER,
            suffix = "%",
            isError = uiState.outcomeIRR.isNotEmpty() && 
                      uiState.outcomeIRR.toDoubleOrNull() == null,
            errorMessage = "Please enter a valid IRR percentage"
        )
        
        InputField(
            label = "Years",
            value = uiState.outcomeYears,
            onValueChange = { viewModel.updateOutcomeInputs(years = it) },
            fieldType = InputFieldType.NUMBER,
            suffix = "years",
            isError = uiState.outcomeYears.isNotEmpty() && 
                      (uiState.outcomeYears.toDoubleOrNull() ?: 0.0) <= 0,
            errorMessage = "Years must be greater than 0"
        )
        
        // Calculate Button
        CalculateButton(
            text = "Calculate Future Value",
            onClick = { viewModel.calculate() },
            isLoading = uiState.isCalculating,
            enabled = uiState.outcomeInitialInvestment.isNotEmpty() && 
                     uiState.outcomeIRR.isNotEmpty() && 
                     uiState.outcomeYears.isNotEmpty() &&
                     (uiState.outcomeInitialInvestment.toDoubleOrNull() ?: 0.0) > 0 &&
                     uiState.outcomeIRR.toDoubleOrNull() != null &&
                     (uiState.outcomeYears.toDoubleOrNull() ?: 0.0) > 0
        )
        
        // Results
        uiState.outcomeResult?.let { outcome ->
            ResultCard(
                label = "Future Value",
                value = NumberFormatter.formatCurrency(outcome),
                isHighlighted = true
            )
            
            // Additional metrics
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val initial = uiState.outcomeInitialInvestment.toDoubleOrNull() ?: 0.0
                val totalReturn = if (initial > 0) (outcome - initial) / initial else 0.0
                val multiple = if (initial > 0) outcome / initial else 0.0
                
                ResultCard(
                    label = "Total Return",
                    value = NumberFormatter.formatPercent(totalReturn),
                    modifier = Modifier.weight(1f)
                )
                
                ResultCard(
                    label = "Multiple",
                    value = "${NumberFormatter.formatNumber(multiple)}x",
                    modifier = Modifier.weight(1f)
                )
            }
            
            // Growth Chart
            GrowthChartView(
                growthPoints = uiState.growthPoints,
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}