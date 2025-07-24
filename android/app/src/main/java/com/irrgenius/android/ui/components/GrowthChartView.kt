package com.irrgenius.android.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.irrgenius.android.data.models.GrowthPoint
import com.irrgenius.android.utils.NumberFormatter
import kotlin.math.max
import kotlin.math.min

@Composable
fun GrowthChartView(
    growthPoints: List<GrowthPoint>,
    modifier: Modifier = Modifier,
    showFollowOnMarkers: Boolean = false
) {
    if (growthPoints.isEmpty()) {
        Card(
            modifier = modifier.fillMaxWidth(),
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(250.dp)
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Calculate to see growth chart",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
        return
    }
    
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Growth Chart",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(250.dp)
            ) {
                SimpleLineChart(
                    points = growthPoints,
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }
}

@Composable
private fun SimpleLineChart(
    points: List<GrowthPoint>,
    modifier: Modifier = Modifier
) {
    val lineColor = Color(0xFF4A90E2)
    val gridColor = Color.Gray.copy(alpha = 0.3f)
    
    Canvas(modifier = modifier) {
        if (points.isEmpty()) return@Canvas
        
        val padding = 40f
        val width = size.width - 2 * padding
        val height = size.height - 2 * padding
        
        // Find min/max values
        val minX = points.minOf { it.month }.toFloat()
        val maxX = points.maxOf { it.month }.toFloat()
        val minY = points.minOf { it.value }.toFloat()
        val maxY = points.maxOf { it.value }.toFloat()
        
        val xRange = maxX - minX
        val yRange = maxY - minY
        
        if (xRange == 0f || yRange == 0f) return@Canvas
        
        // Draw grid lines
        drawGrid(padding, width, height, gridColor)
        
        // Create path for line
        val path = Path()
        points.forEachIndexed { index, point ->
            val x = padding + ((point.month.toFloat() - minX) / xRange) * width
            val y = padding + height - ((point.value.toFloat() - minY) / yRange) * height
            
            if (index == 0) {
                path.moveTo(x, y)
            } else {
                path.lineTo(x, y)
            }
        }
        
        // Draw the line
        drawPath(
            path = path,
            color = lineColor,
            style = Stroke(width = 3.dp.toPx())
        )
        
        // Draw points
        points.forEach { point ->
            val x = padding + ((point.month.toFloat() - minX) / xRange) * width
            val y = padding + height - ((point.value.toFloat() - minY) / yRange) * height
            
            drawCircle(
                color = lineColor,
                radius = 4.dp.toPx(),
                center = Offset(x, y)
            )
        }
    }
}

private fun DrawScope.drawGrid(
    padding: Float,
    width: Float,
    height: Float,
    color: Color
) {
    // Vertical grid lines
    for (i in 0..4) {
        val x = padding + (i * width / 4)
        drawLine(
            color = color,
            start = Offset(x, padding),
            end = Offset(x, padding + height),
            strokeWidth = 1.dp.toPx()
        )
    }
    
    // Horizontal grid lines
    for (i in 0..4) {
        val y = padding + (i * height / 4)
        drawLine(
            color = color,
            start = Offset(padding, y),
            end = Offset(padding + width, y),
            strokeWidth = 1.dp.toPx()
        )
    }
}