package com.irrgenius.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.irrgenius.android.data.DataManager
import com.irrgenius.android.data.models.SavedCalculation
import com.irrgenius.android.data.models.Project
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SavedCalculationsScreen(
    dataManager: DataManager
) {
    var searchText by remember { mutableStateOf("") }
    var showingImportSheet by remember { mutableStateOf(false) }
    var selectedProject by remember { mutableStateOf<Project?>(null) }
    
    val isLoading by dataManager.isLoading
    val errorMessage by dataManager.errorMessage
    
    val filteredCalculations = remember(dataManager.calculations, searchText, selectedProject) {
        dataManager.calculations.filter { calculation ->
            val matchesSearch = searchText.isEmpty() || 
                calculation.name.contains(searchText, ignoreCase = true) ||
                calculation.calculationType.name.replace("_", " ").contains(searchText, ignoreCase = true)
            val matchesProject = selectedProject == null || calculation.projectId == selectedProject?.id
            matchesSearch && matchesProject
        }
    }
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Top App Bar
        TopAppBar(
            title = { Text("Saved Calculations") },
            actions = {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    IconButton(onClick = { showingImportSheet = true }) {
                        Icon(Icons.Default.Add, contentDescription = "Add")
                    }
                }
            }
        )
        
        // Error Message
        errorMessage?.let { error ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                )
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Error,
                        contentDescription = "Error",
                        tint = MaterialTheme.colorScheme.onErrorContainer
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = error,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(onClick = { dataManager.clearError() }) {
                        Icon(
                            Icons.Default.Close,
                            contentDescription = "Dismiss error",
                            tint = MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
            }
        }
        
        // Search Bar
        OutlinedTextField(
            value = searchText,
            onValueChange = { searchText = it },
            label = { Text("Search calculations...") },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = "Search") },
            trailingIcon = {
                if (searchText.isNotEmpty()) {
                    IconButton(onClick = { searchText = "" }) {
                        Icon(Icons.Default.Clear, contentDescription = "Clear search")
                    }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        )
        
        // Project Filter
        if (dataManager.projects.isNotEmpty()) {
            LazyRow(
                modifier = Modifier.padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    FilterChip(
                        onClick = { selectedProject = null },
                        label = { Text("All") },
                        selected = selectedProject == null
                    )
                }
                items(dataManager.projects) { project ->
                    FilterChip(
                        onClick = { selectedProject = project },
                        label = { Text(project.name) },
                        selected = selectedProject?.id == project.id
                    )
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
        }
        
        // Content
        if (filteredCalculations.isEmpty()) {
            EmptyStateView(searchText = searchText)
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(filteredCalculations, key = { it.id }) { calculation ->
                    CalculationCard(
                        calculation = calculation,
                        onDelete = { dataManager.deleteCalculation(calculation) },
                        onExport = { dataManager.exportCalculation(calculation) },
                        onLoad = { /* TODO: Load calculation into calculator */ }
                    )
                }
            }
        }
    }
    
    if (showingImportSheet) {
        ImportFileDialog(
            onDismiss = { showingImportSheet = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalculationCard(
    calculation: SavedCalculation,
    onDelete: () -> Unit,
    onExport: () -> Unit,
    onLoad: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = calculation.name,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = calculation.calculationType.name.replace("_", " ").lowercase()
                            .replaceFirstChar { it.uppercase() },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    calculation.calculatedResult?.let { result ->
                        Text(
                            text = "${String.format("%.2f", result)}%",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                    
                    Box {
                        IconButton(onClick = { showMenu = true }) {
                            Icon(Icons.Default.MoreVert, contentDescription = "More options")
                        }
                        
                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("Load") },
                                onClick = {
                                    onLoad()
                                    showMenu = false
                                },
                                leadingIcon = { Icon(Icons.Default.PlayArrow, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text("Export") },
                                onClick = {
                                    onExport()
                                    showMenu = false
                                },
                                leadingIcon = { Icon(Icons.Default.Share, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text("Delete") },
                                onClick = {
                                    onDelete()
                                    showMenu = false
                                },
                                leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null) }
                            )
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = calculation.createdDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy")),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun EmptyStateView(searchText: String) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = if (searchText.isEmpty()) Icons.Default.Home else Icons.Default.Search,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = if (searchText.isEmpty()) "No Saved Calculations" else "No Results Found",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Medium
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = if (searchText.isEmpty()) 
                "Your saved calculations will appear here. Start by performing a calculation and saving it."
            else 
                "No calculations match '$searchText'. Try adjusting your search terms.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
    }
}

@Composable
fun ImportFileDialog(
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Import File") },
        text = { Text("Import functionality will be implemented in task 4") },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("OK")
            }
        }
    )
}