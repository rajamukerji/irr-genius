package com.irrgenius.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.irrgenius.android.data.models.CalculationMode
import com.irrgenius.android.ui.components.*
import com.irrgenius.android.ui.screens.*
import com.irrgenius.android.ui.theme.IRRGeniusTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            IRRGeniusTheme {
                MainScreen()
            }
        }
    }
}

@Composable
fun MainScreen(
    viewModel: MainViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Header
        HeaderView()
        
        // Mode Selector
        ModeSelectorView(
            selectedMode = uiState.calculationMode,
            onModeSelected = { mode -> viewModel.setCalculationMode(mode) }
        )
        
        // Content based on selected mode
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            when (uiState.calculationMode) {
                CalculationMode.CALCULATE_IRR -> IRRCalculationView(uiState, viewModel)
                CalculationMode.CALCULATE_OUTCOME -> OutcomeCalculationView(uiState, viewModel)
                CalculationMode.CALCULATE_INITIAL -> InitialCalculationView(uiState, viewModel)
                CalculationMode.CALCULATE_BLENDED -> BlendedIRRCalculationView(uiState, viewModel)
            }
        }
    }
}

