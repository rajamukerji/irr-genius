package com.irrgenius.android.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.irrgenius.android.data.AutoSaveManager
import com.irrgenius.android.data.SaveDialogData
import com.irrgenius.android.data.models.CalculationMode
import com.irrgenius.android.data.models.Project
import com.irrgenius.android.data.models.SavedCalculation
import com.irrgenius.android.data.displayName
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class, ExperimentalComposeUiApi::class)
@Composable
fun SaveCalculationDialog(
    autoSaveManager: AutoSaveManager,
    saveDialogData: SaveDialogData,
    projects: List<Project>,
    onDismiss: () -> Unit,
    onSave: () -> Unit
) {
    var name by remember { mutableStateOf(saveDialogData.name) }
    var selectedProject by remember { mutableStateOf<Project?>(
        projects.find { it.id == saveDialogData.projectId }
    ) }
    var notes by remember { mutableStateOf(saveDialogData.notes) }
    var tags by remember { mutableStateOf(saveDialogData.tags) }
    var tagInput by remember { mutableStateOf("") }
    var showingNewProjectField by remember { mutableStateOf(false) }
    var newProjectName by remember { mutableStateOf("") }
    var showProjectDropdown by remember { mutableStateOf(false) }
    
    val keyboardController = LocalSoftwareKeyboardController.current
    
    // Update auto-save manager when values change
    LaunchedEffect(name, selectedProject, notes, tags) {
        autoSaveManager.updateSaveDialogData(
            name = name,
            projectId = selectedProject?.id,
            notes = notes,
            tags = tags
        )
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
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Save Calculation",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Calculation Details Section
                Text(
                    text = "Calculation Details",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Calculation Name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("Notes (Optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3,
                    maxLines = 6,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(
                        onDone = { keyboardController?.hide() }
                    )
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Project Section
                Text(
                    text = "Project",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                if (showingNewProjectField) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedTextField(
                            value = newProjectName,
                            onValueChange = { newProjectName = it },
                            label = { Text("New Project Name") },
                            modifier = Modifier.weight(1f),
                            singleLine = true
                        )
                        
                        TextButton(
                            onClick = {
                                showingNewProjectField = false
                                newProjectName = ""
                            }
                        ) {
                            Text("Cancel", color = MaterialTheme.colorScheme.error)
                        }
                    }
                } else {
                    ExposedDropdownMenuBox(
                        expanded = showProjectDropdown,
                        onExpandedChange = { showProjectDropdown = it }
                    ) {
                        OutlinedTextField(
                            value = selectedProject?.name ?: "No Project",
                            onValueChange = { },
                            readOnly = true,
                            label = { Text("Select Project") },
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
                                text = { Text("No Project") },
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
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    TextButton(
                        onClick = { showingNewProjectField = true }
                    ) {
                        Text("Create New Project")
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Tags Section
                Text(
                    text = "Tags",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = tagInput,
                        onValueChange = { tagInput = it },
                        label = { Text("Add tag") },
                        modifier = Modifier.weight(1f),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                        keyboardActions = KeyboardActions(
                            onDone = {
                                if (tagInput.trim().isNotEmpty() && !tags.contains(tagInput.trim())) {
                                    tags = tags + tagInput.trim()
                                    tagInput = ""
                                }
                                keyboardController?.hide()
                            }
                        )
                    )
                    
                    Button(
                        onClick = {
                            if (tagInput.trim().isNotEmpty() && !tags.contains(tagInput.trim())) {
                                tags = tags + tagInput.trim()
                                tagInput = ""
                            }
                        },
                        enabled = tagInput.trim().isNotEmpty()
                    ) {
                        Text("Add")
                    }
                }
                
                if (tags.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(tags) { tag ->
                            TagChip(
                                tag = tag,
                                onRemove = { tags = tags - tag }
                            )
                        }
                    }
                }
                
                // Calculation Summary Section
                saveDialogData.calculationToSave?.let { calculation ->
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = "Calculation Summary",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
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
                            SummaryRow(
                                label = "Type:",
                                value = calculation.calculationType.displayName
                            )
                            
                            calculation.calculatedResult?.let { result ->
                                SummaryRow(
                                    label = "Result:",
                                    value = formatResult(result, calculation.calculationType),
                                    valueColor = MaterialTheme.colorScheme.primary
                                )
                            }
                            
                            SummaryRow(
                                label = "Created:",
                                value = calculation.createdDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy HH:mm"))
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Action Buttons
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
                        onClick = {
                            // Create new project if needed
                            if (showingNewProjectField && newProjectName.trim().isNotEmpty()) {
                                try {
                                    val newProject = Project.createValidated(
                                        name = newProjectName.trim(),
                                        color = Project.defaultColors.random()
                                    )
                                    autoSaveManager.saveProject(newProject)
                                    selectedProject = newProject
                                } catch (e: Exception) {
                                    // Handle error - could show a snackbar
                                }
                            }
                            onSave()
                        },
                        modifier = Modifier.weight(1f),
                        enabled = name.trim().isNotEmpty()
                    ) {
                        Text("Save")
                    }
                }
            }
        }
    }
}

@Composable
private fun TagChip(
    tag: String,
    onRemove: () -> Unit
) {
    AssistChip(
        onClick = onRemove,
        label = { Text(tag) },
        trailingIcon = {
            Icon(
                Icons.Default.Close,
                contentDescription = "Remove tag",
                modifier = Modifier.size(16.dp)
            )
        }
    )
}

@Composable
private fun SummaryRow(
    label: String,
    value: String,
    valueColor: Color = MaterialTheme.colorScheme.onSurfaceVariant
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = valueColor
        )
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