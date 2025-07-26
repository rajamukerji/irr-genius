package com.irrgenius.android.data.export

import android.content.Context
import android.graphics.*
import android.graphics.pdf.PdfDocument
import com.irrgenius.android.data.models.CalculationMode
import com.irrgenius.android.data.models.FollowOnInvestment
import com.irrgenius.android.data.models.GrowthPoint
import com.irrgenius.android.data.models.SavedCalculation
import com.irrgenius.android.utils.NumberFormatter
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.max
import kotlin.math.min

// PDF Export Service Interface
interface PDFExportService {
    suspend fun exportToPDF(calculation: SavedCalculation): File
    suspend fun exportMultipleCalculationsToPDF(calculations: List<SavedCalculation>): File
}

// PDF Export Exceptions
class PDFExportException(message: String, cause: Throwable? = null) : Exception(message, cause)

// PDF Export Service Implementation
class PDFExportServiceImpl(private val context: Context) : PDFExportService {
    
    companion object {
        private const val PAGE_WIDTH = 612 // US Letter width in points
        private const val PAGE_HEIGHT = 792 // US Letter height in points
        private const val MARGIN = 50f
        private const val LINE_HEIGHT = 20f
        private const val CHART_HEIGHT = 200f
    }
    
    // Paint objects for different text styles
    private val titlePaint = Paint().apply {
        textSize = 24f
        color = Color.BLACK
        typeface = Typeface.DEFAULT_BOLD
        isAntiAlias = true
    }
    
    private val headerPaint = Paint().apply {
        textSize = 18f
        color = Color.BLACK
        typeface = Typeface.DEFAULT_BOLD
        isAntiAlias = true
    }
    
    private val subHeaderPaint = Paint().apply {
        textSize = 16f
        color = Color.BLACK
        typeface = Typeface.DEFAULT_BOLD
        isAntiAlias = true
    }
    
    private val bodyPaint = Paint().apply {
        textSize = 12f
        color = Color.BLACK
        typeface = Typeface.DEFAULT
        isAntiAlias = true
    }
    
    private val smallPaint = Paint().apply {
        textSize = 10f
        color = Color.GRAY
        typeface = Typeface.DEFAULT
        isAntiAlias = true
    }
    
    private val bluePaint = Paint().apply {
        textSize = 14f
        color = Color.parseColor("#4A90E2")
        typeface = Typeface.DEFAULT_BOLD
        isAntiAlias = true
    }
    
    private val linePaint = Paint().apply {
        color = Color.LTGRAY
        strokeWidth = 1f
        style = Paint.Style.STROKE
        isAntiAlias = true
    }
    
    private val chartLinePaint = Paint().apply {
        color = Color.parseColor("#4A90E2")
        strokeWidth = 3f
        style = Paint.Style.STROKE
        isAntiAlias = true
    }
    
    private val chartPointPaint = Paint().apply {
        color = Color.parseColor("#4A90E2")
        style = Paint.Style.FILL
        isAntiAlias = true
    }
    
    override suspend fun exportToPDF(calculation: SavedCalculation): File {
        return generatePDF(listOf(calculation), calculation.name)
    }
    
    override suspend fun exportMultipleCalculationsToPDF(calculations: List<SavedCalculation>): File {
        val filename = "IRR_Calculations_${SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault()).format(Date())}"
        return generatePDF(calculations, filename)
    }
    
