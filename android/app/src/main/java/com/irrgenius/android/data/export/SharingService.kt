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
    
    // TODO: Add PDF export service when implemented
    
    /**
     * Exports a calculation to PDF and shows Android share intent
     */
    suspend fun shareCalculationAsPDF(calculation: SavedCalculation) {
        withContext(Dispatchers.IO) {
            try {
                android.util.Log.d("SharingService", "Sharing calculation as PDF: ${calculation.name}")
                
                // For now, generate a text-based PDF content
                val pdfFile = createPDFFile(calculation)
                shareFile(
                    file = pdfFile,
                    mimeType = "application/pdf",
                    subject = "IRR Calculation: ${calculation.name}",
                    text = "Sharing IRR calculation results for ${calculation.name}"
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
                android.util.Log.d("SharingService", "Sharing ${calculations.size} calculations as PDF")
                
                val pdfFile = createMultiplePDFFile(calculations)
                shareFile(
                    file = pdfFile,
                    mimeType = "application/pdf",
                    subject = "IRR Calculations Report (${calculations.size} calculations)",
                    text = "Sharing consolidated IRR calculations report with ${calculations.size} calculations"
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
                android.util.Log.d("SharingService", "Sharing calculation as CSV: ${calculation.name}")
                
                val csvFile = exportCalculationToCSV(calculation)
                shareFile(
                    file = csvFile,
                    mimeType = "text/csv",
                    subject = "IRR Calculation Data: ${calculation.name}",
                    text = "Sharing CSV data for IRR calculation: ${calculation.name}"
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
                android.util.Log.d("SharingService", "Sharing ${calculations.size} calculations as CSV")
                
                val csvFile = exportCalculationsToCSV(calculations)
                shareFile(
                    file = csvFile,
                    mimeType = "text/csv",
                    subject = "IRR Calculations Data (${calculations.size} calculations)",
                    text = "Sharing CSV data for ${calculations.size} IRR calculations"
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
     * Creates a PDF file for a single calculation (simple text-based implementation)
     */
    private suspend fun createPDFFile(calculation: SavedCalculation): File {
        return withContext(Dispatchers.IO) {
            // For now, create a simple text file with .pdf extension
            // In production, you'd use a proper PDF library like iTextPDF
            val pdfContent = generatePDFContent(listOf(calculation))
            val filename = "${calculation.name.replace(" ", "_")}.pdf"
            val file = File(getCacheDirectory(), filename)
            file.writeText(pdfContent)
            file
        }
    }
    
    /**
     * Creates a PDF file for multiple calculations
     */
    private suspend fun createMultiplePDFFile(calculations: List<SavedCalculation>): File {
        return withContext(Dispatchers.IO) {
            val pdfContent = generatePDFContent(calculations)
            val filename = "IRR_Calculations_Report_${System.currentTimeMillis()}.pdf"
            val file = File(getCacheDirectory(), filename)
            file.writeText(pdfContent)
            file
        }
    }
    
    /**
     * Generates PDF content (simplified text-based format)
     */
    private fun generatePDFContent(calculations: List<SavedCalculation>): String {
        val content = StringBuilder()
        
        content.append("IRR GENIUS CALCULATION REPORT\n")
        content.append("=" .repeat(50) + "\n\n")
        content.append("Generated: ${java.time.LocalDateTime.now()}\n")
        content.append("Number of Calculations: ${calculations.size}\n\n")
        
        calculations.forEachIndexed { index, calculation ->
            content.append("CALCULATION ${index + 1}\n")
            content.append("-".repeat(30) + "\n")
            content.append("Name: ${calculation.name}\n")
            content.append("Type: ${calculation.calculationType.name.replace("_", " ")}\n")
            content.append("Created: ${calculation.createdDate}\n")
            content.append("Modified: ${calculation.modifiedDate}\n")
            content.append("\n")
            
            content.append("FINANCIAL DATA:\n")
            calculation.initialInvestment?.let { content.append("Initial Investment: $${String.format("%.2f", it)}\n") }
            calculation.outcomeAmount?.let { content.append("Outcome Amount: $${String.format("%.2f", it)}\n") }
            calculation.timeInMonths?.let { content.append("Time Period: ${String.format("%.1f", it)} months\n") }
            calculation.irr?.let { content.append("IRR: ${String.format("%.2f", it)}%\n") }
            calculation.unitPrice?.let { content.append("Unit Price: $${String.format("%.2f", it)}\n") }
            calculation.successRate?.let { content.append("Success Rate: ${String.format("%.1f", it)}%\n") }
            calculation.outcomePerUnit?.let { content.append("Outcome Per Unit: $${String.format("%.2f", it)}\n") }
            calculation.investorShare?.let { content.append("Investor Share: ${String.format("%.1f", it)}%\n") }
            calculation.feePercentage?.let { content.append("Fee Percentage: ${String.format("%.2f", it)}%\n") }
            calculation.calculatedResult?.let { content.append("Calculated Result: ${String.format("%.2f", it)}%\n") }
            content.append("\n")
            
            if (!calculation.notes.isNullOrBlank()) {
                content.append("NOTES:\n")
                content.append("${calculation.notes}\n\n")
            }
            
            val tags = calculation.getTagsFromJson()
            if (tags.isNotEmpty()) {
                content.append("TAGS: ${tags.joinToString(", ")}\n")
            }
            
            content.append("\n")
            content.append("=" .repeat(50) + "\n\n")
        }
        
        return content.toString()
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