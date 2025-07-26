package com.irrgenius.android.data.export

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import com.irrgenius.android.data.models.SavedCalculation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/**
 * Service for handling file sharing and export operations on Android
 */
class SharingService(private val context: Context) {
    
    private val pdfExportService = PDFExportServiceImpl(context)
    
    /**
     * Exports a calculation to PDF and shows Android share intent
     */
    suspend fun shareCalculationAsPDF(calculation: SavedCalculation) {
        withContext(Dispatchers.IO) {
            try {
                // Export to PDF
                val pdfFile = pdfExportService.exportToPDF(calculation)
                
                // Share the file
                shareFile(
                    file = pdfFile,
                    mimeType = "application/pdf",
                    subject = "IRR Calculation: ${calculation.name}",
                    text = "Please find attached the IRR calculation report for ${calculation.name}."
                )
                
            } catch (e: Exception) {
                throw SharingException("Failed to share calculation: ${e.message}", e)
            }
        }
    }
    
    /**
     * Exports multiple calculations to PDF and shows Android share intent
     */
    suspend fun shareMultipleCalculationsAsPDF(calculations: List<SavedCalculation>) {
        withContext(Dispatchers.IO) {
            try {
                // Export to PDF
                val pdfFile = pdfExportService.exportMultipleCalculationsToPDF(calculations)
                
                // Share the file
                shareFile(
                    file = pdfFile,
                    mimeType = "application/pdf",
                    subject = "IRR Calculations Export",
                    text = "Please find attached the IRR calculations report containing ${calculations.size} calculations."
                )
                
            } catch (e: Exception) {
                throw SharingException("Failed to share calculations: ${e.message}", e)
            }
        }
    }
    
    /**
     * Exports a calculation to CSV and shows Android share intent
     */
    suspend fun shareCalculationAsCSV(calculation: SavedCalculation) {
        withContext(Dispatchers.IO) {
            try {
                // Export to CSV
                val csvFile = exportCalculationToCSV(calculation)
                
                // Share the file
                shareFile(
                    file = csvFile,
                    mimeType = "text/csv",
                    subject = "IRR Calculation Data: ${calculation.name}",
                    text = "Please find attached the IRR calculation data for ${calculation.name}."
                )
                
            } catch (e: Exception) {
                throw SharingException("Failed to share calculation as CSV: ${e.message}", e)
            }
        }
    }
    
    /**
     * Exports multiple calculations to CSV and shows Android share intent
     */
    suspend fun shareMultipleCalculationsAsCSV(calculations: List<SavedCalculation>) {
        withContext(Dispatchers.IO) {
            try {
                // Export to CSV
                val csvFile = exportCalculationsToCSV(calculations)
                
                // Share the file
                shareFile(
                    file = csvFile,
                    mimeType = "text/csv",
                    subject = "IRR Calculations Data Export",
                    text = "Please find attached the IRR calculations data containing ${calculations.size} calculations."
                )
                
            } catch (e: Exception) {
                throw SharingException("Failed to share calculations as CSV: ${e.message}", e)
            }
        }
    }
    