    private suspend fun generatePDF(calculations: List<SavedCalculation>, filename: String): File {
        val document = PdfDocument()
        
        try {
            calculations.forEachIndexed { index, calculation ->
                val pageInfo = PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, index + 1).create()
                val page = document.startPage(pageInfo)
                val canvas = page.canvas
                
                drawCalculationPage(canvas, calculation)
                
                document.finishPage(page)
            }
            
            // Save to file
            val file = File(context.cacheDir, "$filename.pdf")
            val outputStream = FileOutputStream(file)
            document.writeTo(outputStream)
            outputStream.close()
            
            return file
            
        } catch (e: IOException) {
            throw PDFExportException("Failed to generate PDF", e)
        } finally {
            document.close()
        }
    }
    
    private fun drawCalculationPage(canvas: Canvas, calculation: SavedCalculation) {
        var currentY = MARGIN
        val contentWidth = PAGE_WIDTH - 2 * MARGIN
        
        // Draw header
        currentY = drawHeader(canvas, calculation, currentY, contentWidth)
        currentY += 20f
        
        // Draw calculation details
        currentY = drawCalculationDetails(canvas, calculation, currentY, contentWidth)
        currentY += 20f
        
        // Draw results
        currentY = drawResults(canvas, calculation, currentY, contentWidth)
        currentY += 20f
        
        // Draw chart if available
        val growthPoints = calculation.getGrowthPoints()
        if (growthPoints.isNotEmpty()) {
            currentY = drawChart(canvas, growthPoints, currentY, contentWidth)
            currentY += 20f
        }
        
        // Draw follow-on investments if available (for blended IRR)
        if (calculation.calculationType == CalculationMode.CALCULATE_BLENDED) {
            // Note: Follow-on investments would be retrieved from a separate table/service
            // For now, we'll add a placeholder
            currentY = drawFollowOnInvestmentsPlaceholder(canvas, currentY, contentWidth)
        }
        
        // Draw footer
        drawFooter(canvas, contentWidth)
    }
    
    private fun drawHeader(canvas: Canvas, calculation: SavedCalculation, startY: Float, contentWidth: Float): Float {
        var currentY = startY
        
        // App title
        canvas.drawText("IRR Genius", MARGIN, currentY, titlePaint.apply { color = Color.parseColor("#4A90E2") })
        currentY += 30f
        
        // Calculation name
        canvas.drawText(calculation.name, MARGIN, currentY, headerPaint)
        currentY += 25f
        
        // Calculation type
        val typeText = "Type: ${calculation.calculationType.displayName}"
        canvas.drawText(typeText, MARGIN, currentY, bodyPaint.apply { color = Color.DKGRAY })
        currentY += 20f
        
        // Date
        val dateText = "Generated: ${SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault()).format(Date())}"
        canvas.drawText(dateText, MARGIN, currentY, smallPaint)
        currentY += 20f
        
        // Draw separator line
        canvas.drawLine(MARGIN, currentY, MARGIN + contentWidth, currentY, linePaint)
        
        return currentY + 10f
    }
    
    private fun drawCalculationDetails(canvas: Canvas, calculation: SavedCalculation, startY: Float, contentWidth: Float): Float {
        var currentY = startY
        
        // Section title
        canvas.drawText("Calculation Details", MARGIN, currentY, subHeaderPaint)
        currentY += 25f
        
        // Input parameters based on calculation type
        val details = getCalculationDetails(calculation)
        details.forEach { detail ->
            canvas.drawText("• $detail", MARGIN + 10f, currentY, bodyPaint)
            currentY += LINE_HEIGHT
        }
        
        // Notes if available
        if (!calculation.notes.isNullOrEmpty()) {
            currentY += 10f
            canvas.drawText("Notes:", MARGIN, currentY, bodyPaint.apply { typeface = Typeface.DEFAULT_BOLD })
            currentY += LINE_HEIGHT
            
            // Handle multi-line notes
            val noteLines = wrapText(calculation.notes, contentWidth - 20f, bodyPaint)
            noteLines.forEach { line ->
                canvas.drawText(line, MARGIN, currentY, bodyPaint.apply { 
                    typeface = Typeface.DEFAULT
                    color = Color.DKGRAY 
                })
                currentY += LINE_HEIGHT
            }
        }
        
        return currentY + 10f
    }
    
    private fun drawResults(canvas: Canvas, calculation: SavedCalculation, startY: Float, contentWidth: Float): Float {
        var currentY = startY
        
        // Section title
        canvas.drawText("Results", MARGIN, currentY, subHeaderPaint)
        currentY += 25f
        
        // Main result
        calculation.calculatedResult?.let { result ->
            val resultText = getResultText(calculation, result)
            canvas.drawText(resultText, MARGIN, currentY, bluePaint)
            currentY += 25f
        }
        
        // Summary
        val summaryText = calculation.summary
        canvas.drawText(summaryText, MARGIN, currentY, bodyPaint.apply { color = Color.DKGRAY })
        
        return currentY + 20f
    }
    
    private fun drawChart(canvas: Canvas, growthPoints: List<GrowthPoint>, startY: Float, contentWidth: Float): Float {
        var currentY = startY
        
        // Section title
        canvas.drawText("Growth Chart", MARGIN, currentY, subHeaderPaint)
        currentY += 25f
        
        val chartRect = RectF(MARGIN, currentY, MARGIN + contentWidth, currentY + CHART_HEIGHT)
        
        // Draw chart background
        canvas.drawRect(chartRect, Paint().apply { 
            color = Color.parseColor("#F5F5F5")
            style = Paint.Style.FILL 
        })
        
        // Draw chart border
        canvas.drawRect(chartRect, linePaint)
        
        // Draw chart content
        drawChartContent(canvas, growthPoints, chartRect)
        
        return currentY + CHART_HEIGHT + 10f
    }
    
    private fun drawChartContent(canvas: Canvas, growthPoints: List<GrowthPoint>, rect: RectF) {
        if (growthPoints.isEmpty()) return
        
        val padding = 20f
        val chartArea = RectF(
            rect.left + padding,
            rect.top + padding,
            rect.right - padding,
            rect.bottom - padding
        )
        
        // Find min/max values
        val minMonth = growthPoints.minOf { it.month }
        val maxMonth = growthPoints.maxOf { it.month }
        val minValue = growthPoints.minOf { it.value }
        val maxValue = growthPoints.maxOf { it.value }
        
        val monthRange = maxMonth - minMonth
        val valueRange = maxValue - minValue
        
        if (monthRange <= 0 || valueRange <= 0) return
        
        // Draw grid lines
        val gridPaint = Paint().apply {
            color = Color.LTGRAY
            strokeWidth = 0.5f
            style = Paint.Style.STROKE
        }
        
        // Vertical grid lines
        for (i in 0..4) {
            val x = chartArea.left + (i / 4f) * chartArea.width()
            canvas.drawLine(x, chartArea.top, x, chartArea.bottom, gridPaint)
        }
        
        // Horizontal grid lines
        for (i in 0..4) {
            val y = chartArea.top + (i / 4f) * chartArea.height()
            canvas.drawLine(chartArea.left, y, chartArea.right, y, gridPaint)
        }
        
        // Draw data line
        val path = Path()
        growthPoints.forEachIndexed { index, point ->
            val x = chartArea.left + ((point.month - minMonth).toFloat() / monthRange) * chartArea.width()
            val y = chartArea.bottom - ((point.value - minValue).toFloat() / valueRange) * chartArea.height()
            
            if (index == 0) {
                path.moveTo(x, y)
            } else {
                path.lineTo(x, y)
            }
        }
        
        canvas.drawPath(path, chartLinePaint)
        
        // Draw data points
        growthPoints.forEach { point ->
            val x = chartArea.left + ((point.month - minMonth).toFloat() / monthRange) * chartArea.width()
            val y = chartArea.bottom - ((point.value - minValue).toFloat() / valueRange) * chartArea.height()
            
            canvas.drawCircle(x, y, 4f, chartPointPaint)
        }
        
        // Draw axis labels
        drawChartLabels(canvas, minMonth, maxMonth, minValue, maxValue, chartArea)
    }
    
    private fun drawChartLabels(canvas: Canvas, minMonth: Int, maxMonth: Int, minValue: Double, maxValue: Double, chartArea: RectF) {
        val labelPaint = Paint().apply {
            textSize = 10f
            color = Color.DKGRAY
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        
        // X-axis labels (months)
        for (i in 0..4) {
            val month = minMonth + ((i / 4.0) * (maxMonth - minMonth)).toInt()
            val x = chartArea.left + (i / 4f) * chartArea.width()
            val y = chartArea.bottom + 15f
            
            canvas.drawText("${month}m", x, y, labelPaint)
        }
        
        // Y-axis labels (values)
        labelPaint.textAlign = Paint.Align.RIGHT
        for (i in 0..4) {
            val value = minValue + (i / 4.0) * (maxValue - minValue)
            val x = chartArea.left - 5f
            val y = chartArea.bottom - (i / 4f) * chartArea.height() + 5f
            
            val text = NumberFormatter.formatCurrency(value)
            canvas.drawText(text, x, y, labelPaint)
        }
    }
    
    private fun drawFollowOnInvestmentsPlaceholder(canvas: Canvas, startY: Float, contentWidth: Float): Float {
        var currentY = startY
        
        // Section title
        canvas.drawText("Follow-On Investments", MARGIN, currentY, subHeaderPaint)
        currentY += 25f
        
        // Placeholder text
        canvas.drawText("Follow-on investment details would be displayed here", MARGIN + 10f, currentY, bodyPaint.apply { color = Color.DKGRAY })
        
        return currentY + 20f
    }
    
    private fun drawFooter(canvas: Canvas, contentWidth: Float) {
        val footerY = PAGE_HEIGHT - MARGIN
        
        // Draw separator line
        canvas.drawLine(MARGIN, footerY - 30f, MARGIN + contentWidth, footerY - 30f, linePaint)
        
        // Footer text
        val footerText = "Generated by IRR Genius - Professional IRR Calculator"
        val footerPaint = Paint().apply {
            textSize = 10f
            color = Color.DKGRAY
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        
        canvas.drawText(footerText, MARGIN + contentWidth / 2, footerY - 10f, footerPaint)
    }
    
    private fun getCalculationDetails(calculation: SavedCalculation): List<String> {
        val details = mutableListOf<String>()
        
        when (calculation.calculationType) {
            CalculationMode.CALCULATE_IRR -> {
                calculation.initialInvestment?.let { initial ->
                    details.add("Initial Investment: ${NumberFormatter.formatCurrency(initial)}")
                }
                calculation.outcomeAmount?.let { outcome ->
                    details.add("Outcome Amount: ${NumberFormatter.formatCurrency(outcome)}")
                }
                calculation.timeInMonths?.let { time ->
                    details.add("Time Period: ${time.toInt()} months")
                }
            }
            
            CalculationMode.CALCULATE_OUTCOME -> {
                calculation.initialInvestment?.let { initial ->
                    details.add("Initial Investment: ${NumberFormatter.formatCurrency(initial)}")
                }
                calculation.irr?.let { irr ->
                    details.add("Target IRR: ${String.format("%.2f", irr)}%")
                }
                calculation.timeInMonths?.let { time ->
                    details.add("Time Period: ${time.toInt()} months")
                }
            }
            
            CalculationMode.CALCULATE_INITIAL -> {
                calculation.outcomeAmount?.let { outcome ->
                    details.add("Target Outcome: ${NumberFormatter.formatCurrency(outcome)}")
                }
                calculation.irr?.let { irr ->
                    details.add("Target IRR: ${String.format("%.2f", irr)}%")
                }
                calculation.timeInMonths?.let { time ->
                    details.add("Time Period: ${time.toInt()} months")
                }
            }
            
            CalculationMode.CALCULATE_BLENDED -> {
                calculation.initialInvestment?.let { initial ->
                    details.add("Initial Investment: ${NumberFormatter.formatCurrency(initial)}")
                }
                calculation.outcomeAmount?.let { outcome ->
                    details.add("Final Outcome: ${NumberFormatter.formatCurrency(outcome)}")
                }
                calculation.timeInMonths?.let { time ->
                    details.add("Time Period: ${time.toInt()} months")
                }
                details.add("Includes follow-on investments")
            }
            
            CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> {
                calculation.initialInvestment?.let { initial ->
                    details.add("Investment Amount: ${NumberFormatter.formatCurrency(initial)}")
                }
                calculation.unitPrice?.let { unitPrice ->
                    details.add("Unit Price: ${NumberFormatter.formatCurrency(unitPrice)}")
                }
                calculation.successRate?.let { successRate ->
                    details.add("Success Rate: ${String.format("%.1f", successRate)}%")
                }
                calculation.outcomePerUnit?.let { outcomePerUnit ->
                    details.add("Outcome Per Unit: ${NumberFormatter.formatCurrency(outcomePerUnit)}")
                }
                calculation.investorShare?.let { investorShare ->
                    details.add("Investor Share: ${String.format("%.1f", investorShare)}%")
                }
                calculation.timeInMonths?.let { time ->
                    details.add("Time Period: ${time.toInt()} months")
                }
            }
        }
        
        return details
    }
    
    private fun getResultText(calculation: SavedCalculation, result: Double): String {
        return when (calculation.calculationType) {
            CalculationMode.CALCULATE_IRR, CalculationMode.CALCULATE_BLENDED, CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> {
                "IRR: ${String.format("%.2f", result)}%"
            }
            CalculationMode.CALCULATE_OUTCOME -> {
                "Outcome: ${NumberFormatter.formatCurrency(result)}"
            }
            CalculationMode.CALCULATE_INITIAL -> {
                "Initial Investment: ${NumberFormatter.formatCurrency(result)}"
            }
        }
    }
    
    private fun wrapText(text: String, maxWidth: Float, paint: Paint): List<String> {
        val words = text.split(" ")
        val lines = mutableListOf<String>()
        var currentLine = ""
        
        for (word in words) {
            val testLine = if (currentLine.isEmpty()) word else "$currentLine $word"
            val textWidth = paint.measureText(testLine)
            
            if (textWidth <= maxWidth) {
                currentLine = testLine
            } else {
                if (currentLine.isNotEmpty()) {
                    lines.add(currentLine)
                    currentLine = word
                } else {
                    lines.add(word) // Word is too long, add it anyway
                }
            }
        }
        
        if (currentLine.isNotEmpty()) {
            lines.add(currentLine)
        }
        
        return lines
    }
}

// Extension for CalculationMode display names
val CalculationMode.displayName: String
    get() = when (this) {
        CalculationMode.CALCULATE_IRR -> "Calculate IRR"
        CalculationMode.CALCULATE_OUTCOME -> "Calculate Outcome"
        CalculationMode.CALCULATE_INITIAL -> "Calculate Initial Investment"
        CalculationMode.CALCULATE_BLENDED -> "Calculate Blended IRR"
        CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> "Portfolio Unit Investment"
    }