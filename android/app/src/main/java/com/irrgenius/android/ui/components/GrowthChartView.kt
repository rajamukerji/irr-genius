package com.irrgenius.android.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.irrgenius.android.data.models.GrowthPoint
import com.patrykandpatrick.vico.compose.axis.horizontal.rememberBottomAxis
import com.patrykandpatrick.vico.compose.axis.vertical.rememberStartAxis
import com.patrykandpatrick.vico.compose.chart.Chart
import com.patrykandpatrick.vico.compose.chart.line.lineChart
import com.patrykandpatrick.vico.compose.style.ProvideChartStyle
import com.patrykandpatrick.vico.core.axis.AxisPosition
import com.patrykandpatrick.vico.core.axis.formatter.AxisValueFormatter
import com.patrykandpatrick.vico.core.chart.line.LineChart
import com.patrykandpatrick.vico.core.entry.ChartEntryModelProducer
import com.patrykandpatrick.vico.core.entry.FloatEntry
import java.text.DecimalFormat

@Composable
fun GrowthChartView(
    growthPoints: List<GrowthPoint>,
    modifier: Modifier = Modifier,
    showFollowOnMarkers: Boolean = false
) {
    if (growthPoints.isEmpty()) {
        Card(
            modifier = modifier
                .fillMaxWidth()
                .height(300.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = androidx.compose.ui.Alignment.Center
            ) {
                Text(
                    text = "Calculate to see growth chart",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        return
    }

    val chartEntryModel = remember(growthPoints) {
        ChartEntryModelProducer(
            growthPoints.map { point ->
                FloatEntry(point.month, point.value)
            }
        ).getModel()
    }

    val currencyFormatter = remember { DecimalFormat("$#,##0") }
    val yearFormatter = remember { DecimalFormat("0.#") }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .height(300.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            Text(
                text = "Investment Growth",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(bottom = 8.dp)
            )

            ProvideChartStyle(
                chartStyle = androidx.compose.material3.LocalContentColor.current.let { color ->
                    remember {
                        com.patrykandpatrick.vico.compose.style.ChartStyle(
                            axis = com.patrykandpatrick.vico.compose.style.ChartStyle.Axis(
                                axisLabelColor = color,
                                axisLineColor = color,
                                axisTickColor = color,
                                axisGuidelineColor = color.copy(alpha = 0.1f)
                            ),
                            columnChart = com.patrykandpatrick.vico.compose.style.ChartStyle.ColumnChart(
                                columns = emptyList()
                            ),
                            lineChart = com.patrykandpatrick.vico.compose.style.ChartStyle.LineChart(
                                lines = listOf(
                                    com.patrykandpatrick.vico.compose.style.ChartStyle.LineChart.LineStyle(
                                        lineColor = Color(0xFF4A90E2),
                                        lineBackgroundShader = null
                                    )
                                )
                            ),
                            marker = com.patrykandpatrick.vico.compose.style.ChartStyle.Marker(),
                            elevationOverlayColor = color
                        )
                    }
                }
            ) {
                Chart(
                    chart = lineChart(),
                    model = chartEntryModel,
                    startAxis = rememberStartAxis(
                        valueFormatter = AxisValueFormatter { value, _ ->
                            currencyFormatter.format(value)
                        },
                        guideline = null
                    ),
                    bottomAxis = rememberBottomAxis(
                        valueFormatter = AxisValueFormatter { value, _ ->
                            val years = value / 12f
                            "${yearFormatter.format(years)} yr"
                        },
                        guideline = null
                    ),
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }
}