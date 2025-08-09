package com.irrgenius.android.ui.screens

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.*
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.irrgenius.android.data.import.*
import com.irrgenius.android.data.models.CalculationMode
import kotlinx.coroutines.launch

class ImportDataViewModel : ViewModel() {
    
    // UI State
    var isProcessing by mutableStateOf(false)
        private set
    
    var errorMessage by mutableStateOf<String?>(null)
        private set
    
    var selectedCalculationType by mutableStateOf(CalculationMode.CALCULATE_IRR)
        private set
    
    private var _fileType by mutableStateOf<ImportFileType?>(null)
    val fileType: ImportFileType? get() = _fileType
    
    var importResult by mutableStateOf<ImportResultWithMapping?>(null)
        private set
    
    var columnMapping by mutableStateOf<Map<String, CalculationField>>(emptyMap())
        private set
    
    var validationResult by mutableStateOf<ValidationResult?>(null)
        private set
    
    // Services
    private val csvImportService = CSVImportService()
    private val excelImportService = ExcelImportService()
    
    fun setFileType(type: ImportFileType) {
        _fileType = type
        clearError()
    }
    
    fun setCalculationType(type: CalculationMode) {
        selectedCalculationType = type
    }
    
    fun setError(message: String) {
        errorMessage = message
        isProcessing = false
    }
    
    fun clearError() {
        errorMessage = null
    }
    
    suspend fun processFile(context: Context, uri: Uri) {
        isProcessing = true
        clearError()
        
        try {
            val inputStream = context.contentResolver.openInputStream(uri)
                ?: throw Exception("Could not open file")
            
            val fileName = getFileName(context, uri)
            
            val result = when (fileType) {
                ImportFileType.CSV -> {
                    csvImportService.importCSV(inputStream)
                }
                ImportFileType.EXCEL -> {
                    excelImportService.importExcel(inputStream, fileName)
                }
                null -> throw Exception("File type not selected")
            }
            
            importResult = result
            columnMapping = result.suggestedMapping
            
        } catch (e: Exception) {
            setError("Failed to process file: ${e.message}")
        } finally {
            isProcessing = false
        }
    }
    
    fun updateColumnMapping(columnName: String, field: CalculationField?) {
        columnMapping = if (field != null) {
            columnMapping + (columnName to field)
        } else {
            columnMapping - columnName
        }
    }
    
    suspend fun validateData() {
        val result = importResult ?: return
        
        isProcessing = true
        clearError()
        
        try {
            val validation = when (fileType) {
                ImportFileType.CSV -> {
                    csvImportService.validateAndConvert(
                        importResult = result,
                        columnMapping = columnMapping,
                        calculationType = selectedCalculationType
                    )
                }
                ImportFileType.EXCEL -> {
                    excelImportService.validateAndConvert(
                        importResult = result,
                        columnMapping = columnMapping,
                        calculationType = selectedCalculationType
                    )
                }
                null -> throw Exception("File type not selected")
            }
            
            validationResult = validation
            
        } catch (e: Exception) {
            setError("Validation failed: ${e.message}")
        } finally {
            isProcessing = false
        }
    }
    
    private fun getFileName(context: Context, uri: Uri): String {
        var fileName = "unknown"
        
        context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
            if (nameIndex != -1 && cursor.moveToFirst()) {
                fileName = cursor.getString(nameIndex) ?: "unknown"
            }
        }
        
        return fileName
    }
    
    fun reset() {
        isProcessing = false
        errorMessage = null
        _fileType = null
        importResult = null
        columnMapping = emptyMap()
        validationResult = null
    }
}