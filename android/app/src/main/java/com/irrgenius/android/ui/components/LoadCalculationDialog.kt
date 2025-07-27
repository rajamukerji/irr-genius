package com.irrgenius.android.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.irrgenius.android.data.AutoSaveManager
import com.irrgenius.android.data.models.CalculationMode
import com.irrgenius.android.data.models.Project
import com.irrgenius.android.data.models.SavedCalculation
import com.irrgenius.android.data.displayName
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class, ExperimentalComposeUiApi::class)
@Composable
fun LoadCalculationDialog(
    autoSaveManager: AutoSaveManager,
    calculations: List<SavedCalculation>,
    projects: List<Project>,
    onDismiss: () -> Unit,
    onCalculationSelected: (SavedCalculation) -> Unit
) {
    var searchText by remember { mutableStateOf("") }
    var selectedCalculationType by remember { mutableStateOf<CalculationMode?>(null) }
    var selectedProject by remember { mutableStateOf<Project?>(null) }
    var showingDuplicateAlert by remember { mutableStateOf(false) }
    var calculationToDuplicate by remember { mutableStateOf<SavedCalculation?>(null) }
    
    val keyboardController = LocalSoftwareKeyboardController.current
    
    val filteredCalculations = remember(calculations, searchText, selectedCalculationType, selectedProject) {
        calculations.filter { calculation ->
            val matchesSearch = searchText.isEmpty() || 
                calculation.name.contains(searchText, ignoreCase = true) ||
                (calculation.notes?.contains(searchText, ignoreCase = true) ?: false)
            
            val matchesType = selectedCalculationType == null || 
                calculation.calculationType == selectedCalculationType
            
            val matchesProject = selectedProject == null || 
                calculation.projectId == selectedProject?.id
            
            matchesSearch && matchesType && matchesProject
        }
    }
    
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false
        )
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.9f)
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier.fillMaxSize()
            ) {
                // Header
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp, 24.dp, 24.dp, 16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Load Calculation",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
                
                // Search and Filters
                Column(
                    modifier = Modifier.padding(horizontal = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Search Bar
                    OutlinedTextField(
                        value = searchText,
                        onValueChange = { searchText = it },
                        label = { Text("Search calculations...") },
                        leadingIcon = {
                            Icon(Icons.Default.Search, contentDescription = "Search")
                        },
                        trailingIcon = {
                            if (searchText.isNotEmpty()) {
                                IconButton(onClick = { searchText = "" }) {
                                    Icon(Icons.Default.Clear, contentDescription = "Clear")
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(
                            onSearch = { keyboardController?.hide() }
                        )
                    )
                    
                    // Filters Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Calculation Type Filter
                        var showTypeDropdown by remember { mutableStateOf(false) }
                        
                        ExposedDropdownMenuBox(
                            expanded = showTypeDropdown,
                            onExpandedChange = { showTypeDropdown = it },
                            modifier = Modifier.weight(1f)
                        ) {
                            OutlinedTextField(
                                value = selectedCalculationType?.displayName ?: "All Types",
                                onValueChange = { },
                                readOnly = true,
                                label = { Text("Type") },
                                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = showTypeDropdown) },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .menuAnchor()
                            )
                            
                            ExposedDropdownMenu(
                                expanded = showTypeDropdown,
                                onDismissRequest = { showTypeDropdown = false }
                            ) {
                                DropdownMenuItem(
                                    text = { Text("All Types") },
                                    onClick = {
                                        selectedCalculationType = null
                                        showTypeDropdown = false
                                    }
                                )
                                
                                CalculationMode.values().forEach { mode ->
                                    DropdownMenuItem(
                                        text = { Text(mode.displayName) },
                                        onClick = {
                                            selectedCalculationType = mode
                                            showTypeDropdown = false
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Project Filter
                        var showProjectDropdown by remember { mutableStateOf(false) }
                        
                        ExposedDropdownMenuBox(
                            expanded = showProjectDropdown,
                            onExpandedChange = { showProjectDropdown = it },
                            modifier = Modifier.weight(1f)
                        ) {
                            OutlinedTextField(
                                value = selectedProject?.name ?: "All Projects",
                                onValueChange = { },
                                readOnly = true,
                                label = { Text("Project") },
                                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = showProjectDropdown) },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .menuAnchor()
                            )
                            
                            ExposedDropdownMenu(
                                expanded = showProjectDropdown,
                                onDismissRequest = { showProjectDropdown = false }
                            ) {
                                DropdownMenuItem(
                                    text = { Text("All Projects") },
                                    onClick = {
                                        selectedProject = null
                                        showProjectDropdown = false
                                    }
                                )
                                
                                projects.forEach { project ->
                                    DropdownMenuItem(
                                        text = {
                                            Row(
                                                verticalAlignment = Alignment.CenterVertically,
                                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                                            ) {
                                                project.color?.let { color ->
                                                    Box(
                                                        modifier = Modifier
                                                            .size(12.dp)
                                                            .background(
                                                                Color(android.graphics.Color.parseColor(color)),
                                                                RoundedCornerShape(6.dp)
                                                            )
                                                    )
                                                }
                                                Text(project.name)
                                            }
                                        },
                                        onClick = {
                                            selectedProject = project
                                            showProjectDropdown = false
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Divider()
                
                // Calculations List
                if (filteredCalculations.isEmpty()) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            Icons.Default.Home,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = "No calculations found",
                            style = MaterialTheme.typography.headlineSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        if (searchText.isNotEmpty()) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "Try adjusting your search or filters",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(24.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(filteredCalculations) { calculation ->
                            CalculationLoadCard(
                                calculation = calculation,
                                onLoad = {
                                    onCalculationSelected(calculation)
                                    onDismiss()
                                },
                                onDuplicate = {
                                    calculationToDuplicate = calculation
                                    showingDuplicateAlert = true
                                },
                                onViewHistory = {
                                    // TODO: Implement history view
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Duplicate Alert Dialog
    if (showingDuplicateAlert) {
        AlertDialog(
            onDismissRequest = { showingDuplicateAlert = false },
            title = { Text("Duplicate Calculation") },
            text = { Text("This will create a copy of the calculation that you can modify independently.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        calculationToDuplicate?.let { calculation ->
                            autoSaveManager.duplicateCalculation(calculation)
                        }
                        showingDuplicateAlert = false
                    }
                ) {
                    Text("Duplicate")
                }
            },
            dismissButton = {
                TextButton(onClick = { showingDuplicateAlert = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun CalculationLoadCard(
    calculation: SavedCalculation,
    onLoad: () -> Unit,
    onDuplicate: () -> Unit,
    onViewHistory: () -> Unit
) {
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
            // Header Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = calculation.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    
                    Text(
                        text = calculation.calculationType.displayName,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                Column(
                    horizontalAlignment = Alignment.End,
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    calculation.calculatedResult?.let { result ->
                        Text(
                            text = formatResult(result, calculation.calculationType),
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                    
                    Text(
                        text = calculation.modifiedDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy")),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            // Notes
            calculation.notes?.takeIf { it.isNotEmpty() }?.let { notes ->
                Text(
                    text = notes,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
            
            // Tags
            val tags = calculation.getTagsFromJson()
            if (tags.isNotEmpty()) {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    items(tags) { tag ->
                        AssistChip(
                            onClick = { },
                            label = {
                                Text(
                                    text = tag,
                                    style = MaterialTheme.typography.labelSmall
                                )
                            },
                            modifier = Modifier.height(24.dp)
                        )
                    }
                }
            }
            
            // Action Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onLoad,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Load")
                }
                
                OutlinedButton(
                    onClick = onDuplicate
                ) {
                    Text("Duplicate")
                }
                
                OutlinedButton(
                    onClick = onViewHistory
                ) {
                    Text("History")
                }
            }
        }
    }
}

private fun formatResult(result: Double, calculationType: CalculationMode): String {
    return when (calculationType) {
        CalculationMode.CALCULATE_IRR,
        CalculationMode.CALCULATE_BLENDED,
        CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> {
            String.format("%.2f%%", result)
        }
        CalculationMode.CALCULATE_OUTCOME,
        CalculationMode.CALCULATE_INITIAL -> {
            String.format("$%.2f", result)
        }
    }
}