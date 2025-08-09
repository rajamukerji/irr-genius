package com.irrgenius.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.irrgenius.android.data.sync.CloudSyncService
import com.irrgenius.android.data.sync.SyncStatus
import com.irrgenius.android.data.sync.SyncConflict
import com.irrgenius.android.data.sync.ConflictResolution
import com.irrgenius.android.data.sync.ConflictType
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CloudSyncSettingsScreen(
    onNavigateBack: () -> Unit,
    viewModel: CloudSyncSettingsViewModel = viewModel()
) {
    val syncStatus by viewModel.syncStatus.collectAsState()
    val syncProgress by viewModel.syncProgress.collectAsState()
    val pendingConflicts by viewModel.pendingConflicts.collectAsState()
    val isSyncEnabled by viewModel.isSyncEnabled.collectAsState()
    
    var showConflictDialog by remember { mutableStateOf(false) }
    var showErrorDialog by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    
    // Handle sync status changes
    LaunchedEffect(syncStatus) {
        val currentStatus = syncStatus
        if (currentStatus is SyncStatus.Error) {
            errorMessage = currentStatus.message
            showErrorDialog = true
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Cloud Sync") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Cloud Sync Status Card
            item {
                CloudSyncStatusCard(
                    isSyncEnabled = isSyncEnabled,
                    syncStatus = syncStatus,
                    syncProgress = syncProgress,
                    onToggleSync = { enabled ->
                        if (enabled) {
                            viewModel.enableSync()
                        } else {
                            viewModel.disableSync()
                        }
                    },
                    onManualSync = { viewModel.manualSync() }
                )
            }
            
            // Conflict Resolution Card
            if (pendingConflicts.isNotEmpty()) {
                item {
                    ConflictResolutionCard(
                        conflictCount = pendingConflicts.size,
                        onResolveConflicts = { showConflictDialog = true }
                    )
                }
            }
            
            // Sync Information Card
            item {
                SyncInformationCard()
            }
        }
    }
    
    // Conflict Resolution Dialog
    if (showConflictDialog) {
        ConflictResolutionDialog(
            conflicts = pendingConflicts,
            onDismiss = { showConflictDialog = false },
            onResolveConflict = { conflict, resolution ->
                viewModel.resolveConflict(conflict, resolution)
            }
        )
    }
    
    // Error Dialog
    if (showErrorDialog) {
        AlertDialog(
            onDismissRequest = { showErrorDialog = false },
            title = { Text("Sync Error") },
            text = { Text(errorMessage) },
            confirmButton = {
                TextButton(onClick = { showErrorDialog = false }) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
private fun CloudSyncStatusCard(
    isSyncEnabled: Boolean,
    syncStatus: SyncStatus,
    syncProgress: Double,
    onToggleSync: (Boolean) -> Unit,
    onManualSync: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header with toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.Settings,
                        contentDescription = null,
                        tint = if (isSyncEnabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        "Cloud Sync",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                Switch(
                    checked = isSyncEnabled,
                    onCheckedChange = onToggleSync
                )
            }
            
            if (isSyncEnabled) {
                // Sync Status
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = when (syncStatus) {
                            is SyncStatus.Idle -> Icons.Default.CheckCircle
                            is SyncStatus.Syncing -> Icons.Default.Refresh
                            is SyncStatus.Success -> Icons.Default.CheckCircle
                            is SyncStatus.Error -> Icons.Default.Warning
                        },
                        contentDescription = null,
                        tint = when (syncStatus) {
                            is SyncStatus.Idle -> MaterialTheme.colorScheme.onSurfaceVariant
                            is SyncStatus.Syncing -> MaterialTheme.colorScheme.primary
                            is SyncStatus.Success -> Color(0xFF4CAF50)
                            is SyncStatus.Error -> MaterialTheme.colorScheme.error
                        }
                    )
                    
                    Text(
                        text = when (syncStatus) {
                            is SyncStatus.Idle -> "Ready to sync"
                            is SyncStatus.Syncing -> "Syncing..."
                            is SyncStatus.Success -> "Last synced ${java.text.SimpleDateFormat("MM/dd/yy HH:mm", java.util.Locale.getDefault()).format(java.util.Date(syncStatus.timestamp))}"
                            is SyncStatus.Error -> "Sync failed"
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                // Sync Progress
                if (syncStatus is SyncStatus.Syncing) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                "Syncing...",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                "${(syncProgress * 100).toInt()}%",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        LinearProgressIndicator(
                            progress = syncProgress.toFloat(),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
                
                // Manual Sync Button
                Button(
                    onClick = onManualSync,
                    modifier = Modifier.fillMaxWidth(),
                    enabled = syncStatus !is SyncStatus.Syncing
                ) {
                    Icon(Icons.Default.Refresh, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Sync Now")
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ConflictResolutionCard(
    conflictCount: Int,
    onResolveConflicts: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.errorContainer
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.Default.Warning,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onErrorContainer
                )
                Text(
                    "Sync Conflicts",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
                
                Spacer(modifier = Modifier.weight(1f))
                
                Badge {
                    Text(conflictCount.toString())
                }
            }
            
            Text(
                "Some calculations have conflicting changes that need to be resolved.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onErrorContainer
            )
            
            OutlinedButton(
                onClick = onResolveConflicts,
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = MaterialTheme.colorScheme.onErrorContainer
                ),
                border = ButtonDefaults.outlinedButtonBorder.copy(
                    brush = androidx.compose.ui.graphics.SolidColor(MaterialTheme.colorScheme.onErrorContainer)
                )
            ) {
                Text("Resolve Conflicts")
            }
        }
    }
}

@Composable
private fun SyncInformationCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                "About Cloud Sync",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                "When enabled, your calculations and projects are automatically synchronized across all your devices using Firebase. Your data is encrypted and stored securely in your personal cloud account.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Column(
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                InfoRow(icon = Icons.Default.Lock, text = "End-to-end encryption")
                InfoRow(icon = Icons.Default.Refresh, text = "Automatic sync every 5 minutes")
                InfoRow(icon = Icons.Default.Settings, text = "Offline-first with conflict resolution")
                InfoRow(icon = Icons.Default.Phone, text = "Cross-platform compatibility")
            }
        }
    }
}

@Composable
private fun InfoRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    text: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            icon,
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        Text(
            text,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun ConflictResolutionDialog(
    conflicts: List<SyncConflict>,
    onDismiss: () -> Unit,
    onResolveConflict: (SyncConflict, ConflictResolution) -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Resolve Conflicts") },
        text = {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(conflicts) { conflict ->
                    ConflictItem(
                        conflict = conflict,
                        onResolve = { resolution ->
                            onResolveConflict(conflict, resolution)
                        }
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Done")
            }
        }
    )
}

@Composable
private fun ConflictItem(
    conflict: SyncConflict,
    onResolve: (ConflictResolution) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                "Conflict Item",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                when (conflict.conflictType) {
                    ConflictType.DATA_CONFLICT ->
                        "Conflicting data between local and remote versions."
                    ConflictType.VERSION_CONFLICT ->
                        "Both local and remote versions were modified at the same time."
                    ConflictType.MERGE_CONFLICT ->
                        "Automatic merge failed, manual resolution required."
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = { onResolve(ConflictResolution.USE_LOCAL) },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Use Local", style = MaterialTheme.typography.bodySmall)
                }
                
                OutlinedButton(
                    onClick = { onResolve(ConflictResolution.USE_REMOTE) },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Use Remote", style = MaterialTheme.typography.bodySmall)
                }
                
                Button(
                    onClick = { onResolve(ConflictResolution.MERGE) },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Merge", style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}