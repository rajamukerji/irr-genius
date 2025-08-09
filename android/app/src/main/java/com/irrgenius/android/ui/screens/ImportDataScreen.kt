package com.irrgenius.android.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.viewmodel.compose.viewModel
import com.irrgenius.android.data.import.*
import com.irrgenius.android.data.import.ImportResultWithMapping as ImportResult
import com.irrgenius.android.data.models.CalculationMode
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ImportDataScreen(
    onNavigateBack: () -> Unit,
    onImportComplete: (List<com.irrgenius.android.data.models.SavedCalculation>) -> Unit,
    viewModel: ImportDataViewModel = viewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    
    var showFileTypePicker by remember { mutableStateOf(false) }
    var showColumnMappingDialog by remember { mutableStateOf(false) }
    var showValidationDialog by remember { mutableStateOf(false) }
    var showImportConfirmationDialog by remember { mutableStateOf(false) }
    
    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { fileUri ->
            scope.launch {
                try {
                    viewModel.processFile(context, fileUri)
                    showColumnMappingDialog = true
                } catch (e: Exception) {
                    viewModel.setError("Failed to process file: ${e.message}")
                }
            }
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Import Data") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // File Selection Section
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Select File to Import",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Text(
                        text = "Choose a CSV or Excel file containing your calculation data",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = { 
                                viewModel.setFileType(ImportFileType.CSV)
                                filePickerLauncher.launch("text/csv")
                            },
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("CSV File")
                        }
                        
                        Button(
                            onClick = { 
                                // TODO: Implement Excel import when ImportFileType is available
                            },
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Default.List, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Excel File")
                        }
                    }
                }
            }
            
            // Calculation Type Selection
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Calculation Type",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    CalculationModeDropdown(
                        selectedMode = viewModel.selectedCalculationType,
                        onModeSelected = viewModel::setCalculationType
                    )
                }
            }
            
            // Import Progress
            if (viewModel.isProcessing) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        CircularProgressIndicator()
                        Text("Processing file...")
                    }
                }
            }
            
            // Error Display
            viewModel.errorMessage?.let { error ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Warning,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onErrorContainer
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = error,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
            }
            
            // Import Summary
            viewModel.importResult?.let { result ->
                ImportSummaryCard(
                    importResult = result,
                    onEditMapping = { showColumnMappingDialog = true },
                    onValidate = { 
                        scope.launch {
                            viewModel.validateData()
                            showValidationDialog = true
                        }
                    }
                )
            }
        }
    }
    
    // Column Mapping Dialog
    if (showColumnMappingDialog) {
        ColumnMappingDialog(
            importResult = viewModel.importResult,
            currentMapping = viewModel.columnMapping,
            onMappingChanged = viewModel::updateColumnMapping,
            onConfirm = { 
                showColumnMappingDialog = false
                scope.launch {
                    viewModel.validateData()
                    showValidationDialog = true
                }
            },
            onDismiss = { showColumnMappingDialog = false }
        )
    }
    
    // Validation Results Dialog
    if (showValidationDialog) {
        ValidationResultsDialog(
            validationResult = viewModel.validationResult,
            onConfirm = { 
                showValidationDialog = false
                showImportConfirmationDialog = true
            },
            onDismiss = { showValidationDialog = false }
        )
    }
    
    // Import Confirmation Dialog
    if (showImportConfirmationDialog) {
        ImportConfirmationDialog(
            validationResult = viewModel.validationResult,
            onConfirm = { 
                showImportConfirmationDialog = false
                viewModel.importResult?.validCalculations?.let { calculations ->
                    onImportComplete(calculations)
                }
            },
            onDismiss = { showImportConfirmationDialog = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CalculationModeDropdown(
    selectedMode: CalculationMode,
    onModeSelected: (CalculationMode) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    
    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = !expanded }
    ) {
        OutlinedTextField(
            value = selectedMode.name.replace("_", " ").lowercase().replaceFirstChar { it.uppercase() },
            onValueChange = { },
            readOnly = true,
            label = { Text("Calculation Type") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .fillMaxWidth()
                .menuAnchor()
        )
        
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            CalculationMode.values().forEach { mode ->
                DropdownMenuItem(
                    text = { Text(mode.name.replace("_", " ").lowercase().replaceFirstChar { it.uppercase() }) },
                    onClick = {
                        onModeSelected(mode)
                        expanded = false
                    }
                )
            }
        }
    }
}

@Composable
private fun ImportSummaryCard(
    importResult: ImportResult,
    onEditMapping: () -> Unit,
    onValidate: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Import Summary",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Columns: ${importResult.headers.size}")
                Text("Rows: ${importResult.rows.size}")
            }
            
            Text(
                text = "Detected Format: ${when (importResult.detectedFormat) {
                    ImportFormat.CSV -> "CSV"
                    ImportFormat.Excel -> "Excel"
                    else -> importResult.detectedFormat.name
                }}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onEditMapping,
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.Edit, contentDescription = null)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Edit Mapping")
                }
                
                Button(
                    onClick = onValidate,
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.Check, contentDescription = null)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Validate")
                }
            }
        }
    }
}

