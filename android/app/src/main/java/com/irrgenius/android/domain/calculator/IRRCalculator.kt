package com.irrgenius.android.domain.calculator

import com.irrgenius.android.data.models.*
import java.time.LocalDate
import kotlin.math.pow
import kotlin.math.ln

class IRRCalculator {
    
    fun calculateIRRValue(initial: Double, outcome: Double, years: Double): Double {
        if (initial <= 0 || outcome <= 0 || years <= 0) return 0.0
        return (outcome / initial).pow(1.0 / years) - 1.0
    }
    
    fun calculateOutcomeValue(initial: Double, irr: Double, years: Double): Double {
        if (initial <= 0 || years < 0) return 0.0
        return initial * (1.0 + irr).pow(years)
    }
    
    fun calculateInitialValue(outcome: Double, irr: Double, years: Double): Double {
        if (outcome <= 0 || years < 0) return 0.0
        val divisor = (1.0 + irr).pow(years)
        if (divisor == 0.0) return 0.0
        return outcome / divisor
    }
    
    fun calculateBlendedIRR(
        initial: Double,
        outcome: Double,
        years: Double,
        followOnInvestments: List<FollowOnInvestment>,
        initialInvestmentDate: LocalDate
    ): Double {
        if (followOnInvestments.isEmpty()) {
            return calculateIRRValue(initial, outcome, years)
        }
        
        // Calculate base IRR for tag-along investments
        val baseIRR = calculateIRRValue(initial, outcome, years)
        
        // Calculate total cash flows
        var totalInvested = initial
        var totalProceeds = 0.0
        
        // Process each follow-on investment
        followOnInvestments.forEach { investment ->
            val yearsFromInitial = investment.getYearsFromInitial(initialInvestmentDate)
            
            when (investment.investmentType) {
                InvestmentType.BUY -> {
                    totalInvested += investment.amount
                }
                InvestmentType.SELL -> {
                    val proceeds = when (investment.valuationMode) {
                        ValuationMode.TAG_ALONG -> {
                            val currentValue = initial * (1.0 + baseIRR).pow(yearsFromInitial)
                            investment.amount * (outcome / currentValue)
                        }
                        ValuationMode.CUSTOM -> {
                            when (investment.valuationType) {
                                ValuationType.COMPUTED -> {
                                    val currentValuation = investment.customValuation
                                    val futureValuation = currentValuation * (outcome / (initial * (1.0 + baseIRR).pow(yearsFromInitial)))
                                    investment.amount * (futureValuation / currentValuation)
                                }
                                ValuationType.SPECIFIED -> investment.amount
                            }
                        }
                    }
                    totalProceeds += proceeds
                }
                InvestmentType.BUY_SELL -> {
                    totalInvested += investment.amount
                    val proceeds = investment.amount * (outcome / (initial * (1.0 + baseIRR).pow(yearsFromInitial)))
                    totalProceeds += proceeds
                }
            }
        }
        
        // Final outcome includes remaining value plus any proceeds
        val finalOutcome = outcome + totalProceeds
        
        // Calculate money-weighted return (simplified XIRR)
        return calculateIRRValue(totalInvested, finalOutcome, years)
    }
    
    fun growthPoints(initial: Double, irr: Double, years: Double): List<GrowthPoint> {
        val points = mutableListOf<GrowthPoint>()
        val monthsTotal = (years * 12).toInt()
        
        for (month in 0..monthsTotal) {
            val yearFraction = month / 12.0
            val value = initial * (1.0 + irr).pow(yearFraction)
            points.add(GrowthPoint(month, value))
        }
        
        return points
    }
    
    fun growthPointsWithFollowOn(
        initial: Double,
        irr: Double,
        years: Double,
        followOnInvestments: List<FollowOnInvestment>,
        initialInvestmentDate: LocalDate
    ): List<GrowthPoint> {
        val baseIRR = irr
        val points = mutableListOf<GrowthPoint>()
        val monthsTotal = (years * 12).toInt()
        
        // Track cumulative investment and valuation
        var cumulativeInvestment = initial
        
        for (month in 0..monthsTotal) {
            val yearFraction = month / 12.0
            val currentDate = initialInvestmentDate.plusMonths(month.toLong())
            
            // Base growth
            var value = initial * (1.0 + baseIRR).pow(yearFraction)
            
            // Add impact of follow-on investments up to this point
            followOnInvestments.forEach { investment ->
                val investmentDate = investment.getInvestmentDate(initialInvestmentDate)
                
                if (!currentDate.isBefore(investmentDate)) {
                    val yearsFromInvestment = investment.getYearsFromInitial(initialInvestmentDate)
                    val yearsSinceInvestment = yearFraction - yearsFromInvestment
                    
                    if (yearsSinceInvestment >= 0) {
                        when (investment.investmentType) {
                            InvestmentType.BUY, InvestmentType.BUY_SELL -> {
                                when (investment.valuationMode) {
                                    ValuationMode.TAG_ALONG -> {
                                        value += investment.amount * (1.0 + baseIRR).pow(yearsSinceInvestment)
                                    }
                                    ValuationMode.CUSTOM -> {
                                        // For custom valuation, calculate growth from investment point
                                        val remainingYears = years - yearsFromInvestment
                                        val customIRR = if (investment.customValuation > 0 && remainingYears > 0) {
                                            val finalValue = initial * (1.0 + baseIRR).pow(years)
                                            (finalValue / investment.customValuation).pow(1.0 / remainingYears) - 1.0
                                        } else baseIRR
                                        value += investment.amount * (1.0 + customIRR).pow(yearsSinceInvestment)
                                    }
                                }
                            }
                            InvestmentType.SELL -> {
                                // For sells, reduce the value
                                value -= investment.amount * (1.0 + baseIRR).pow(yearsSinceInvestment)
                            }
                        }
                    }
                }
            }
            
            points.add(GrowthPoint(month, value))
        }
        
        return points
    }
    
