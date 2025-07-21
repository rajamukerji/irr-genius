package com.irrgenius.android.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.irrgenius.android.data.models.CalculationMode

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ModeSelectorView(
    selectedMode: CalculationMode,
    onModeSelected: (CalculationMode) -> Unit,
    modifier: Modifier = Modifier
) {
    ScrollableTabRow(
        selectedTabIndex = selectedMode.ordinal,
        modifier = modifier,
        edgePadding = 16.dp,
        divider = { HorizontalDivider() }
    ) {
        Tab(
            selected = selectedMode == CalculationMode.CALCULATE_IRR,
            onClick = { onModeSelected(CalculationMode.CALCULATE_IRR) },
            text = { 
                Text(
                    "Calculate IRR",
                    style = MaterialTheme.typography.labelLarge
                )
            }
        )
        Tab(
            selected = selectedMode == CalculationMode.CALCULATE_OUTCOME,
            onClick = { onModeSelected(CalculationMode.CALCULATE_OUTCOME) },
            text = { 
                Text(
                    "Calculate Outcome",
                    style = MaterialTheme.typography.labelLarge
                )
            }
        )
        Tab(
            selected = selectedMode == CalculationMode.CALCULATE_INITIAL,
            onClick = { onModeSelected(CalculationMode.CALCULATE_INITIAL) },
            text = { 
                Text(
                    "Calculate Initial",
                    style = MaterialTheme.typography.labelLarge
                )
            }
        )
        Tab(
            selected = selectedMode == CalculationMode.CALCULATE_BLENDED,
            onClick = { onModeSelected(CalculationMode.CALCULATE_BLENDED) },
            text = { 
                Text(
                    "Blended IRR",
                    style = MaterialTheme.typography.labelLarge
                )
            }
        )
    }
}