@Composable
private fun ColumnMappingDialog(
    importResult: ImportResult?,
    currentMapping: Map<String, CalculationField>,
    onMappingChanged: (String, CalculationField?) -> Unit,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    importResult?.let { result ->
        Dialog(onDismissRequest = onDismiss) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .fillMaxHeight(0.8f),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Map Columns",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    LazyColumn(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(result.headers) { header: String ->
                            ColumnMappingRow(
                                columnName = header,
                                selectedField = currentMapping[header],
                                onFieldSelected = { field -> onMappingChanged(header, field) }
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = onDismiss,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Cancel")
                        }
                        
                        Button(
                            onClick = onConfirm,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Confirm")
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ColumnMappingRow(
    columnName: String,
    selectedField: CalculationField?,
    onFieldSelected: (CalculationField?) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = columnName,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyMedium
        )
        
        ExposedDropdownMenuBox(
            expanded = expanded,
            onExpandedChange = { expanded = !expanded },
            modifier = Modifier.weight(1f)
        ) {
            OutlinedTextField(
                value = selectedField?.displayName ?: "Not mapped",
                onValueChange = { },
                readOnly = true,
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor()
            )
            
            ExposedDropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                DropdownMenuItem(
                    text = { Text("Not mapped") },
                    onClick = {
                        onFieldSelected(null)
                        expanded = false
                    }
                )
                
                CalculationField.values().forEach { field ->
                    DropdownMenuItem(
                        text = { Text(field.displayName) },
                        onClick = {
                            onFieldSelected(field)
                            expanded = false
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun ValidationResultsDialog(
    validationResult: ValidationResult?,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    validationResult?.let { result ->
        Dialog(onDismissRequest = onDismiss) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .fillMaxHeight(0.8f),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Validation Results",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Summary
                    Card(
                        colors = CardDefaults.cardColors(
                            containerColor = if (result.hasErrors) 
                                MaterialTheme.colorScheme.errorContainer 
                            else 
                                MaterialTheme.colorScheme.primaryContainer
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(12.dp)
                        ) {
                            Text(
                                text = "Valid: ${result.validRows}/${result.totalRows} rows",
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "Success Rate: ${(result.successRate * 100).toInt()}%"
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Errors
                    if (result.validationErrors.isNotEmpty()) {
                        Text(
                            text = "Errors:",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        
                        LazyColumn(
                            modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            items(result.validationErrors) { error ->
                                ValidationErrorItem(error = error)
                            }
                        }
                    } else {
                        Box(
                            modifier = Modifier.weight(1f),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Icon(
                                    Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(48.dp)
                                )
                                Text(
                                    text = "All data is valid!",
                                    style = MaterialTheme.typography.titleMedium
                                )
                            }
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = onDismiss,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Back")
                        }
                        
                        Button(
                            onClick = onConfirm,
                            enabled = result.validRows > 0,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Continue")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ValidationErrorItem(error: ValidationError) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = when (error.severity) {
                ValidationSeverity.ERROR -> MaterialTheme.colorScheme.errorContainer
                ValidationSeverity.WARNING -> MaterialTheme.colorScheme.secondaryContainer
                ValidationSeverity.INFO -> MaterialTheme.colorScheme.tertiaryContainer
            }
        )
    ) {
        Row(
            modifier = Modifier.padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                when (error.severity) {
                    ValidationSeverity.ERROR -> Icons.Default.Warning
                    ValidationSeverity.WARNING -> Icons.Default.Warning
                    ValidationSeverity.INFO -> Icons.Default.Info
                },
                contentDescription = null,
                tint = when (error.severity) {
                    ValidationSeverity.ERROR -> MaterialTheme.colorScheme.onErrorContainer
                    ValidationSeverity.WARNING -> MaterialTheme.colorScheme.onSecondaryContainer
                    ValidationSeverity.INFO -> MaterialTheme.colorScheme.onTertiaryContainer
                }
            )
            
            Spacer(modifier = Modifier.width(8.dp))
            
            Column {
                Text(
                    text = "Row ${error.row}${error.column?.let { ", Column $it" } ?: ""}",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = error.message,
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@Composable
private fun ImportConfirmationDialog(
    validationResult: ValidationResult?,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    validationResult?.let { result ->
        AlertDialog(
            onDismissRequest = onDismiss,
            title = { Text("Confirm Import") },
            text = {
                Column {
                    Text("Ready to import ${result.validRows} calculations.")
                    if (result.validationErrors.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "${result.validationErrors.size} rows will be skipped due to errors.",
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                }
            },
            confirmButton = {
                Button(onClick = onConfirm) {
                    Text("Import")
                }
            },
            dismissButton = {
                OutlinedButton(onClick = onDismiss) {
                    Text("Cancel")
                }
            }
        )
    }
}

enum class ImportFileType {
    CSV, EXCEL
}