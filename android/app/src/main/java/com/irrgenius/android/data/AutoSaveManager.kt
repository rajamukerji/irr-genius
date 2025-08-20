package com.irrgenius.android.data

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.irrgenius.android.data.models.*
import com.irrgenius.android.data.repository.RepositoryManager
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.util.UUID

// Auto-save configuration
data class AutoSaveConfiguration(
    val isEnabled: Boolean = true,
    val saveDelayMs: Long = 1000L, // Delay after calculation before auto-save
    val draftSaveIntervalMs: Long = 30000L, // Interval for saving drafts
    val showSaveDialog: Boolean = true // Whether to show save dialog after calculation
)

// Save dialog data
data class SaveDialogData(
    val name: String = "",
    val projectId: String? = null,
    val notes: String = "",
    val tags: List<String> = emptyList(),
    val isVisible: Boolean = false,
    val calculationToSave: SavedCalculation? = null
)

// Unsaved changes detection
data class UnsavedChanges(
    val hasChanges: Boolean = false,
    val lastModified: LocalDateTime = LocalDateTime.now(),
    val changeDescription: String = ""
) {
    companion object {
        val none = UnsavedChanges()
    }
}

class AutoSaveManager : ViewModel() {
    
    private lateinit var repositoryManager: RepositoryManager
    private val calculationRepository by lazy { repositoryManager.calculationRepository }
    private val projectRepository by lazy { repositoryManager.projectRepository }
    
    fun initialize(context: Context) {
        repositoryManager = RepositoryManager.getInstance(context)
    }
    
    // State flows
    private val _calculations = MutableStateFlow<List<SavedCalculation>>(emptyList())
    val calculations: StateFlow<List<SavedCalculation>> = _calculations.asStateFlow()
    
    private val _projects = MutableStateFlow<List<Project>>(emptyList())
    val projects: StateFlow<List<Project>> = _projects.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()
    
    private val _loadingState = MutableStateFlow<com.irrgenius.android.ui.components.LoadingState>(com.irrgenius.android.ui.components.LoadingState.Idle)
    val loadingState: StateFlow<com.irrgenius.android.ui.components.LoadingState> = _loadingState.asStateFlow()
    
    private val _syncProgress = MutableStateFlow(0f)
    val syncProgress: StateFlow<Float> = _syncProgress.asStateFlow()
    
    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()
    
    private val _saveDialogData = MutableStateFlow(SaveDialogData())
    val saveDialogData: StateFlow<SaveDialogData> = _saveDialogData.asStateFlow()
    
    private val _unsavedChanges = MutableStateFlow(UnsavedChanges.none)
    val unsavedChanges: StateFlow<UnsavedChanges> = _unsavedChanges.asStateFlow()
    
    private val _autoSaveConfiguration = MutableStateFlow(AutoSaveConfiguration())
    val autoSaveConfiguration: StateFlow<AutoSaveConfiguration> = _autoSaveConfiguration.asStateFlow()
    
    // Private properties
    private var autoSaveJob: Job? = null
    private var draftSaveJob: Job? = null
    private var lastCalculationInputs: Map<String, Any> = emptyMap()
    private var pendingCalculation: SavedCalculation? = null
    
    init {
        setupAutoSave()
        loadInitialData()
    }
    
    // MARK: - Auto-Save Setup
    
    private fun setupAutoSave() {
        if (_autoSaveConfiguration.value.isEnabled) {
            startDraftSaveTimer()
        }
    }
    
    private fun startDraftSaveTimer() {
        draftSaveJob?.cancel()
        draftSaveJob = viewModelScope.launch {
            while (true) {
                delay(_autoSaveConfiguration.value.draftSaveIntervalMs)
                saveDraftIfNeeded()
            }
        }
    }
    
    private fun stopDraftSaveTimer() {
        draftSaveJob?.cancel()
        draftSaveJob = null
    }
    
    // MARK: - Data Loading
    
    private fun loadInitialData() {
        viewModelScope.launch {
            loadCalculations()
            loadProjects()
        }
    }
    
    fun loadCalculations() {
        viewModelScope.launch {
            _loadingState.value = com.irrgenius.android.ui.components.LoadingState.Loading("Loading calculations...")
            _errorMessage.value = null
            
            try {
                val loadedCalculations = calculationRepository.loadCalculations()
                _calculations.value = loadedCalculations.sortedByDescending { it.modifiedDate }
                _loadingState.value = com.irrgenius.android.ui.components.LoadingState.Idle
            } catch (e: Exception) {
                _errorMessage.value = e.message
                _loadingState.value = com.irrgenius.android.ui.components.LoadingState.Error(e.message ?: "Failed to load calculations")
            }
        }
    }
    
