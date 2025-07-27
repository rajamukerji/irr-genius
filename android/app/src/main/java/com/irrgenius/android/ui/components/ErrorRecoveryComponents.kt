package com.irrgenius.android.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.irrgenius.android.services.ErrorRecoveryService
import com.irrgenius.android.services.ErrorType
import com.irrgenius.android.services.RecoverableError
import com.irrgenius.android.services.RecoveryAction

@Composable
fun ErrorRecoveryView(
    error: RecoverableError,
    errorRecoveryService: ErrorRecoveryService,
    modifier: Modifier = Modifier,
    onDismiss: () -> Unit = {}
) {
    var isRecovering by remember { mutableStateOf(false) }
    val isRecoveringService by errorRecoveryService.isRecovering.collectAsState()
    
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = when (error.type) {
                ErrorType.Network -> Color(0xFFFFEBEE)
                ErrorType.CloudSync -> Color(0xFFE3F2FD)
                ErrorType.Storage -> Color(0xFFFFF3E0)
                ErrorType.Validation -> Color(0xFFE8F5E8)
                is ErrorType.Custom -> Color(0xFFF5F5F5)
            }
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Header with icon and title
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = when (error.type) {
                        ErrorType.Network -> Icons.Default.Warning
                        ErrorType.CloudSync -> Icons.Default.Settings
                        ErrorType.Storage -> Icons.Default.Home
                        ErrorType.Validation -> Icons.Default.Warning
                        is ErrorType.Custom -> Icons.Default.Warning
                    },
                    contentDescription = null,
                    tint = when (error.type) {
                        ErrorType.Network -> Color(0xFFD32F2F)
                        ErrorType.CloudSync -> Color(0xFF1976D2)
                        ErrorType.Storage -> Color(0xFFF57C00)
                        ErrorType.Validation -> Color(0xFF388E3C)
                        is ErrorType.Custom -> Color(0xFF757575)
                    },
                    modifier = Modifier.size(24.dp)
                )
                
                Spacer(modifier = Modifier.width(12.dp))
                
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = error.title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Text(
                        text = error.description,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Dismiss"
                    )
                }
            }
            
            if (error.recoveryActions.isNotEmpty()) {
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "Recovery Options:",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Medium
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                error.recoveryActions.forEachIndexed { index, action ->
                    RecoveryActionButton(
                        action = action,
                        isLoading = isRecovering || isRecoveringService,
                        onClick = {
                            isRecovering = true
                            // Launch recovery action
                        }
                    )
                    
                    if (index < error.recoveryActions.size - 1) {
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun RecoveryActionButton(
    action: RecoveryAction,
    isLoading: Boolean,
    onClick: () -> Unit
) {
    OutlinedButton(
        onClick = onClick,
        enabled = !isLoading,
        modifier = Modifier.fillMaxWidth()
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(16.dp),
                strokeWidth = 2.dp
            )
            Spacer(modifier = Modifier.width(8.dp))
        }
        
        Column {
            Text(
                text = action.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
            
            if (action.description.isNotEmpty()) {
                Text(
                    text = action.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        if (action.isAutomated) {
            Spacer(modifier = Modifier.width(8.dp))
            Icon(
                imageVector = Icons.Default.PlayArrow,
                contentDescription = "Automated",
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

@Composable
fun NetworkErrorView(
    title: String = "Network Connection Problem",
    description: String = "Unable to connect to the internet. Please check your connection and try again.",
    onRetry: () -> Unit = {},
    onDismiss: () -> Unit = {}
) {
    ErrorMessageCard(
        title = title,
        description = description,
        icon = Icons.Default.Warning,
        iconTint = Color(0xFFD32F2F),
        backgroundColor = Color(0xFFFFEBEE),
        actions = listOf(
            "Retry" to onRetry,
            "Dismiss" to onDismiss
        )
    )
}

@Composable
fun StorageErrorView(
    title: String = "Storage Problem",
    description: String = "Unable to access local storage. The app may not function properly.",
    onClearCache: () -> Unit = {},
    onDismiss: () -> Unit = {}
) {
    ErrorMessageCard(
        title = title,
        description = description,
        icon = Icons.Default.Home,
        iconTint = Color(0xFFF57C00),
        backgroundColor = Color(0xFFFFF3E0),
        actions = listOf(
            "Clear Cache" to onClearCache,
            "Dismiss" to onDismiss
        )
    )
}

@Composable
fun CloudSyncErrorView(
    title: String = "Cloud Sync Issue",
    description: String = "Unable to sync your data with the cloud. Your local data is safe.",
    onRetrySync: () -> Unit = {},
    onDismiss: () -> Unit = {}
) {
    ErrorMessageCard(
        title = title,
        description = description,
        icon = Icons.Default.Settings,
        iconTint = Color(0xFF1976D2),
        backgroundColor = Color(0xFFE3F2FD),
        actions = listOf(
            "Retry Sync" to onRetrySync,
            "Dismiss" to onDismiss
        )
    )
}

@Composable
private fun ErrorMessageCard(
    title: String,
    description: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    iconTint: Color,
    backgroundColor: Color,
    actions: List<Pair<String, () -> Unit>>
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = backgroundColor)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = iconTint,
                    modifier = Modifier.size(24.dp)
                )
                
                Spacer(modifier = Modifier.width(12.dp))
                
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Text(
                        text = description,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            if (actions.isNotEmpty()) {
                Spacer(modifier = Modifier.height(16.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    actions.forEach { (label, action) ->
                        OutlinedButton(
                            onClick = action,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(label)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ErrorRecoveryList(
    errorRecoveryService: ErrorRecoveryService,
    modifier: Modifier = Modifier
) {
    val errors by errorRecoveryService.activeErrors.collectAsState()
    
    if (errors.isNotEmpty()) {
        Column(
            modifier = modifier.verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            errors.forEach { error ->
                ErrorRecoveryView(
                    error = error,
                    errorRecoveryService = errorRecoveryService,
                    onDismiss = { errorRecoveryService.dismissError(error.id) }
                )
            }
        }
    }
}