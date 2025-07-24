package com.irrgenius.android.data.models

import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.util.UUID

// Validation exception for FollowOnInvestment
class FollowOnInvestmentValidationException(message: String) : Exception(message)

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
    val customValuation: Double = 0.0,
    val irr: Double = 0.0 // Used for computed valuation
) {
    
    companion object {
        /**
         * Creates a validated FollowOnInvestment instance
         */
        @Throws(FollowOnInvestmentValidationException::class)
        fun createValidated(
            id: String = UUID.randomUUID().toString(),
            amount: Double,
            investmentType: InvestmentType = InvestmentType.BUY,
            timingType: TimingType = TimingType.ABSOLUTE,
            absoluteDate: LocalDate = LocalDate.now(),
            relativeTime: Double = 1.0,
            relativeTimeUnit: TimeUnit = TimeUnit.YEARS,
            valuationMode: ValuationMode = ValuationMode.TAG_ALONG,
            valuationType: ValuationType = ValuationType.COMPUTED,
            customValuation: Double = 0.0,
            irr: Double = 0.0,
            initialInvestmentDate: LocalDate = LocalDate.now()
        ): FollowOnInvestment {
            val investment = FollowOnInvestment(
                id = id,
                amount = amount,
                investmentType = investmentType,
                timingType = timingType,
                absoluteDate = absoluteDate,
                relativeTime = relativeTime,
                relativeTimeUnit = relativeTimeUnit,
                valuationMode = valuationMode,
                valuationType = valuationType,
                customValuation = customValuation,
                irr = irr
            )
            
            investment.validate(initialInvestmentDate)
            return investment
        }
    }
    
    /**
     * Validates the follow-on investment for data integrity
     */
    @Throws(FollowOnInvestmentValidationException::class)
    fun validate(initialInvestmentDate: LocalDate = LocalDate.now()) {
        // Validate investment amount
        if (amount <= 0) {
            throw FollowOnInvestmentValidationException("Investment amount must be positive")
        }
        
        // Validate timing
        when (timingType) {
            TimingType.ABSOLUTE -> {
                // For absolute dates, ensure it's not in the past relative to initial investment
                if (absoluteDate <= initialInvestmentDate) {
                    throw FollowOnInvestmentValidationException("Investment date must be after initial investment date")
                }
            }
            TimingType.RELATIVE -> {
                if (relativeTime <= 0) {
                    throw FollowOnInvestmentValidationException("Relative time must be positive")
                }
            }
        }
        
        // Validate valuation based on mode
        when (valuationMode) {
            ValuationMode.CUSTOM -> {
                if (valuationType == ValuationType.SPECIFIED) {
                    if (customValuation <= 0) {
                        throw FollowOnInvestmentValidationException("Custom valuation must be positive")
                    }
                } else {
                    // For computed valuation, validate IRR
                    if (irr <= -100.0 || irr >= 1000.0) {
                        throw FollowOnInvestmentValidationException("IRR must be between -100 and 1000")
                    }
                }
            }
            ValuationMode.TAG_ALONG -> {
                // Tag-along mode doesn't require additional validation
            }
        }
    }
    
    /**
     * Checks if the follow-on investment has valid data
     */
    fun isValid(initialInvestmentDate: LocalDate = LocalDate.now()): Boolean {
        return try {
            validate(initialInvestmentDate)
            true
        } catch (e: FollowOnInvestmentValidationException) {
            false
        }
    }
    
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
    
    /**
     * Converts this FollowOnInvestment to a FollowOnInvestmentEntity for database storage
     */
    fun toEntity(calculationId: String): FollowOnInvestmentEntity {
        return FollowOnInvestmentEntity(
            id = id,
            calculationId = calculationId,
            amount = amount,
            investmentType = investmentType,
            timingType = timingType,
            absoluteDate = if (timingType == TimingType.ABSOLUTE) absoluteDate.toString() else null,
            relativeTime = if (timingType == TimingType.RELATIVE) relativeTime else null,
            relativeTimeUnit = if (timingType == TimingType.RELATIVE) relativeTimeUnit else null,
            valuationMode = valuationMode,
            valuationType = valuationType,
            customValuation = if (valuationType == ValuationType.SPECIFIED) customValuation else null,
            irr = if (valuationType == ValuationType.COMPUTED) irr else null
        )
    }
}