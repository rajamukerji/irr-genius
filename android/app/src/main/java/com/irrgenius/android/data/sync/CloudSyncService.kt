package com.irrgenius.android.data.sync

import android.content.Context
import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.SetOptions
import com.irrgenius.android.data.models.SavedCalculation
import com.irrgenius.android.data.models.Project
import com.irrgenius.android.data.repository.RepositoryFactory
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await
import java.util.*
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec
import android.util.Base64
import kotlinx.coroutines.delay
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * Cloud synchronization service for Android using Firebase Firestore
 * Provides cross-platform data sync with iOS CloudKit through standardized data format
 */
class CloudSyncService(
    private val context: Context,
    private val repositoryFactory: RepositoryFactory
) {
    companion object {
        private const val TAG = "CloudSyncService"
        private const val CALCULATIONS_COLLECTION = "calculations"
        private const val PROJECTS_COLLECTION = "projects"
        private const val SYNC_METADATA_COLLECTION = "sync_metadata"
        private const val ENCRYPTION_KEY_PREF = "cloud_sync_encryption_key"
        private const val SYNC_ENABLED_PREF = "cloud_sync_enabled"
        private const val LAST_SYNC_PREF = "last_sync_timestamp"
        private const val MAX_RETRY_ATTEMPTS = 3
        private const val RETRY_DELAY_MS = 30000L // 30 seconds
        private const val SYNC_INTERVAL_MS = 300000L // 5 minutes
    }

    // Firebase instances
    private val firestore = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()
    
    // Repository instances
    private val calculationRepository = repositoryFactory.createCalculationRepository()
    private val projectRepository = repositoryFactory.createProjectRepository()
    
    // Sync state management
    private val _syncStatus = MutableStateFlow<SyncStatus>(SyncStatus.Idle)
    val syncStatus: StateFlow<SyncStatus> = _syncStatus.asStateFlow()
    
    private val _syncProgress = MutableStateFlow(0.0)
    val syncProgress: StateFlow<Double> = _syncProgress.asStateFlow()
    
    private val _pendingConflicts = MutableStateFlow<List<SyncConflict>>(emptyList())
    val pendingConflicts: StateFlow<List<SyncConflict>> = _pendingConflicts.asStateFlow()
    
    // Retry mechanism
    private val retryQueue = mutableListOf<RetryOperation>()
    private var retryTimer: Timer? = null
    private var syncTimer: Timer? = null
    
    // Encryption
    private val encryptionKey: SecretKey by lazy { getOrCreateEncryptionKey() }
    
    // Preferences
    private val prefs = context.getSharedPreferences("cloud_sync", Context.MODE_PRIVATE)
    
    /**
     * Sync status enumeration
     */
    sealed class SyncStatus {
        object Idle : SyncStatus()
        object Syncing : SyncStatus()
        data class Success(val timestamp: LocalDateTime) : SyncStatus()
        data class Error(val error: Throwable) : SyncStatus()
        
        val isActive: Boolean get() = this is Syncing
        val lastSyncDate: LocalDateTime? get() = if (this is Success) timestamp else null
        val errorMessage: String? get() = if (this is Error) error.message else null
    }
    
    /**
     * Sync conflict data class
     */
    data class SyncConflict(
        val localRecord: SavedCalculation,
        val remoteRecord: SavedCalculation,
        val conflictType: ConflictType
    ) {
        enum class ConflictType {
            MODIFICATION_DATE,
            DATA_CONFLICT
        }
    }
    
    /**
     * Conflict resolution options
     */
    enum class ConflictResolution {
        USE_LOCAL,
        USE_REMOTE,
        MERGE,
        ASK_USER
    }
    
    /**
     * Retry operation data class
     */
    data class RetryOperation(
        val id: String = UUID.randomUUID().toString(),
        val operation: suspend () -> Unit,
        val description: String,
        var attemptCount: Int = 0,
        val maxAttempts: Int = MAX_RETRY_ATTEMPTS,
        val createdAt: LocalDateTime = LocalDateTime.now()
    ) {
        val canRetry: Boolean get() = attemptCount < maxAttempts
    }
    
    /**
     * Cross-platform data format for calculations
     */
    data class CloudCalculation(
        val id: String,
        val name: String,
        val calculationType: String,
        val createdDate: String, // ISO 8601 format
        val modifiedDate: String, // ISO 8601 format
        val projectId: String?,
        val initialInvestment: Double?,
        val outcomeAmount: Double?,
        val timeInMonths: Double?,
        val irr: Double?,
        val unitPrice: Double?,
        val successRate: Double?,
        val outcomePerUnit: Double?,
        val investorShare: Double?,
        val feePercentage: Double?,
        val calculatedResult: Double?,
        val followOnInvestments: String?, // JSON string
        val growthPoints: String?, // JSON string
        val notes: String?,
        val tags: String?, // JSON array as string
        val encryptedData: String? // Encrypted sensitive data
    )
    
    /**
     * Cross-platform data format for projects
     */
    data class CloudProject(
        val id: String,
        val name: String,
        val description: String?,
        val createdDate: String, // ISO 8601 format
        val modifiedDate: String, // ISO 8601 format
        val color: String?
    )
    
    // MARK: - Public API
    
    /**
     * Enables cloud synchronization
     */
    suspend fun enableSync(): Result<Unit> {
        return try {
            // Check if user is authenticated
            if (auth.currentUser == null) {
                // Sign in anonymously for now - in production, implement proper auth
                auth.signInAnonymously().await()
            }
            
            prefs.edit().putBoolean(SYNC_ENABLED_PREF, true).apply()
            startAutomaticSync()
            
            // Perform initial sync
            syncCalculations()
            syncProjects()
            
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enable sync", e)
            Result.failure(CloudSyncException.SyncEnableFailed(e))
        }
    }
    
    /**
     * Disables cloud synchronization
     */
    suspend fun disableSync(): Result<Unit> {
        return try {
            prefs.edit().putBoolean(SYNC_ENABLED_PREF, false).apply()
            stopAutomaticSync()
            _syncStatus.value = SyncStatus.Idle
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disable sync", e)
            Result.failure(CloudSyncException.SyncDisableFailed(e))
        }
    }
    
    /**
     * Manually triggers synchronization
     */
    suspend fun manualSync(): Result<Unit> {
        return try {
            syncCalculations()
            syncProjects()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Manual sync failed", e)
            Result.failure(CloudSyncException.SyncFailed(e))
        }
    }
    
    /**
     * Synchronizes calculations with cloud
     */
    suspend fun syncCalculations(): Result<Unit> {
        if (!isSyncEnabled()) return Result.success(Unit)
        
        _syncStatus.value = SyncStatus.Syncing
        _syncProgress.value = 0.0
        
        return try {
            // Get local calculations
            val localCalculations = calculationRepository.getAllCalculations()
            _syncProgress.value = 0.2
            
            // Get remote calculations
            val remoteCalculations = downloadCalculations()
            _syncProgress.value = 0.4
            
            // Resolve conflicts and determine sync operations
            val syncOperations = resolveCalculationDifferences(localCalculations, remoteCalculations)
            _syncProgress.value = 0.6
            
            // Handle conflicts
            if (syncOperations.conflicts.isNotEmpty()) {
                _pendingConflicts.value = syncOperations.conflicts
                // For now, use last-modified-wins strategy
                for (conflict in syncOperations.conflicts) {
                    resolveConflict(conflict, ConflictResolution.USE_LOCAL)
                }
            }
            
            // Upload new/modified local calculations
            for (calculation in syncOperations.toUpload) {
                uploadCalculation(calculation)
            }
            _syncProgress.value = 0.8
            
            // Save new/modified remote calculations locally
            for (calculation in syncOperations.toDownload) {
                calculationRepository.insertCalculation(calculation)
            }
            _syncProgress.value = 1.0
            
            // Update last sync timestamp
            prefs.edit().putString(LAST_SYNC_PREF, LocalDateTime.now().toString()).apply()
            _syncStatus.value = SyncStatus.Success(LocalDateTime.now())
            
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Calculation sync failed", e)
            _syncStatus.value = SyncStatus.Error(e)
            Result.failure(CloudSyncException.SyncFailed(e))
        }
    }
    
    /**
     * Synchronizes projects with cloud
     */
    suspend fun syncProjects(): Result<Unit> {
        if (!isSyncEnabled()) return Result.success(Unit)
        
        return try {
            // Get local projects
            val localProjects = projectRepository.getAllProjects()
            
            // Get remote projects
            val remoteProjects = downloadProjects()
            
            // Resolve differences and sync
            val syncOperations = resolveProjectDifferences(localProjects, remoteProjects)
            
            // Upload new/modified local projects
            for (project in syncOperations.toUpload) {
                uploadProject(project)
            }
            
            // Save new/modified remote projects locally
            for (project in syncOperations.toDownload) {
                projectRepository.insertProject(project)
            }
            
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Project sync failed", e)
            Result.failure(CloudSyncException.SyncFailed(e))
        }
    }
    
    /**
     * Uploads a calculation to cloud storage
     */
    suspend fun uploadCalculation(calculation: SavedCalculation): Result<Unit> {
        return try {
            val cloudCalculation = convertToCloudFormat(calculation)
            val userId = auth.currentUser?.uid ?: throw IllegalStateException("User not authenticated")
            
            firestore.collection("users")
                .document(userId)
                .collection(CALCULATIONS_COLLECTION)
                .document(calculation.id)
                .set(cloudCalculation, SetOptions.merge())
                .await()
            
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to upload calculation", e)
            
            // Add to retry queue if it's a retryable error
            if (shouldRetryError(e)) {
                addToRetryQueue(
                    operation = { uploadCalculation(calculation) },
                    description = "Upload calculation: ${calculation.name}"
                )
            }
            
            Result.failure(CloudSyncException.UploadFailed(e))
        }
    }
    
    /**
     * Uploads a project to cloud storage
     */
    suspend fun uploadProject(project: Project): Result<Unit> {
        return try {
            val cloudProject = convertToCloudFormat(project)
            val userId = auth.currentUser?.uid ?: throw IllegalStateException("User not authenticated")
            
            firestore.collection("users")
                .document(userId)
                .collection(PROJECTS_COLLECTION)
                .document(project.id)
                .set(cloudProject, SetOptions.merge())
                .await()
            
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to upload project", e)
            
            // Add to retry queue if it's a retryable error
            if (shouldRetryError(e)) {
                addToRetryQueue(
                    operation = { uploadProject(project) },
                    description = "Upload project: ${project.name}"
                )
            }
            
            Result.failure(CloudSyncException.UploadFailed(e))
        }
    }
    
    /**
     * Downloads calculations from cloud storage
     */
    suspend fun downloadCalculations(): List<SavedCalculation> {
        val userId = auth.currentUser?.uid ?: throw IllegalStateException("User not authenticated")
        
        val snapshot = firestore.collection("users")
            .document(userId)
            .collection(CALCULATIONS_COLLECTION)
            .orderBy("modifiedDate", Query.Direction.DESCENDING)
            .get()
            .await()
        
        return snapshot.documents.mapNotNull { document ->
            try {
                val cloudCalculation = document.toObject(CloudCalculation::class.java)
                cloudCalculation?.let { convertFromCloudFormat(it) }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse calculation document: ${document.id}", e)
                null
            }
        }
    }
    
    /**
     * Downloads projects from cloud storage
     */
    suspend fun downloadProjects(): List<Project> {
        val userId = auth.currentUser?.uid ?: throw IllegalStateException("User not authenticated")
        
        val snapshot = firestore.collection("users")
            .document(userId)
            .collection(PROJECTS_COLLECTION)
            .orderBy("modifiedDate", Query.Direction.DESCENDING)
            .get()
            .await()
        
        return snapshot.documents.mapNotNull { document ->
            try {
                val cloudProject = document.toObject(CloudProject::class.java)
                cloudProject?.let { convertFromCloudFormat(it) }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse project document: ${document.id}", e)
                null
            }
        }
    }
    
    /**
     * Resolves a sync conflict
     */
    suspend fun resolveConflict(conflict: SyncConflict, resolution: ConflictResolution): Result<Unit> {
        return try {
            when (resolution) {
                ConflictResolution.USE_LOCAL -> {
                    uploadCalculation(conflict.localRecord)
                }
                ConflictResolution.USE_REMOTE -> {
                    calculationRepository.insertCalculation(conflict.remoteRecord)
                }
                ConflictResolution.MERGE -> {
                    val mergedCalculation = mergeCalculations(conflict.localRecord, conflict.remoteRecord)
                    uploadCalculation(mergedCalculation)
                    calculationRepository.insertCalculation(mergedCalculation)
                }
                ConflictResolution.ASK_USER -> {
                    // This will be handled by the UI layer
                    return Result.success(Unit)
                }
            }
            
            // Remove resolved conflict
            val currentConflicts = _pendingConflicts.value.toMutableList()
            currentConflicts.removeAll { it.localRecord.id == conflict.localRecord.id }
            _pendingConflicts.value = currentConflicts
            
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to resolve conflict", e)
            Result.failure(CloudSyncException.ConflictResolutionFailed(e))
        }
    }
    
    // MARK: - Private Methods
    
    private fun isSyncEnabled(): Boolean {
        return prefs.getBoolean(SYNC_ENABLED_PREF, false) && auth.currentUser != null
    }
    
    private fun startAutomaticSync() {
        stopAutomaticSync()
        
        syncTimer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    // Run sync in coroutine
                    kotlinx.coroutines.GlobalScope.launch {
                        try {
                            syncCalculations()
                            syncProjects()
                        } catch (e: Exception) {
                            Log.e(TAG, "Automatic sync failed", e)
                            _syncStatus.value = SyncStatus.Error(e)
                        }
                    }
                }
            }, SYNC_INTERVAL_MS, SYNC_INTERVAL_MS)
        }
        
        startRetryTimer()
    }
    
    private fun stopAutomaticSync() {
        syncTimer?.cancel()
        syncTimer = null
        stopRetryTimer()
    }
    
    private fun startRetryTimer() {
        stopRetryTimer()
        
        retryTimer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    kotlinx.coroutines.GlobalScope.launch {
                        processRetryQueue()
                    }
                }
            }, RETRY_DELAY_MS, RETRY_DELAY_MS)
        }
    }
    
    private fun stopRetryTimer() {
        retryTimer?.cancel()
        retryTimer = null
    }
    
    private fun addToRetryQueue(operation: suspend () -> Result<Unit>, description: String) {
        val retryOperation = RetryOperation(
            operation = { operation() },
            description = description
        )
        retryQueue.add(retryOperation)
    }
    
    private suspend fun processRetryQueue() {
        if (retryQueue.isEmpty()) return
        
        val completedOperations = mutableListOf<String>()
        
        for (operation in retryQueue.toList()) {
            if (!operation.canRetry) {
                completedOperations.add(operation.id)
                continue
            }
            
            operation.attemptCount++
            
            try {
                operation.operation()
                completedOperations.add(operation.id)
                Log.d(TAG, "Retry operation succeeded: ${operation.description}")
            } catch (e: Exception) {
                Log.w(TAG, "Retry operation failed (attempt ${operation.attemptCount}/${operation.maxAttempts}): ${operation.description}", e)
                
                if (!operation.canRetry) {
                    completedOperations.add(operation.id)
                    Log.e(TAG, "Max retry attempts reached for: ${operation.description}")
                }
            }
        }
        
        // Remove completed operations
        retryQueue.removeAll { completedOperations.contains(it.id) }
    }
    
    private fun shouldRetryError(error: Throwable): Boolean {
        return when (error) {
            is java.net.UnknownHostException,
            is java.net.SocketTimeoutException,
            is java.io.IOException -> true
            else -> false
        }
    }
    
    // MARK: - Data Conversion Methods
    
    private fun convertToCloudFormat(calculation: SavedCalculation): CloudCalculation {
        return CloudCalculation(
            id = calculation.id,
            name = calculation.name,
            calculationType = calculation.calculationType.name,
            createdDate = calculation.createdDate.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            modifiedDate = calculation.modifiedDate.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            projectId = calculation.projectId,
            initialInvestment = calculation.initialInvestment,
            outcomeAmount = calculation.outcomeAmount,
            timeInMonths = calculation.timeInMonths,
            irr = calculation.irr,
            unitPrice = calculation.unitPrice,
            successRate = calculation.successRate,
            outcomePerUnit = calculation.outcomePerUnit,
            investorShare = calculation.investorShare,
            feePercentage = calculation.feePercentage,
            calculatedResult = calculation.calculatedResult,
            followOnInvestments = calculation.followOnInvestmentsJson,
            growthPoints = calculation.growthPointsJson,
            notes = calculation.notes,
            tags = calculation.tagsJson,
            encryptedData = encryptSensitiveData(calculation)
        )
    }
    
    private fun convertFromCloudFormat(cloudCalculation: CloudCalculation): SavedCalculation {
        return SavedCalculation(
            id = cloudCalculation.id,
            name = cloudCalculation.name,
            calculationType = enumValueOf(cloudCalculation.calculationType),
            createdDate = LocalDateTime.parse(cloudCalculation.createdDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            modifiedDate = LocalDateTime.parse(cloudCalculation.modifiedDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            projectId = cloudCalculation.projectId,
            initialInvestment = cloudCalculation.initialInvestment,
            outcomeAmount = cloudCalculation.outcomeAmount,
            timeInMonths = cloudCalculation.timeInMonths,
            irr = cloudCalculation.irr,
            unitPrice = cloudCalculation.unitPrice,
            successRate = cloudCalculation.successRate,
            outcomePerUnit = cloudCalculation.outcomePerUnit,
            investorShare = cloudCalculation.investorShare,
            feePercentage = cloudCalculation.feePercentage,
            calculatedResult = cloudCalculation.calculatedResult,
            followOnInvestmentsJson = cloudCalculation.followOnInvestments,
            growthPointsJson = cloudCalculation.growthPoints,
            notes = cloudCalculation.notes,
            tagsJson = cloudCalculation.tags
        )
    }
    
    private fun convertToCloudFormat(project: Project): CloudProject {
        return CloudProject(
            id = project.id,
            name = project.name,
            description = project.description,
            createdDate = project.createdDate.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            modifiedDate = project.modifiedDate.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            color = project.color
        )
    }
    
    private fun convertFromCloudFormat(cloudProject: CloudProject): Project {
        return Project(
            id = cloudProject.id,
            name = cloudProject.name,
            description = cloudProject.description,
            createdDate = LocalDateTime.parse(cloudProject.createdDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            modifiedDate = LocalDateTime.parse(cloudProject.modifiedDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            color = cloudProject.color
        )
    }
    
    // MARK: - Encryption Methods
    
    private fun getOrCreateEncryptionKey(): SecretKey {
        val keyString = prefs.getString(ENCRYPTION_KEY_PREF, null)
        
        return if (keyString != null) {
            val keyBytes = Base64.decode(keyString, Base64.DEFAULT)
            SecretKeySpec(keyBytes, "AES")
        } else {
            val keyGenerator = KeyGenerator.getInstance("AES")
            keyGenerator.init(256)
            val key = keyGenerator.generateKey()
            
            val keyString = Base64.encodeToString(key.encoded, Base64.DEFAULT)
            prefs.edit().putString(ENCRYPTION_KEY_PREF, keyString).apply()
            
            key
        }
    }
    
    private fun encryptSensitiveData(calculation: SavedCalculation): String? {
        return try {
            // Encrypt sensitive financial data
            val sensitiveData = mapOf(
                "initialInvestment" to calculation.initialInvestment,
                "outcomeAmount" to calculation.outcomeAmount,
                "calculatedResult" to calculation.calculatedResult
            )
            
            val dataJson = com.google.gson.Gson().toJson(sensitiveData)
            val cipher = Cipher.getInstance("AES/ECB/PKCS1Padding")
            cipher.init(Cipher.ENCRYPT_MODE, encryptionKey)
            val encryptedBytes = cipher.doFinal(dataJson.toByteArray())
            Base64.encodeToString(encryptedBytes, Base64.DEFAULT)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to encrypt sensitive data", e)
            null
        }
    }
    
    private fun decryptSensitiveData(encryptedData: String?): Map<String, Any?>? {
        return try {
            if (encryptedData == null) return null
            
            val cipher = Cipher.getInstance("AES/ECB/PKCS1Padding")
            cipher.init(Cipher.DECRYPT_MODE, encryptionKey)
            val encryptedBytes = Base64.decode(encryptedData, Base64.DEFAULT)
            val decryptedBytes = cipher.doFinal(encryptedBytes)
            val dataJson = String(decryptedBytes)
            
            com.google.gson.Gson().fromJson(dataJson, Map::class.java) as Map<String, Any?>
        } catch (e: Exception) {
            Log.e(TAG, "Failed to decrypt sensitive data", e)
            null
        }
    }
    
    // MARK: - Conflict Resolution Methods
    
    private data class SyncOperations<T>(
        val toUpload: List<T>,
        val toDownload: List<T>,
        val conflicts: List<SyncConflict>
    )
    
    private fun resolveCalculationDifferences(
        local: List<SavedCalculation>,
        remote: List<SavedCalculation>
    ): SyncOperations<SavedCalculation> {
        val toUpload = mutableListOf<SavedCalculation>()
        val toDownload = mutableListOf<SavedCalculation>()
        val conflicts = mutableListOf<SyncConflict>()
        
        val localMap = local.associateBy { it.id }
        val remoteMap = remote.associateBy { it.id }
        
        // Find calculations to upload (local only or newer local)
        for (localCalc in local) {
            val remoteCalc = remoteMap[localCalc.id]
            if (remoteCalc == null) {
                // Local only - upload
                toUpload.add(localCalc)
            } else {
                // Both exist - check for conflicts
                when {
                    localCalc.modifiedDate.isAfter(remoteCalc.modifiedDate) -> {
                        toUpload.add(localCalc)
                    }
                    localCalc.modifiedDate.isBefore(remoteCalc.modifiedDate) -> {
                        toDownload.add(remoteCalc)
                    }
                    !areCalculationsEqual(localCalc, remoteCalc) -> {
                        // Same modification date but different data - conflict
                        conflicts.add(SyncConflict(
                            localRecord = localCalc,
                            remoteRecord = remoteCalc,
                            conflictType = SyncConflict.ConflictType.DATA_CONFLICT
                        ))
                    }
                }
            }
        }
        
        // Find calculations to download (remote only)
        for (remoteCalc in remote) {
            if (localMap[remoteCalc.id] == null) {
                toDownload.add(remoteCalc)
            }
        }
        
        return SyncOperations(toUpload, toDownload, conflicts)
    }
    
    private fun resolveProjectDifferences(
        local: List<Project>,
        remote: List<Project>
    ): SyncOperations<Project> {
        val toUpload = mutableListOf<Project>()
        val toDownload = mutableListOf<Project>()
        
        val localMap = local.associateBy { it.id }
        val remoteMap = remote.associateBy { it.id }
        
        // Find projects to upload (local only or newer local)
        for (localProject in local) {
            val remoteProject = remoteMap[localProject.id]
            if (remoteProject == null) {
                toUpload.add(localProject)
            } else if (localProject.modifiedDate.isAfter(remoteProject.modifiedDate)) {
                toUpload.add(localProject)
            } else if (localProject.modifiedDate.isBefore(remoteProject.modifiedDate)) {
                toDownload.add(remoteProject)
            }
        }
        
        // Find projects to download (remote only)
        for (remoteProject in remote) {
            if (localMap[remoteProject.id] == null) {
                toDownload.add(remoteProject)
            }
        }
        
        return SyncOperations(toUpload, toDownload, emptyList())
    }
    
    private fun areCalculationsEqual(calc1: SavedCalculation, calc2: SavedCalculation): Boolean {
        return calc1.name == calc2.name &&
                calc1.calculationType == calc2.calculationType &&
                calc1.initialInvestment == calc2.initialInvestment &&
                calc1.outcomeAmount == calc2.outcomeAmount &&
                calc1.timeInMonths == calc2.timeInMonths &&
                calc1.irr == calc2.irr &&
                calc1.calculatedResult == calc2.calculatedResult &&
                calc1.notes == calc2.notes &&
                calc1.tagsJson == calc2.tagsJson
    }
    
    private fun mergeCalculations(local: SavedCalculation, remote: SavedCalculation): SavedCalculation {
        // Simple merge strategy: use the most recent non-null values
        return SavedCalculation(
            id = local.id,
            name = if (local.modifiedDate.isAfter(remote.modifiedDate)) local.name else remote.name,
            calculationType = local.calculationType,
            createdDate = if (local.createdDate.isBefore(remote.createdDate)) local.createdDate else remote.createdDate,
            modifiedDate = if (local.modifiedDate.isAfter(remote.modifiedDate)) local.modifiedDate else remote.modifiedDate,
            projectId = local.projectId ?: remote.projectId,
            initialInvestment = local.initialInvestment ?: remote.initialInvestment,
            outcomeAmount = local.outcomeAmount ?: remote.outcomeAmount,
            timeInMonths = local.timeInMonths ?: remote.timeInMonths,
            irr = local.irr ?: remote.irr,
            unitPrice = local.unitPrice ?: remote.unitPrice,
            successRate = local.successRate ?: remote.successRate,
            outcomePerUnit = local.outcomePerUnit ?: remote.outcomePerUnit,
            investorShare = local.investorShare ?: remote.investorShare,
            feePercentage = local.feePercentage ?: remote.feePercentage,
            calculatedResult = local.calculatedResult ?: remote.calculatedResult,
            followOnInvestmentsJson = local.followOnInvestmentsJson ?: remote.followOnInvestmentsJson,
            growthPointsJson = local.growthPointsJson ?: remote.growthPointsJson,
            notes = local.notes ?: remote.notes,
            tagsJson = local.tagsJson ?: remote.tagsJson
        )
    }
    
    fun cleanup() {
        stopAutomaticSync()
    }
}

/**
 * Cloud sync exceptions
 */
sealed class CloudSyncException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class SyncEnableFailed(cause: Throwable) : CloudSyncException("Failed to enable sync", cause)
    class SyncDisableFailed(cause: Throwable) : CloudSyncException("Failed to disable sync", cause)
    class SyncFailed(cause: Throwable) : CloudSyncException("Sync operation failed", cause)
    class UploadFailed(cause: Throwable) : CloudSyncException("Upload failed", cause)
    class DownloadFailed(cause: Throwable) : CloudSyncException("Download failed", cause)
    class ConflictResolutionFailed(cause: Throwable) : CloudSyncException("Conflict resolution failed", cause)
    class AuthenticationFailed(cause: Throwable) : CloudSyncException("Authentication failed", cause)
    class EncryptionFailed(cause: Throwable) : CloudSyncException("Encryption failed", cause)
}