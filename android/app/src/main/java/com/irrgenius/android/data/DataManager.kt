package com.irrgenius.android.data

import android.content.Context
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import com.irrgenius.android.data.models.SavedCalculation
import com.irrgenius.android.data.models.Project
import com.irrgenius.android.data.repository.RepositoryManager
import com.irrgenius.android.data.sync.CloudSyncService
import com.irrgenius.android.data.sync.SyncStatus
import com.irrgenius.android.data.sync.SyncConflict
import com.irrgenius.android.data.sync.ConflictResolution
import com.irrgenius.android.data.export.SharingException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Data manager for handling calculations, projects, and export operations
 */
class DataManager(private val context: Context) {
    
    // State
    val calculations = mutableStateListOf<SavedCalculation>()
    val projects = mutableStateListOf<Project>()
    val isLoading = mutableStateOf(false)
    val errorMessage = mutableStateOf<String?>(null)
    
    // Cloud sync state
    private val _isSyncEnabled = MutableStateFlow(false)
    val isSyncEnabled: StateFlow<Boolean> = _isSyncEnabled.asStateFlow()
    
    private val _syncStatus = MutableStateFlow<SyncStatus>(SyncStatus.Idle)
    val syncStatus: StateFlow<SyncStatus> = _syncStatus.asStateFlow()
    
    private val _syncProgress = MutableStateFlow(0.0)
    val syncProgress: StateFlow<Double> = _syncProgress.asStateFlow()
    
    private val _pendingConflicts = MutableStateFlow<List<String>>(emptyList())
    val pendingConflicts: StateFlow<List<String>> = _pendingConflicts.asStateFlow()
    
    // Services
    private val repositoryManager = RepositoryManager.getInstance(context)
    private val cloudSyncService = CloudSyncService(context, repositoryManager)
    private val sharingService = com.irrgenius.android.data.export.SharingService(context)
    private val coroutineScope = CoroutineScope(Dispatchers.Main)
    
    init {
        // Initialize sync enabled status
        val prefs = context.getSharedPreferences("cloud_sync", Context.MODE_PRIVATE)
        _isSyncEnabled.value = prefs.getBoolean("cloud_sync_enabled", false)
    }
    
    // MARK: - Calculation Management
    
    /**
     * Deletes a calculation
     */
    fun deleteCalculation(calculation: SavedCalculation) {
        calculations.remove(calculation)
        // TODO: Delete from repository when implemented
    }
    
    /**
     * Exports a calculation to PDF and shows share intent
     */
    fun exportCalculation(calculation: SavedCalculation) {
        coroutineScope.launch {
            isLoading.value = true
            errorMessage.value = null
            
            try {
                sharingService.shareCalculationAsPDF(calculation)
            } catch (e: SharingException) {
                errorMessage.value = "Failed to export calculation: ${e.message}"
            } catch (e: Exception) {
                errorMessage.value = "Unexpected error during export: ${e.message}"
            } finally {
                isLoading.value = false
            }
        }
    }
    
    /**
     * Exports multiple calculations to PDF and shows share intent
     */
    fun exportCalculations(calculations: List<SavedCalculation>) {
        coroutineScope.launch {
            isLoading.value = true
            errorMessage.value = null
            
            try {
                sharingService.shareMultipleCalculationsAsPDF(calculations)
            } catch (e: SharingException) {
                errorMessage.value = "Failed to export calculations: ${e.message}"
            } catch (e: Exception) {
                errorMessage.value = "Unexpected error during export: ${e.message}"
            } finally {
                isLoading.value = false
            }
        }
    }
    
    /**
     * Exports a calculation to CSV and shows share intent
     */
    fun exportCalculationToCSV(calculation: SavedCalculation) {
        coroutineScope.launch {
            isLoading.value = true
            errorMessage.value = null
            
            try {
                sharingService.shareCalculationAsCSV(calculation)
            } catch (e: SharingException) {
                errorMessage.value = "Failed to export calculation to CSV: ${e.message}"
            } catch (e: Exception) {
                errorMessage.value = "Unexpected error during CSV export: ${e.message}"
            } finally {
                isLoading.value = false
            }
        }
    }
    
    /**
     * Exports multiple calculations to CSV and shows share intent
     */
    fun exportCalculationsToCSV(calculations: List<SavedCalculation>) {
        coroutineScope.launch {
            isLoading.value = true
            errorMessage.value = null
            
            try {
                sharingService.shareMultipleCalculationsAsCSV(calculations)
            } catch (e: SharingException) {
                errorMessage.value = "Failed to export calculations to CSV: ${e.message}"
            } catch (e: Exception) {
                errorMessage.value = "Unexpected error during CSV export: ${e.message}"
            } finally {
                isLoading.value = false
            }
        }
    }
    