    /**
     * Shares a file using Android's share intent
     */
    private fun shareFile(
        file: File,
        mimeType: String,
        subject: String,
        text: String
    ) {
        try {
            // Get URI for the file using FileProvider
            val fileUri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )
            
            // Create share intent
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, fileUri)
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            
            // Create chooser
            val chooserIntent = Intent.createChooser(shareIntent, "Share calculation")
            chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            // Start the share activity
            context.startActivity(chooserIntent)
            
        } catch (e: Exception) {
            throw SharingException("Failed to create share intent: ${e.message}", e)
        }
    }
    
    /**
     * Shares multiple files using Android's share intent
     */
    private fun shareMultipleFiles(
        files: List<File>,
        mimeType: String,
        subject: String,
        text: String
    ) {
        try {
            // Get URIs for all files
            val fileUris = files.map { file ->
                FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    file
                )
            }
            
            // Create share intent for multiple files
            val shareIntent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = mimeType
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(fileUris))
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            
            // Create chooser
            val chooserIntent = Intent.createChooser(shareIntent, "Share calculations")
            chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            // Start the share activity
            context.startActivity(chooserIntent)
            
        } catch (e: Exception) {
            throw SharingException("Failed to create share intent for multiple files: ${e.message}", e)
        }
    }
    
    /**
     * Cleans up temporary files after sharing
     */
    suspend fun cleanupTemporaryFiles(files: List<File>) {
        withContext(Dispatchers.IO) {
            files.forEach { file ->
                try {
                    if (file.exists()) {
                        file.delete()
                    }
                } catch (e: Exception) {
                    // Log error but don't throw - cleanup failures shouldn't break the app
                    println("Failed to cleanup temporary file: ${file.name}, error: ${e.message}")
                }
            }
        }
    }
    
    /**
     * Exports a single calculation to CSV file
     */
    private suspend fun exportCalculationToCSV(calculation: SavedCalculation): File {
        return withContext(Dispatchers.IO) {
            val csvContent = generateCSVContent(listOf(calculation))
            val filename = "${calculation.name.replace(" ", "_")}.csv"
            val file = File(getCacheDirectory(), filename)
            file.writeText(csvContent)
            file
        }
    }
    
    /**
     * Exports multiple calculations to CSV file
     */
    private suspend fun exportCalculationsToCSV(calculations: List<SavedCalculation>): File {
        return withContext(Dispatchers.IO) {
            val csvContent = generateCSVContent(calculations)
            val filename = "IRR_Calculations_${System.currentTimeMillis()}.csv"
            val file = File(getCacheDirectory(), filename)
            file.writeText(csvContent)
            file
        }
    }
    
    /**
     * Generates CSV content from calculations
     */
    private fun generateCSVContent(calculations: List<SavedCalculation>): String {
        val csvLines = mutableListOf<String>()
        
        // Header row
        val headers = listOf(
            "Name",
            "Type",
            "Created Date",
            "Modified Date",
            "Initial Investment",
            "Outcome Amount",
            "Time (Months)",
            "IRR (%)",
            "Unit Price",
            "Success Rate (%)",
            "Outcome Per Unit",
            "Investor Share (%)",
            "Fee Percentage (%)",
            "Calculated Result",
            "Project ID",
            "Notes",
            "Tags"
        )
        
        csvLines.add(headers.joinToString(","))
        
        // Data rows
        for (calculation in calculations) {
            val row = listOf(
                escapeCSVField(calculation.name),
                escapeCSVField(calculation.calculationType.name.replace("_", " ")),
                escapeCSVField(calculation.createdDate.toString()),
                escapeCSVField(calculation.modifiedDate.toString()),
                formatOptionalDouble(calculation.initialInvestment),
                formatOptionalDouble(calculation.outcomeAmount),
                formatOptionalDouble(calculation.timeInMonths),
                formatOptionalDouble(calculation.irr),
                formatOptionalDouble(calculation.unitPrice),
                formatOptionalDouble(calculation.successRate),
                formatOptionalDouble(calculation.outcomePerUnit),
                formatOptionalDouble(calculation.investorShare),
                formatOptionalDouble(calculation.feePercentage),
                formatOptionalDouble(calculation.calculatedResult),
                escapeCSVField(calculation.projectId ?: ""),
                escapeCSVField(calculation.notes ?: ""),
                escapeCSVField(calculation.getTagsFromJson().joinToString(";"))
            )
            
            csvLines.add(row.joinToString(","))
        }
        
        return csvLines.joinToString("\n")
    }
    
    /**
     * Escapes CSV field content
     */
    private fun escapeCSVField(field: String): String {
        val needsEscaping = field.contains(",") || field.contains("\"") || field.contains("\n")
        
        return if (needsEscaping) {
            val escapedField = field.replace("\"", "\"\"")
            "\"$escapedField\""
        } else {
            field
        }
    }
    
    /**
     * Formats optional double values for CSV
     */
    private fun formatOptionalDouble(value: Double?): String {
        return value?.let { String.format("%.2f", it) } ?: ""
    }
    
    /**
     * Gets the cache directory for temporary export files
     */
    fun getCacheDirectory(): File {
        val cacheDir = File(context.cacheDir, "exports")
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }
        return cacheDir
    }
    
    /**
     * Checks if external storage is available for writing
     */
    fun isExternalStorageWritable(): Boolean {
        return android.os.Environment.getExternalStorageState() == android.os.Environment.MEDIA_MOUNTED
    }
}

/**
 * Exception thrown when sharing operations fail
 */
class SharingException(message: String, cause: Throwable? = null) : Exception(message, cause)