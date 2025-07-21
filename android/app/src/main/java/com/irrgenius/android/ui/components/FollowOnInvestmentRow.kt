package com.irrgenius.android.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.irrgenius.android.data.models.*
import com.irrgenius.android.utils.NumberFormatter
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Composable
fun FollowOnInvestmentRow(
    investment: FollowOnInvestment,
    initialDate: LocalDate,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                // Investment Type and Amount
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = when (investment.investmentType) {
                            InvestmentType.BUY -> "Buy"
                            InvestmentType.SELL -> "Sell"
                            InvestmentType.BUY_SELL -> "Buy/Sell"
                        },
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = when (investment.investmentType) {
                            InvestmentType.BUY -> MaterialTheme.colorScheme.primary
                            InvestmentType.SELL -> MaterialTheme.colorScheme.error
                            InvestmentType.BUY_SELL -> MaterialTheme.colorScheme.secondary
                        }
                    )
                    Text(
                        text = NumberFormatter.formatCurrency(investment.amount),
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Medium
                    )
                }
                
                // Timing
                Text(
                    text = when (investment.timingType) {
                        TimingType.ABSOLUTE -> {
                            val formatter = DateTimeFormatter.ofPattern("MMM d, yyyy")
                            investment.absoluteDate.format(formatter)
                        }
                        TimingType.RELATIVE -> {
                            val timeStr = NumberFormatter.formatNumber(investment.relativeTime)
                            val unitStr = when (investment.relativeTimeUnit) {
                                TimeUnit.DAYS -> "day"
                                TimeUnit.MONTHS -> "month"
                                TimeUnit.YEARS -> "year"
                            }
                            val plural = if (investment.relativeTime != 1.0) "s" else ""
                            "$timeStr $unitStr$plural after initial"
                        }
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                // Valuation
                Text(
                    text = when (investment.valuationMode) {
                        ValuationMode.TAG_ALONG -> "Tag-along valuation"
                        ValuationMode.CUSTOM -> {
                            when (investment.valuationType) {
                                ValuationType.COMPUTED -> "Custom: ${NumberFormatter.formatCurrency(investment.customValuation)}"
                                ValuationType.SPECIFIED -> "Specified outcome"
                            }
                        }
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            IconButton(
                onClick = onDelete,
                modifier = Modifier.size(40.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = "Delete investment",
                    tint = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}