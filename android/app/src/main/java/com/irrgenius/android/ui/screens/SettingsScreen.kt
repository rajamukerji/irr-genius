package com.irrgenius.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    dataManager: com.irrgenius.android.data.DataManager,
    onNavigateToCloudSync: () -> Unit,
    onNavigateToImport: () -> Unit
) {
    val isSyncEnabled by dataManager.isSyncEnabled.collectAsState()
    val syncStatus by dataManager.syncStatus.collectAsState()
    val pendingConflicts by dataManager.pendingConflicts.collectAsState()
    
    var autoSaveEnabled by remember { mutableStateOf(true) }
    var showingAbout by remember { mutableStateOf(false) }
    var showingClearDataDialog by remember { mutableStateOf(false) }
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Top App Bar
        TopAppBar(
            title = { Text("Settings") }
        )
        
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                SettingsSection(title = "Data Management") {
                    // Cloud Sync Settings
                    CloudSyncSettingsItem(
                        isSyncEnabled = isSyncEnabled,
                        syncStatus = syncStatus,
                        pendingConflicts = pendingConflicts,
                        onClick = onNavigateToCloudSync
                    )
                    
                    SettingsToggleItem(
                        icon = Icons.Default.Save,
                        title = "Auto-Save Calculations",
                        description = "Automatically save completed calculations",
                        checked = autoSaveEnabled,
                        onCheckedChange = { autoSaveEnabled = it }
                    )
                    
                    SettingsActionItem(
                        icon = Icons.Default.Delete,
                        title = "Clear All Data",
                        description = "Remove all saved calculations and projects",
                        iconTint = MaterialTheme.colorScheme.error,
                        onClick = { showingClearDataDialog = true }
                    )
                }
            }
            
            item {
                SettingsSection(title = "Import & Export") {
                    SettingsActionItem(
                        icon = Icons.Default.Upload,
                        title = "Export All Calculations",
                        description = "Export all calculations to a file",
                        onClick = { /* TODO: Implement bulk export */ }
                    )
                    
                    SettingsActionItem(
                        icon = Icons.Default.Download,
                        title = "Import from File",
                        description = "Import calculations from CSV or Excel",
                        onClick = { /* TODO: Implement import */ }
                    )
                }
            }
            
            item {
                SettingsSection(title = "App Information") {
                    SettingsActionItem(
                        icon = Icons.Default.Info,
                        title = "About IRR Genius",
                        description = "Version and app information",
                        onClick = { showingAbout = true }
                    )
                    
                    SettingsActionItem(
                        icon = Icons.Default.Star,
                        title = "Rate App",
                        description = "Rate us on the Play Store",
                        onClick = { /* TODO: Implement app rating */ }
                    )
                }
            }
        }
    }
    
    if (showingAbout) {
        AboutDialog(
            onDismiss = { showingAbout = false }
        )
    }
    
    if (showingClearDataDialog) {
        ClearDataDialog(
            onDismiss = { showingClearDataDialog = false },
            onConfirm = {
                // Clear all data
                dataManager.calculations.clear()
                dataManager.projects.clear()
                showingClearDataDialog = false
            }
        )
    }
}

@Composable
fun CloudSyncSettingsItem(
    isSyncEnabled: Boolean,
    syncStatus: com.irrgenius.android.data.sync.CloudSyncService.SyncStatus,
    pendingConflicts: List<com.irrgenius.android.data.sync.CloudSyncService.SyncConflict>,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.Settings,
            contentDescription = null,
            tint = if (isSyncEnabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(24.dp)
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = "Cloud Sync",
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium
            )
            
            val statusText = when {
                !isSyncEnabled -> "Disabled"
                syncStatus is com.irrgenius.android.data.sync.CloudSyncService.SyncStatus.Syncing -> "Syncing..."
                syncStatus is com.irrgenius.android.data.sync.CloudSyncService.SyncStatus.Success -> "Enabled"
                syncStatus is com.irrgenius.android.data.sync.CloudSyncService.SyncStatus.Error -> "Error"
                else -> "Ready"
            }
            
            Text(
                text = statusText,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        // Show indicators
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Sync progress indicator
            if (syncStatus is com.irrgenius.android.data.sync.CloudSyncService.SyncStatus.Syncing) {
                CircularProgressIndicator(
                    modifier = Modifier.size(16.dp),
                    strokeWidth = 2.dp
                )
            }
            
            // Conflict indicator
            if (pendingConflicts.isNotEmpty()) {
                Badge {
                    Text(
                        text = pendingConflicts.size.toString(),
                        style = MaterialTheme.typography.labelSmall
                    )
                }
            }
            
            IconButton(onClick = onClick) {
                Icon(
                    imageVector = Icons.Default.ArrowForward,
                    contentDescription = "Open Cloud Sync Settings"
                )
            }
        }
    }
}

@Composable
fun ClearDataDialog(
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Clear All Data") },
        text = {
            Text("This will permanently delete all your saved calculations and projects. This action cannot be undone.")
        },
        confirmButton = {
            TextButton(
                onClick = onConfirm,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text("Clear")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun SettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(bottom = 12.dp)
            )
            content()
        }
    }
}

@Composable
fun SettingsToggleItem(
    icon: ImageVector,
    title: String,
    description: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    iconTint: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurfaceVariant
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = iconTint,
            modifier = Modifier.size(24.dp)
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}

@Composable
fun SettingsActionItem(
    icon: ImageVector,
    title: String,
    description: String,
    onClick: () -> Unit,
    iconTint: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurfaceVariant
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = iconTint,
            modifier = Modifier.size(24.dp)
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        IconButton(onClick = onClick) {
            Icon(
                imageVector = Icons.Default.ArrowForward,
                contentDescription = "Open"
            )
        }
    }
}

@Composable
fun AboutDialog(
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("About IRR Genius") },
        text = {
            Column {
                Icon(
                    imageVector = Icons.Default.Settings,
                    contentDescription = null,
                    modifier = Modifier
                        .size(60.dp)
                        .align(Alignment.CenterHorizontally),
                    tint = MaterialTheme.colorScheme.primary
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "IRR Genius",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
                
                Text(
                    text = "Version 1.0",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "A powerful tool for calculating Internal Rate of Return (IRR) and managing investment calculations.",
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("OK")
            }
        }
    )
}