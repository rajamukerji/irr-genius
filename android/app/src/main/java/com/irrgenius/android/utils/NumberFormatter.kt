package com.irrgenius.android.utils

import java.text.DecimalFormat
import java.text.NumberFormat
import java.util.Locale

object NumberFormatter {
    private val currencyFormatter = NumberFormat.getCurrencyInstance(Locale.US).apply {
        maximumFractionDigits = 0
    }
    
    private val numberFormatter = DecimalFormat("#,##0.##")
    
    private val percentFormatter = DecimalFormat("0.##%")
    
    fun formatCurrency(value: Double): String {
        return currencyFormatter.format(value)
    }
    
    fun formatNumber(value: Double): String {
        return numberFormatter.format(value)
    }
    
    fun formatPercent(value: Double): String {
        return percentFormatter.format(value)
    }
    
    fun parseDouble(text: String): Double? {
        val cleanedText = text.replace(",", "").replace("$", "").trim()
        return cleanedText.toDoubleOrNull()
    }
    
    fun formatInputText(text: String, isCurrency: Boolean = false): String {
        val cleanedText = text.replace(",", "").replace("$", "").trim()
        val number = cleanedText.toDoubleOrNull() ?: return text
        
        return if (isCurrency) {
            formatCurrency(number).replace("$", "")
        } else {
            formatNumber(number)
        }
    }
}