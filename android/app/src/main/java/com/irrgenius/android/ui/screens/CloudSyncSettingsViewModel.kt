package com.irrgenius.android.ui.screens

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.irrgenius.android.data.repository.RepositoryManager
import com.irrgenius.android.data.sync.CloudSyncService
import com.irrgenius.android.data.sync.SyncStatus
import com.irrgenius.android.data.sync.SyncConflict
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class CloudSyncSettingsViewModel(application: Application) : AndroidViewModel(application) {
    
    private val repositoryManager = RepositoryManager.getInstance(application)
    private val cloudSyncService = CloudSyncService(application, repositoryManager)
    
    // Expose sync service state flows
    val syncStatus: StateFlow<SyncStatus> = cloudSyncService.syncStatus
    val syncProgress: StateFlow<Double> = cloudSyncService.syncProgress
    val pendingConflicts: StateFlow<List<SyncConflict>> = cloudSyncService.pendingConflicts
    
    // Local state for sync enabled status
    private val _isSyncEnabled = MutableStateFlow(false)
    val isSyncEnabled: StateFlow<Boolean> = _isSyncEnabled.asStateFlow()
    
    init {
        // Initialize sync enabled status from preferences
        val prefs = application.getSharedPreferences("cloud_sync", android.content.Context.MODE_PRIVATE)
        _isSyncEnabled.value = prefs.getBoolean("cloud_sync_enabled", false)
    }
    
    /**
     * Enables cloud synchronization
     */
    fun enableSync() {
        viewModelScope.launch {
            val result = cloudSyncService.enableSync()
            result.onSuccess {
                _isSyncEnabled.value = true
            }.onFailure { error ->
                // Error will be handled by sync status flow
                android.util.Log.e("CloudSyncViewModel", "Failed to enable sync", error)
            }
        }
    }
    
    /**
     * Disables cloud synchronization
     */
    fun disableSync() {
        viewModelScope.launch {
            val result = cloudSyncService.disableSync()
            result.onSuccess {
                _isSyncEnabled.value = false
            }.onFailure { error ->
                android.util.Log.e("CloudSyncViewModel", "Failed to disable sync", error)
            }
        }
    }
    
    /**
     * Manually triggers synchronization
     */
    fun manualSync() {
        viewModelScope.launch {
            val result = cloudSyncService.manualSync()
            result.onFailure { error ->
                android.util.Log.e("CloudSyncViewModel", "Manual sync failed", error)
            }
        }
    }
    
    /**
     * Resolves a sync conflict
     */
    fun resolveConflict(conflict: CloudSyncService.SyncConflict, resolution: CloudSyncService.ConflictResolution) {
        viewModelScope.launch {
            val result = cloudSyncService.resolveConflict(conflict, resolution)
            result.onFailure { error ->
                android.util.Log.e("CloudSyncViewModel", "Failed to resolve conflict", error)
            }
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        cloudSyncService.cleanup()
    }
}