    fun loadProjects() {
        viewModelScope.launch {
            try {
                val loadedProjects = projectRepository.loadProjects()
                _projects.value = loadedProjects.sortedByDescending { it.modifiedDate }
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }
    
    // MARK: - Auto-Save Functionality
    
    /**
     * Called after a successful calculation to trigger auto-save
     */
    fun handleCalculationCompleted(
        calculationType: CalculationMode,
        inputs: Map<String, Any>,
        result: Double,
        growthPoints: List<GrowthPoint>?
    ) {
        // Stop any existing auto-save job
        autoSaveJob?.cancel()
        
        // Create calculation object
        val calculation = createCalculationFromInputs(
            calculationType = calculationType,
            inputs = inputs,
            result = result,
            growthPoints = growthPoints
        )
        
        if (calculation == null) {
            _errorMessage.value = "Failed to create calculation from inputs"
            return
        }
        
        pendingCalculation = calculation
        
        if (_autoSaveConfiguration.value.isEnabled) {
            if (_autoSaveConfiguration.value.showSaveDialog) {
                // Show save dialog after delay
                autoSaveJob = viewModelScope.launch {
                    delay(_autoSaveConfiguration.value.saveDelayMs)
                    showSaveDialog(calculation)
                }
            } else {
                // Auto-save without dialog
                autoSaveJob = viewModelScope.launch {
                    delay(_autoSaveConfiguration.value.saveDelayMs)
                    autoSaveCalculation(calculation)
                }
            }
        }
    }
    
    /**
     * Shows save dialog for the calculation
     */
    fun showSaveDialog(calculation: SavedCalculation) {
        _saveDialogData.value = SaveDialogData(
            name = generateDefaultName(calculation),
            projectId = null,
            notes = "",
            tags = emptyList(),
            isVisible = true,
            calculationToSave = calculation
        )
    }
    
    /**
     * Auto-saves calculation without user interaction
     */
    private suspend fun autoSaveCalculation(calculation: SavedCalculation) {
        val namedCalculation = calculation.copy(
            name = generateDefaultName(calculation),
            modifiedDate = LocalDateTime.now(),
            projectId = null,
            notes = "Auto-saved calculation",
            tags = "[\"auto-saved\"]"
        )
        
        saveCalculation(namedCalculation)
    }
    
    /**
     * Generates a default name for a calculation
     */
    private fun generateDefaultName(calculation: SavedCalculation): String {
        val typeString = calculation.calculationType.displayName
        val dateString = calculation.createdDate.toString().substring(0, 16) // YYYY-MM-DDTHH:MM
        
        return "$typeString - $dateString"
    }
    
    // MARK: - Save Dialog Actions
    
    /**
     * Updates save dialog data
     */
    fun updateSaveDialogData(
        name: String? = null,
        projectId: String? = null,
        notes: String? = null,
        tags: List<String>? = null
    ) {
        _saveDialogData.value = _saveDialogData.value.copy(
            name = name ?: _saveDialogData.value.name,
            projectId = projectId ?: _saveDialogData.value.projectId,
            notes = notes ?: _saveDialogData.value.notes,
            tags = tags ?: _saveDialogData.value.tags
        )
    }
    
    /**
     * Saves calculation from save dialog
     */
    fun saveFromDialog() {
        viewModelScope.launch {
            val dialogData = _saveDialogData.value
            val calculation = dialogData.calculationToSave ?: return@launch
            
            val namedCalculation = calculation.copy(
                name = dialogData.name.ifEmpty { generateDefaultName(calculation) },
                modifiedDate = LocalDateTime.now(),
                projectId = dialogData.projectId,
                notes = dialogData.notes.ifEmpty { null },
                tags = if (dialogData.tags.isEmpty()) "[]" else "[" + dialogData.tags.joinToString(",") { "\"$it\"" } + "]"
            )
            
            saveCalculation(namedCalculation)
            dismissSaveDialog()
        }
    }
    
    /**
     * Dismisses save dialog
     */
    fun dismissSaveDialog() {
        _saveDialogData.value = SaveDialogData()
        pendingCalculation = null
    }
    
    // MARK: - Unsaved Changes Detection
    
    /**
     * Updates input tracking for unsaved changes detection
     */
    fun updateInputs(inputs: Map<String, Any>) {
        val hasChanges = inputs.isNotEmpty() && inputs != lastCalculationInputs
        
        if (hasChanges) {
            _unsavedChanges.value = UnsavedChanges(
                hasChanges = true,
                lastModified = LocalDateTime.now(),
                changeDescription = "Calculation inputs modified"
            )
        } else {
            _unsavedChanges.value = UnsavedChanges.none
        }
        
        lastCalculationInputs = inputs
    }
    
    /**
     * Clears unsaved changes (called after save or calculation)
     */
    fun clearUnsavedChanges() {
        _unsavedChanges.value = UnsavedChanges.none
        lastCalculationInputs = emptyMap()
    }
    
    /**
     * Shows warning for unsaved changes
     */
    fun showUnsavedChangesWarning(): Boolean {
        return _unsavedChanges.value.hasChanges
    }
    
    // MARK: - Draft Saving
    
    /**
     * Saves draft calculation if there are unsaved changes
     */
    private suspend fun saveDraftIfNeeded() {
        if (!_unsavedChanges.value.hasChanges || lastCalculationInputs.isEmpty()) return
        
        // Create draft calculation from current inputs
        val draftCalculation = createDraftCalculation()
        if (draftCalculation != null) {
            saveDraftCalculation(draftCalculation)
        }
    }
    
    /**
     * Creates a draft calculation from current inputs
     */
    private fun createDraftCalculation(): SavedCalculation? {
        // This would need to be called with current form state
        // For now, return null as we need form state from the view
        return null
    }
    
    /**
     * Saves a draft calculation
     */
    private suspend fun saveDraftCalculation(calculation: SavedCalculation) {
        val draftCalculation = calculation.copy(
            name = "[DRAFT] ${calculation.name}",
            modifiedDate = LocalDateTime.now(),
            notes = "Draft saved automatically",
            tags = "[\"draft\", \"auto-saved\"]"
        )
        
        saveCalculation(draftCalculation)
    }
    
    // MARK: - Calculation Management
    
    /**
     * Saves a calculation
     */
    fun saveCalculation(calculation: SavedCalculation) {
        viewModelScope.launch {
            try {
                calculationRepository.saveCalculation(calculation)
                
                // Update local list
                val currentCalculations = _calculations.value.toMutableList()
                val existingIndex = currentCalculations.indexOfFirst { it.id == calculation.id }
                
                if (existingIndex >= 0) {
                    currentCalculations[existingIndex] = calculation
                } else {
                    currentCalculations.add(0, calculation)
                }
                
                _calculations.value = currentCalculations.sortedByDescending { it.modifiedDate }
                clearUnsavedChanges()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }
    
    /**
     * Deletes a calculation
     */
    fun deleteCalculation(calculation: SavedCalculation) {
        viewModelScope.launch {
            try {
                calculationRepository.deleteCalculation(calculation.id)
                _calculations.value = _calculations.value.filter { it.id != calculation.id }
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }
    
    /**
     * Loads a specific calculation
     */
    suspend fun loadCalculation(id: String): SavedCalculation? {
        return try {
            calculationRepository.loadCalculation(id)
        } catch (e: Exception) {
            _errorMessage.value = e.message
            null
        }
    }
    
    // MARK: - Project Management
    
    /**
     * Saves a project
     */
    fun saveProject(project: Project) {
        viewModelScope.launch {
            try {
                projectRepository.saveProject(project)
                
                val currentProjects = _projects.value.toMutableList()
                val existingIndex = currentProjects.indexOfFirst { it.id == project.id }
                
                if (existingIndex >= 0) {
                    currentProjects[existingIndex] = project
                } else {
                    currentProjects.add(0, project)
                }
                
                _projects.value = currentProjects.sortedByDescending { it.modifiedDate }
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }
    
    /**
     * Deletes a project
     */
    fun deleteProject(project: Project) {
        viewModelScope.launch {
            try {
                projectRepository.deleteProject(project.id)
                _projects.value = _projects.value.filter { it.id != project.id }
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     * Creates a SavedCalculation from calculation inputs and results
     */
    private fun createCalculationFromInputs(
        calculationType: CalculationMode,
        inputs: Map<String, Any>,
        result: Double,
        growthPoints: List<GrowthPoint>?
    ): SavedCalculation? {
        
        return try {
            when (calculationType) {
                CalculationMode.CALCULATE_IRR -> {
                    SavedCalculation.createValidated(
                        name = "Untitled IRR Calculation",
                        calculationType = calculationType,
                        initialInvestment = inputs["Initial Investment"] as? Double,
                        outcomeAmount = inputs["Outcome Amount"] as? Double,
                        timeInMonths = inputs["Time Period (Months)"] as? Double,
                        calculatedResult = result,
                        growthPointsJson = growthPoints?.let { GrowthPoint.toJsonString(it) }
                    )
                }
                
                CalculationMode.CALCULATE_OUTCOME -> {
                    SavedCalculation.createValidated(
                        name = "Untitled Outcome Calculation",
                        calculationType = calculationType,
                        initialInvestment = inputs["Initial Investment"] as? Double,
                        irr = inputs["IRR"] as? Double,
                        timeInMonths = inputs["Time Period (Months)"] as? Double,
                        calculatedResult = result,
                        growthPointsJson = growthPoints?.let { GrowthPoint.toJsonString(it) }
                    )
                }
                
                CalculationMode.CALCULATE_INITIAL -> {
                    SavedCalculation.createValidated(
                        name = "Untitled Initial Investment Calculation",
                        calculationType = calculationType,
                        outcomeAmount = inputs["Outcome Amount"] as? Double,
                        irr = inputs["IRR"] as? Double,
                        timeInMonths = inputs["Time Period (Months)"] as? Double,
                        calculatedResult = result,
                        growthPointsJson = growthPoints?.let { GrowthPoint.toJsonString(it) }
                    )
                }
                
                CalculationMode.CALCULATE_BLENDED -> {
                    SavedCalculation.createValidated(
                        name = "Untitled Blended IRR Calculation",
                        calculationType = calculationType,
                        initialInvestment = inputs["Initial Investment"] as? Double,
                        outcomeAmount = inputs["Final Valuation"] as? Double,
                        timeInMonths = inputs["Time Period (Months)"] as? Double,
                        calculatedResult = result,
                        growthPointsJson = growthPoints?.let { GrowthPoint.toJsonString(it) }
                    )
                }
                
                CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> {
                    SavedCalculation.createValidated(
                        name = "Untitled Portfolio Unit Investment",
                        calculationType = calculationType,
                        initialInvestment = inputs["Initial Investment"] as? Double,
                        timeInMonths = inputs["Time Period (Months)"] as? Double,
                        unitPrice = inputs["Unit Price"] as? Double,
                        successRate = inputs["Success Rate (%)"] as? Double,
                        calculatedResult = result,
                        growthPointsJson = growthPoints?.let { GrowthPoint.toJsonString(it) }
                    )
                }
            }
        } catch (e: Exception) {
            println("Failed to create calculation: $e")
            null
        }
    }
    
    // MARK: - Calculation Loading and Editing
    
    /**
     * Duplicates a calculation for scenario analysis
     */
    fun duplicateCalculation(calculation: SavedCalculation) {
        viewModelScope.launch {
            try {
                val duplicatedCalculation = calculation.copy(
                    id = java.util.UUID.randomUUID().toString(),
                    name = "${calculation.name} (Copy)",
                    createdDate = LocalDateTime.now(),
                    modifiedDate = LocalDateTime.now()
                )
                
                saveCalculation(duplicatedCalculation)
            } catch (e: Exception) {
                _errorMessage.value = "Failed to duplicate calculation: ${e.message}"
            }
        }
    }
    
    /**
     * Gets calculation history (versions of the same calculation)
     */
    suspend fun getCalculationHistory(calculation: SavedCalculation): List<SavedCalculation> {
        val baseName = calculation.name
            .replace(" (Copy)", "")
            .replace(Regex(" - v\\d+"), "")
        
        return _calculations.value.filter { calc ->
            calc.id != calculation.id &&
            calc.calculationType == calculation.calculationType &&
            (calc.name.contains(baseName) || calc.name.startsWith(baseName))
        }.sortedByDescending { it.modifiedDate }
    }
    
    /**
     * Creates a new version of a calculation
     */
    fun createCalculationVersion(calculation: SavedCalculation, name: String) {
        viewModelScope.launch {
            try {
                val versionedCalculation = calculation.copy(
                    id = java.util.UUID.randomUUID().toString(),
                    name = name,
                    createdDate = LocalDateTime.now(),
                    modifiedDate = LocalDateTime.now(),
                    tags = calculation.getTagsFromJson().plus("version").let { tagsList ->
                        if (tagsList.isEmpty()) "[]" else "[" + tagsList.joinToString(",") { "\"$it\"" } + "]"
                    }
                )
                
                saveCalculation(versionedCalculation)
            } catch (e: Exception) {
                _errorMessage.value = "Failed to create calculation version: ${e.message}"
            }
        }
    }
    
    // MARK: - Configuration
    
    /**
     * Updates auto-save configuration
     */
    fun updateAutoSaveConfiguration(config: AutoSaveConfiguration) {
        _autoSaveConfiguration.value = config
        
        if (config.isEnabled) {
            startDraftSaveTimer()
        } else {
            stopDraftSaveTimer()
        }
    }
    
    // MARK: - Cleanup
    
    override fun onCleared() {
        super.onCleared()
        autoSaveJob?.cancel()
        draftSaveJob?.cancel()
    }
}

// MARK: - CalculationMode Extension
val CalculationMode.displayName: String
    get() = when (this) {
        CalculationMode.CALCULATE_IRR -> "IRR Calculation"
        CalculationMode.CALCULATE_OUTCOME -> "Outcome Calculation"
        CalculationMode.CALCULATE_INITIAL -> "Initial Investment Calculation"
        CalculationMode.CALCULATE_BLENDED -> "Blended IRR Calculation"
        CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> "Portfolio Unit Investment"
    }