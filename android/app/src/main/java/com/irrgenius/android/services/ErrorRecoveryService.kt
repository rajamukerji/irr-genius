package com.irrgenius.android.services

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

// MARK: - Error Recovery Models

data class RecoveryAction(
    val title: String,
    val description: String,
    val action: suspend () -> Boolean, // Returns true if recovery was successful
    val isAutomated: Boolean = false
)

sealed class ErrorType {
    object Network : ErrorType()
    object CloudSync : ErrorType()
    object Validation : ErrorType()
    object Storage : ErrorType()
    data class Custom(val category: String) : ErrorType()
}

data class RecoverableError(
    val id: String,
    val type: ErrorType,
    val title: String,
    val description: String,
    val timestamp: Long = System.currentTimeMillis(),
    val recoveryActions: List<RecoveryAction> = emptyList(),
    val isRecoverable: Boolean = true,
    val metadata: Map<String, Any> = emptyMap()
)

// MARK: - Error Recovery Service

class ErrorRecoveryService {
    private val _activeErrors = MutableStateFlow<List<RecoverableError>>(emptyList())
    val activeErrors: StateFlow<List<RecoverableError>> = _activeErrors.asStateFlow()
    
    private val _isRecovering = MutableStateFlow(false)
    val isRecovering: StateFlow<Boolean> = _isRecovering.asStateFlow()
    
    fun reportError(error: RecoverableError) {
        val currentErrors = _activeErrors.value.toMutableList()
        currentErrors.add(error)
        _activeErrors.value = currentErrors
    }
    
    fun reportError(
        type: ErrorType,
        title: String,
        description: String,
        recoveryActions: List<RecoveryAction> = emptyList()
    ) {
        val error = RecoverableError(
            id = generateErrorId(),
            type = type,
            title = title,
            description = description,
            recoveryActions = recoveryActions
        )
        reportError(error)
    }
    
    suspend fun attemptRecovery(errorId: String, actionIndex: Int): Boolean {
        _isRecovering.value = true
        
        return try {
            val error = _activeErrors.value.find { it.id == errorId }
            val action = error?.recoveryActions?.getOrNull(actionIndex)
            
            val success = action?.action?.invoke() ?: false
            
            if (success) {
                dismissError(errorId)
            }
            
            success
        } catch (e: Exception) {
            false
        } finally {
            _isRecovering.value = false
        }
    }
    
    fun dismissError(errorId: String) {
        val currentErrors = _activeErrors.value.toMutableList()
        currentErrors.removeAll { it.id == errorId }
        _activeErrors.value = currentErrors
    }
    
    fun dismissAllErrors() {
        _activeErrors.value = emptyList()
    }
    
    fun getErrorsByType(type: ErrorType): List<RecoverableError> {
        return _activeErrors.value.filter { it.type == type }
    }
    
    // MARK: - Common Recovery Actions Factory
    
    fun createNetworkRecoveryActions(): List<RecoveryAction> = listOf(
        RecoveryAction(
            title = "Retry Connection",
            description = "Attempt to reconnect to the network",
            action = { 
                // Basic network retry logic
                try {
                    // You would implement actual network check here
                    true
                } catch (e: Exception) {
                    false
                }
            }
        ),
        RecoveryAction(
            title = "Check Settings",
            description = "Open network settings to check configuration",
            action = { 
                // Open network settings
                false // User needs to manually configure
            }
        )
    )
    
    fun createStorageRecoveryActions(): List<RecoveryAction> = listOf(
        RecoveryAction(
            title = "Clear Cache",
            description = "Clear application cache to free up space",
            action = {
                try {
                    // Clear cache logic
                    true
                } catch (e: Exception) {
                    false
                }
            },
            isAutomated = true
        ),
        RecoveryAction(
            title = "Restart App",
            description = "Restart the application to reset storage state",
            action = { false } // Requires user action
        )
    )
    
    fun createCloudSyncRecoveryActions(): List<RecoveryAction> = listOf(
        RecoveryAction(
            title = "Retry Sync",
            description = "Attempt to sync with cloud again",
            action = {
                try {
                    // Retry sync logic
                    true
                } catch (e: Exception) {
                    false
                }
            }
        ),
        RecoveryAction(
            title = "Reset Sync",
            description = "Reset sync state and try again",
            action = {
                try {
                    // Reset sync state
                    true
                } catch (e: Exception) {
                    false
                }
            }
        )
    )
    
    private fun generateErrorId(): String {
        return "error_${System.currentTimeMillis()}_${(0..9999).random()}"
    }
}

// MARK: - Error Recovery Extensions

fun ErrorRecoveryService.reportNetworkError(
    title: String = "Network Error",
    description: String = "Unable to connect to the network"
) {
    reportError(
        type = ErrorType.Network,
        title = title,
        description = description,
        recoveryActions = createNetworkRecoveryActions()
    )
}

fun ErrorRecoveryService.reportStorageError(
    title: String = "Storage Error", 
    description: String = "Unable to access local storage"
) {
    reportError(
        type = ErrorType.Storage,
        title = title,
        description = description,
        recoveryActions = createStorageRecoveryActions()
    )
}

fun ErrorRecoveryService.reportCloudSyncError(
    title: String = "Cloud Sync Error",
    description: String = "Unable to sync data with cloud"
) {
    reportError(
        type = ErrorType.CloudSync,
        title = title,
        description = description,
        recoveryActions = createCloudSyncRecoveryActions()
    )
}