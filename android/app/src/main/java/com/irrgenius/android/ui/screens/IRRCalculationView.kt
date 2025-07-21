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
fun IRRCalculationView(
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
            value = uiState.irrInitialInvestment,
            onValueChange = { viewModel.updateIRRInputs(initial = it) },
            fieldType = InputFieldType.CURRENCY,
            isError = uiState.irrInitialInvestment.isNotEmpty() && 
                      (uiState.irrInitialInvestment.toDoubleOrNull() ?: 0.0) <= 0,
            errorMessage = "Initial investment must be greater than 0"
        )
        
        InputField(
            label = "Outcome Value",
            value = uiState.irrOutcome,
            onValueChange = { viewModel.updateIRRInputs(outcome = it) },
            fieldType = InputFieldType.CURRENCY,
            isError = uiState.irrOutcome.isNotEmpty() && 
                      (uiState.irrOutcome.toDoubleOrNull() ?: 0.0) <= 0,
            errorMessage = "Outcome must be greater than 0"
        )
        
        InputField(
            label = "Years",
            value = uiState.irrYears,
            onValueChange = { viewModel.updateIRRInputs(years = it) },
            fieldType = InputFieldType.NUMBER,
            suffix = "years",
            isError = uiState.irrYears.isNotEmpty() && 
                      (uiState.irrYears.toDoubleOrNull() ?: 0.0) <= 0,
            errorMessage = "Years must be greater than 0"
        )
        
        // Calculate Button
        CalculateButton(
            text = "Calculate IRR",
            onClick = { viewModel.calculate() },
            isLoading = uiState.isCalculating,
            enabled = uiState.irrInitialInvestment.isNotEmpty() && 
                     uiState.irrOutcome.isNotEmpty() && 
                     uiState.irrYears.isNotEmpty() &&
                     (uiState.irrInitialInvestment.toDoubleOrNull() ?: 0.0) > 0 &&
                     (uiState.irrOutcome.toDoubleOrNull() ?: 0.0) > 0 &&
                     (uiState.irrYears.toDoubleOrNull() ?: 0.0) > 0
        )
        
        // Results
        uiState.irrResult?.let { irr ->
            ResultCard(
                label = "Internal Rate of Return",
                value = NumberFormatter.formatPercent(irr),
                isHighlighted = true
            )
            
            // Additional metrics
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val initial = uiState.irrInitialInvestment.toDoubleOrNull() ?: 0.0
                val outcome = uiState.irrOutcome.toDoubleOrNull() ?: 0.0
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