    // MARK: - Project Management
    
    /**
     * Creates a new project
     */
    fun createProject(name: String, description: String?) {
        val newProject = Project(
            id = java.util.UUID.randomUUID().toString(),
            name = name,
            description = description,
            createdDate = java.time.LocalDateTime.now(),
            modifiedDate = java.time.LocalDateTime.now(),
            color = null
        )
        projects.add(newProject)
        // TODO: Save to repository when implemented
    }
    
    /**
     * Updates an existing project
     */
    fun updateProject(project: Project, name: String, description: String?) {
        val index = projects.indexOfFirst { it.id == project.id }
        if (index != -1) {
            projects[index] = project.copy(
                name = name,
                description = description,
                modifiedDate = java.time.LocalDateTime.now()
            )
            // TODO: Update in repository when implemented
        }
    }
    
    /**
     * Deletes a project and moves its calculations to "No Project"
     */
    fun deleteProject(project: Project) {
        // Move calculations from this project to "No Project"
        for (i in calculations.indices) {
            if (calculations[i].projectId == project.id) {
                calculations[i] = calculations[i].copy(projectId = null)
            }
        }
        
        // Remove the project
        projects.removeAll { it.id == project.id }
        // TODO: Delete from repository when implemented
    }
    
    // MARK: - Cloud Sync Management
    
    /**
     * Enables cloud synchronization
     */
    fun enableCloudSync() {
        coroutineScope.launch {
            val result = cloudSyncService.enableSync()
            result.onSuccess {
                _isSyncEnabled.value = true
            }.onFailure { error ->
                errorMessage.value = "Failed to enable cloud sync: ${error.message}"
            }
        }
    }
    
    /**
     * Disables cloud synchronization
     */
    fun disableCloudSync() {
        coroutineScope.launch {
            val result = cloudSyncService.disableSync()
            result.onSuccess {
                _isSyncEnabled.value = false
            }.onFailure { error ->
                errorMessage.value = "Failed to disable cloud sync: ${error.message}"
            }
        }
    }
    
    /**
     * Manually triggers synchronization
     */
    fun manualSync() {
        coroutineScope.launch {
            val result = cloudSyncService.manualSync()
            result.onFailure { error ->
                errorMessage.value = "Sync failed: ${error.message}"
            }
        }
    }
    
    /**
     * Resolves a sync conflict
     */
    fun resolveSyncConflict(conflict: SyncConflict, resolution: ConflictResolution) {
        coroutineScope.launch {
            val result = cloudSyncService.resolveConflict(conflict, resolution)
            result.onFailure { error ->
                errorMessage.value = "Failed to resolve conflict: ${error.message}"
            }
        }
    }
    
    /**
     * Uploads a calculation to cloud storage after local save
     */
    private fun syncCalculationToCloud(calculation: SavedCalculation) {
        if (!_isSyncEnabled.value) return
        
        coroutineScope.launch {
            val result = cloudSyncService.uploadCalculation(calculation)
            result.onFailure { error ->
                // Don't show error to user for background sync failures
                android.util.Log.w("DataManager", "Failed to sync calculation to cloud: ${error.message}")
            }
        }
    }
    
    /**
     * Uploads a project to cloud storage after local save
     */
    private fun syncProjectToCloud(project: Project) {
        if (!_isSyncEnabled.value) return
        
        coroutineScope.launch {
            val result = cloudSyncService.uploadProject(project)
            result.onFailure { error ->
                // Don't show error to user for background sync failures
                android.util.Log.w("DataManager", "Failed to sync project to cloud: ${error.message}")
            }
        }
    }
    
    // MARK: - Data Refresh
    
    /**
     * Refreshes data from repository
     */
    suspend fun refreshData() {
        withContext(Dispatchers.IO) {
            // TODO: Implement data refresh from repository
            // For now, just simulate refresh
            kotlinx.coroutines.delay(500)
        }
    }
    
    // MARK: - Error Handling
    
    /**
     * Clears the current error message
     */
    fun clearError() {
        errorMessage.value = null
    }
    
    // MARK: - Progress Indicators
    
    /**
     * Shows loading state for long-running operations
     */
    private fun setLoading(loading: Boolean) {
        isLoading.value = loading
    }
}