    /**
     * Calculates Portfolio Unit Investment IRR
     * @param investmentAmount Total amount invested
     * @param unitPrice Price per unit/lead/patent/etc.
     * @param successRate Percentage of units that succeed (0-100)
     * @param outcomePerUnit Revenue/settlement/profit per successful unit
     * @param investorShare Percentage of outcome that goes to investor (0-100)
     * @param years Time to outcome realization
     * @param feePercentage Optional management/legal/servicing fees (0-100)
     * @return IRR as decimal (e.g., 0.15 for 15%)
     */
    fun calculatePortfolioUnitIRR(
        investmentAmount: Double,
        unitPrice: Double,
        successRate: Double,
        outcomePerUnit: Double,
        investorShare: Double,
        years: Double,
        feePercentage: Double = 0.0
    ): Double {
        if (investmentAmount <= 0 || unitPrice <= 0 || years <= 0) return 0.0
        if (successRate < 0 || successRate > 100) return 0.0
        if (investorShare < 0 || investorShare > 100) return 0.0
        if (feePercentage < 0 || feePercentage > 100) return 0.0
        
        // Calculate number of units purchased
        val totalUnits = investmentAmount / unitPrice
        
        // Calculate successful units
        val successfulUnits = totalUnits * (successRate / 100.0)
        
        // Calculate gross outcome per successful unit
        val grossOutcomePerUnit = outcomePerUnit * (investorShare / 100.0)
        
        // Apply fees to the outcome
        val netOutcomePerUnit = grossOutcomePerUnit * (1.0 - feePercentage / 100.0)
        
        // Calculate total outcome
        val totalOutcome = successfulUnits * netOutcomePerUnit
        
        // Calculate IRR
        return calculateIRRValue(investmentAmount, totalOutcome, years)
    }
    
    /**
     * Calculates Portfolio Unit Investment with multiple batches (follow-on investments)
     */
    fun calculatePortfolioUnitBlendedIRR(
        initialInvestmentAmount: Double,
        initialUnitPrice: Double,
        successRate: Double,
        outcomePerUnit: Double,
        investorShare: Double,
        years: Double,
        followOnBatches: List<PortfolioUnitBatch>,
        initialInvestmentDate: LocalDate,
        feePercentage: Double = 0.0
    ): Double {
        if (initialInvestmentAmount <= 0 || initialUnitPrice <= 0 || years <= 0) return 0.0
        
        // Calculate initial batch
        val initialUnits = initialInvestmentAmount / initialUnitPrice
        var totalInvestment = initialInvestmentAmount
        var totalUnits = initialUnits
        
        // Add follow-on batches
        followOnBatches.forEach { batch ->
            val batchUnits = batch.investmentAmount / batch.unitPrice
            totalInvestment += batch.investmentAmount
            totalUnits += batchUnits
        }
        
        // Calculate successful units
        val successfulUnits = totalUnits * (successRate / 100.0)
        
        // Calculate gross outcome per successful unit
        val grossOutcomePerUnit = outcomePerUnit * (investorShare / 100.0)
        
        // Apply fees to the outcome
        val netOutcomePerUnit = grossOutcomePerUnit * (1.0 - feePercentage / 100.0)
        
        // Calculate total outcome
        val totalOutcome = successfulUnits * netOutcomePerUnit
        
        // Calculate blended IRR
        return calculateIRRValue(totalInvestment, totalOutcome, years)
    }
    
    /**
     * Generates growth points for Portfolio Unit Investment
     */
    fun portfolioUnitGrowthPoints(
        investmentAmount: Double,
        unitPrice: Double,
        successRate: Double,
        outcomePerUnit: Double,
        investorShare: Double,
        years: Double,
        feePercentage: Double = 0.0
    ): List<GrowthPoint> {
        val points = mutableListOf<GrowthPoint>()
        val monthsTotal = (years * 12).toInt()
        
        // Calculate final outcome
        val totalUnits = investmentAmount / unitPrice
        val successfulUnits = totalUnits * (successRate / 100.0)
        val grossOutcomePerUnit = outcomePerUnit * (investorShare / 100.0)
        val netOutcomePerUnit = grossOutcomePerUnit * (1.0 - feePercentage / 100.0)
        val totalOutcome = successfulUnits * netOutcomePerUnit
        
        // Calculate IRR for growth trajectory
        val irr = calculateIRRValue(investmentAmount, totalOutcome, years)
        
        // Generate growth points
        for (month in 0..monthsTotal) {
            val yearFraction = month / 12.0
            val value = investmentAmount * (1.0 + irr).pow(yearFraction)
            points.add(GrowthPoint(month, value))
        }
        
        return points
    }
}

/**
 * Data class for follow-on portfolio unit investment batches
 */
data class PortfolioUnitBatch(
    val investmentAmount: Double,
    val unitPrice: Double,
    val investmentDate: LocalDate
)