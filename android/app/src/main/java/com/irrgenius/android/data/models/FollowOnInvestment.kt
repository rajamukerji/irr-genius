package com.irrgenius.android.data.models

import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.util.UUID

data class FollowOnInvestment(
    val id: String = UUID.randomUUID().toString(),
    val amount: Double = 0.0,
    val investmentType: InvestmentType = InvestmentType.BUY,
    val timingType: TimingType = TimingType.ABSOLUTE,
    val absoluteDate: LocalDate = LocalDate.now(),
    val relativeTime: Double = 1.0,
    val relativeTimeUnit: TimeUnit = TimeUnit.YEARS,
    val valuationMode: ValuationMode = ValuationMode.TAG_ALONG,
    val valuationType: ValuationType = ValuationType.COMPUTED,
    val customValuation: Double = 0.0
) {
    fun getInvestmentDate(initialInvestmentDate: LocalDate): LocalDate {
        return when (timingType) {
            TimingType.ABSOLUTE -> absoluteDate
            TimingType.RELATIVE -> {
                when (relativeTimeUnit) {
                    TimeUnit.DAYS -> initialInvestmentDate.plusDays(relativeTime.toLong())
                    TimeUnit.MONTHS -> initialInvestmentDate.plusMonths(relativeTime.toLong())
                    TimeUnit.YEARS -> {
                        val days = (relativeTime * 365.25).toLong()
                        initialInvestmentDate.plusDays(days)
                    }
                }
            }
        }
    }
    
    fun getYearsFromInitial(initialInvestmentDate: LocalDate): Double {
        val investmentDate = getInvestmentDate(initialInvestmentDate)
        val days = ChronoUnit.DAYS.between(initialInvestmentDate, investmentDate)
        return days / 365.25
    }
}