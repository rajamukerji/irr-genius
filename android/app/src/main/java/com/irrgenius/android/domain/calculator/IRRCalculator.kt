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
            points.add(GrowthPoint(month.toFloat(), value.toFloat()))
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
            
            points.add(GrowthPoint(month.toFloat(), value.toFloat()))
        }
        
        return points
    }
}