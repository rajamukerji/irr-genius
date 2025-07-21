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
fun InitialCalculationView(
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
            label = "Target Outcome",
            value = uiState.initialOutcome,
            onValueChange = { viewModel.updateInitialInputs(outcome = it) },
            fieldType = InputFieldType.CURRENCY,
            isError = uiState.initialOutcome.isNotEmpty() && 
                      (uiState.initialOutcome.toDoubleOrNull() ?: 0.0) <= 0,
            errorMessage = "Target outcome must be greater than 0"
        )
        
        InputField(
            label = "Target IRR",
            value = uiState.initialIRR,
            onValueChange = { viewModel.updateInitialInputs(irr = it) },
            fieldType = InputFieldType.NUMBER,
            suffix = "%",
            isError = uiState.initialIRR.isNotEmpty() && 
                      uiState.initialIRR.toDoubleOrNull() == null,
            errorMessage = "Please enter a valid IRR percentage"
        )
        
        InputField(
            label = "Years",
            value = uiState.initialYears,
            onValueChange = { viewModel.updateInitialInputs(years = it) },
            fieldType = InputFieldType.NUMBER,
            suffix = "years",
            isError = uiState.initialYears.isNotEmpty() && 
                      (uiState.initialYears.toDoubleOrNull() ?: 0.0) <= 0,
            errorMessage = "Years must be greater than 0"
        )
        
        // Calculate Button
        CalculateButton(
            text = "Calculate Required Investment",
            onClick = { viewModel.calculate() },
            isLoading = uiState.isCalculating,
            enabled = uiState.initialOutcome.isNotEmpty() && 
                     uiState.initialIRR.isNotEmpty() && 
                     uiState.initialYears.isNotEmpty() &&
                     (uiState.initialOutcome.toDoubleOrNull() ?: 0.0) > 0 &&
                     uiState.initialIRR.toDoubleOrNull() != null &&
                     (uiState.initialYears.toDoubleOrNull() ?: 0.0) > 0
        )
        
        // Results
        uiState.initialResult?.let { initial ->
            ResultCard(
                label = "Required Initial Investment",
                value = NumberFormatter.formatCurrency(initial),
                isHighlighted = true
            )
            
            // Additional metrics
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val outcome = uiState.initialOutcome.toDoubleOrNull() ?: 0.0
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