//
//  IRRCalculator.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import Foundation

class IRRCalculator {
    // MARK: - Basic IRR Calculations

    static func calculateIRRValue(initialInvestment: Double, outcomeAmount: Double, timeInYears: Double) -> Double {
        let ratio = outcomeAmount / initialInvestment
        let irr = pow(ratio, 1.0 / timeInYears) - 1
        return irr * 100
    }

    static func calculateOutcomeValue(initialInvestment: Double, irr: Double, timeInYears: Double) -> Double {
        let irrDecimal = irr / 100
        return initialInvestment * pow(1 + irrDecimal, timeInYears)
    }

    static func calculateInitialValue(outcomeAmount: Double, irr: Double, timeInYears: Double) -> Double {
        let irrDecimal = irr / 100
        return outcomeAmount / pow(1 + irrDecimal, timeInYears)
    }

    // MARK: - Blended IRR Calculations

    static func calculateBlendedIRRValue(
        initialInvestment: Double,
        followOnInvestments: [FollowOnInvestment],
        finalValuation: Double,
        totalTimeInYears: Double
    ) -> Double {
        // Sort investments by date
        let sortedInvestments = followOnInvestments.sorted { $0.investmentDate < $1.investmentDate }

        // Calculate total invested capital (time-weighted)
        var totalInvested = initialInvestment * totalTimeInYears // Initial investment for full period
        var totalFinalValue = finalValuation

        // Get the initial investment date from the first follow-on investment (they all have the same reference date)
        let initialInvestmentDate = sortedInvestments.first?.initialInvestmentDate ?? Date()

        // Calculate the final date based on initial investment date + total time
        let finalDate = Calendar.current.date(byAdding: .month, value: Int(totalTimeInYears * 12), to: initialInvestmentDate) ?? Date()

        for investment in sortedInvestments {
            let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")

            guard let amount = Double(cleanAmount) else { continue }

            // Calculate time from investment date to final date
            let monthsFromInvestment = Calendar.current.dateComponents([.month], from: investment.investmentDate, to: finalDate).month ?? 0
            let yearsFromInvestment = Double(monthsFromInvestment) / 12.0

            // Handle different investment types
            switch investment.investmentType {
            case .buy:
                // Add time-weighted investment amount
                totalInvested += amount * yearsFromInvestment

                // For tag-along investments, they follow the same IRR trajectory as initial investment
                if investment.valuationMode == .tagAlong {
                    // The valuation will be calculated based on the blended IRR
                    // This is handled in the chart generation
                } else {
                    // For custom valuations, add the valuation to final value
                    let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
                    if let valuation = Double(cleanValuation) {
                        totalFinalValue += valuation
                    }
                }

            case .sell:
                // Selling reduces the final value
                let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
                if let valuation = Double(cleanValuation) {
                    totalFinalValue -= valuation
                }

            case .buySell:
                // Buy/Sell: add to invested capital but subtract from final value
                totalInvested += amount * yearsFromInvestment
                let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
                if let valuation = Double(cleanValuation) {
                    totalFinalValue -= valuation
                }
            }
        }

        // Calculate blended IRR using the formula: (Final Value / Total Invested)^(1/Total Time) - 1
        let ratio = totalFinalValue / totalInvested
        let blendedIRR = pow(ratio, 1.0 / totalTimeInYears) - 1

        return blendedIRR * 100
    }

    // MARK: - Chart Data Generation

    static func growthPoints(initial: Double, rate: Double, months: Int) -> [GrowthPoint] {
        (0 ... months).map { month in
            let value = initial * pow(1 + rate, Double(month) / 12.0)
            return GrowthPoint(month: month, value: value)
        }
    }

    static func growthPointsWithFollowOn(
        initial: Double,
        followOnInvestments: [FollowOnInvestment],
        finalValuation: Double,
        months: Int
    ) -> [GrowthPoint] {
        var growthPoints: [GrowthPoint] = []

        // Calculate the blended IRR rate
        let totalYears = Double(months) / 12.0
        let blendedIRR = calculateBlendedIRRValue(
            initialInvestment: initial,
            followOnInvestments: followOnInvestments,
            finalValuation: finalValuation,
            totalTimeInYears: totalYears
        ) / 100.0

        // Sort investments by their actual investment date
        let sortedInvestments = followOnInvestments.sorted { $0.investmentDate < $1.investmentDate }

        // Generate monthly growth points
        for month in 0 ... months {
            var totalValue = initial * pow(1 + blendedIRR, Double(month) / 12.0)

            // Add value from follow-on investments
            for investment in sortedInvestments {
                let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")
                guard let amount = Double(cleanAmount) else { continue }

                // Calculate when this investment was made (months from start)
                let initialInvestmentDate = investment.initialInvestmentDate
                let investmentMonth = Calendar.current.dateComponents([.month], from: initialInvestmentDate, to: investment.investmentDate).month ?? 0
                let investmentMonthFromStart = max(0, investmentMonth)

                // Only add growth if the investment was made before or at this month
                if month >= investmentMonthFromStart {
                    let monthsSinceInvestment = month - investmentMonthFromStart

                    switch investment.investmentType {
                    case .buy:
                        if investment.valuationMode == .tagAlong {
                            // Tag-along investments follow the same IRR trajectory as initial investment
                            let investmentGrowth = amount * pow(1 + blendedIRR, Double(monthsSinceInvestment) / 12.0)
                            totalValue += investmentGrowth
                        } else {
                            // Custom valuation - use the specified valuation
                            let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
                            if let valuation = Double(cleanValuation) {
                                totalValue += valuation
                            }
                        }

                    case .sell:
                        // Selling reduces the value
                        let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
                        if let valuation = Double(cleanValuation) {
                            totalValue -= valuation
                        }

                    case .buySell:
                        // Buy/Sell: add the investment amount growth but subtract the sell valuation
                        let investmentGrowth = amount * pow(1 + blendedIRR, Double(monthsSinceInvestment) / 12.0)
                        totalValue += investmentGrowth

                        let cleanValuation = investment.valuation.replacingOccurrences(of: ",", with: "")
                        if let valuation = Double(cleanValuation) {
                            totalValue -= valuation
                        }
                    }
                }
            }

            growthPoints.append(GrowthPoint(month: month, value: totalValue))
        }

        return growthPoints
    }

    // MARK: - Portfolio Growth Points with Follow-On
    
    static func growthPointsWithPortfolioFollowOn(
        initial: Double,
        followOnInvestments: [FollowOnInvestment],
        finalValuation: Double,
        months: Int
    ) -> [GrowthPoint] {
        var growthPoints: [GrowthPoint] = []
        
        // Calculate the blended IRR rate
        let totalYears = Double(months) / 12.0
        
        // For portfolio investments, we need to calculate total invested capital differently
        // since 'valuation' field contains unit price, not total valuation
        var totalInvested = initial
        for investment in followOnInvestments {
            let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")
            if let amount = Double(cleanAmount) {
                totalInvested += amount
            }
        }
        
        // Simple IRR calculation for the portfolio
        let irr = calculateIRRValue(
            initialInvestment: totalInvested,
            outcomeAmount: finalValuation,
            timeInYears: totalYears
        ) / 100.0
        
        // Sort investments by their actual investment date
        let sortedInvestments = followOnInvestments.sorted { $0.investmentDate < $1.investmentDate }
        
        // Generate monthly growth points
        for month in 0 ... months {
            // Start with initial investment growing at IRR
            var totalValue = initial * pow(1 + irr, Double(month) / 12.0)
            
            // Add value from follow-on investments
            for investment in sortedInvestments {
                let cleanAmount = investment.amount.replacingOccurrences(of: ",", with: "")
                guard let amount = Double(cleanAmount) else { continue }
                
                // Calculate when this investment was made (months from start)
                let initialInvestmentDate = investment.initialInvestmentDate
                let investmentMonth = Calendar.current.dateComponents([.month], from: initialInvestmentDate, to: investment.investmentDate).month ?? 0
                let investmentMonthFromStart = max(0, investmentMonth)
                
                // Only add growth if the investment was made before or at this month
                if month >= investmentMonthFromStart {
                    let monthsSinceInvestment = month - investmentMonthFromStart
                    
                    // For portfolio investments, all follow-ons grow at the same IRR
                    let investmentGrowth = amount * pow(1 + irr, Double(monthsSinceInvestment) / 12.0)
                    totalValue += investmentGrowth
                }
            }
            
            growthPoints.append(GrowthPoint(month: month, value: totalValue))
        }
        
        return growthPoints
    }
    
    // MARK: - Portfolio Unit Investment Calculations

    /**
     * Calculates Portfolio Unit Investment IRR
     * @param investmentAmount Total amount invested
     * @param unitPrice Price per unit/lead/patent/etc.
     * @param successRate Percentage of units that succeed (0-100)
     * @param outcomePerUnit Revenue/settlement/profit per successful unit
     * @param investorShare Percentage of outcome that goes to investor (0-100)
     * @param years Time to outcome realization
     * @param feePercentage Optional management/legal/servicing fees (0-100)
     * @return IRR as percentage (e.g., 15.0 for 15%)
     */
    static func calculatePortfolioUnitIRR(
        investmentAmount: Double,
        unitPrice: Double,
        successRate: Double,
        outcomePerUnit: Double,
        investorShare: Double,
        years: Double,
        feePercentage: Double = 0.0
    ) -> Double {
        guard investmentAmount > 0, unitPrice > 0, years > 0 else { return 0.0 }
        guard successRate >= 0, successRate <= 100 else { return 0.0 }
        guard investorShare >= 0, investorShare <= 100 else { return 0.0 }
        guard feePercentage >= 0, feePercentage <= 100 else { return 0.0 }

        // Calculate number of units purchased
        let totalUnits = investmentAmount / unitPrice

        // Calculate successful units
        let successfulUnits = totalUnits * (successRate / 100.0)

        // Calculate gross outcome per successful unit
        let grossOutcomePerUnit = outcomePerUnit * (investorShare / 100.0)

        // Apply fees to the outcome
        let netOutcomePerUnit = grossOutcomePerUnit * (1.0 - feePercentage / 100.0)

        // Calculate total outcome
        let totalOutcome = successfulUnits * netOutcomePerUnit

        // Calculate IRR
        return calculateIRRValue(initialInvestment: investmentAmount, outcomeAmount: totalOutcome, timeInYears: years)
    }

    /**
     * Calculates Portfolio Unit Investment with multiple batches (follow-on investments)
     */
    static func calculatePortfolioUnitBlendedIRR(
        initialInvestmentAmount: Double,
        initialUnitPrice: Double,
        successRate: Double,
        outcomePerUnit: Double,
        investorShare: Double,
        years: Double,
        followOnBatches: [PortfolioUnitBatch],
        feePercentage: Double = 0.0
    ) -> Double {
        guard initialInvestmentAmount > 0, initialUnitPrice > 0, years > 0 else { return 0.0 }

        // Calculate initial batch
        let initialUnits = initialInvestmentAmount / initialUnitPrice
        var totalInvestment = initialInvestmentAmount
        var totalUnits = initialUnits

        // Add follow-on batches
        for batch in followOnBatches {
            let batchUnits = batch.investmentAmount / batch.unitPrice
            totalInvestment += batch.investmentAmount
            totalUnits += batchUnits
        }

        // Calculate successful units
        let successfulUnits = totalUnits * (successRate / 100.0)

        // Calculate gross outcome per successful unit
        let grossOutcomePerUnit = outcomePerUnit * (investorShare / 100.0)

        // Apply fees to the outcome
        let netOutcomePerUnit = grossOutcomePerUnit * (1.0 - feePercentage / 100.0)

        // Calculate total outcome
        let totalOutcome = successfulUnits * netOutcomePerUnit

        // Calculate blended IRR
        return calculateIRRValue(initialInvestment: totalInvestment, outcomeAmount: totalOutcome, timeInYears: years)
    }

    /**
     * Generates growth points for Portfolio Unit Investment
     */
    static func portfolioUnitGrowthPoints(
        investmentAmount: Double,
        unitPrice: Double,
        successRate: Double,
        outcomePerUnit: Double,
        investorShare: Double,
        years: Double,
        feePercentage: Double = 0.0
    ) -> [GrowthPoint] {
        let monthsTotal = Int(years * 12)
        var points: [GrowthPoint] = []

        // Calculate final outcome
        let totalUnits = investmentAmount / unitPrice
        let successfulUnits = totalUnits * (successRate / 100.0)
        let grossOutcomePerUnit = outcomePerUnit * (investorShare / 100.0)
        let netOutcomePerUnit = grossOutcomePerUnit * (1.0 - feePercentage / 100.0)
        let totalOutcome = successfulUnits * netOutcomePerUnit

        // Calculate IRR for growth trajectory (as decimal)
        let irrPercentage = calculateIRRValue(initialInvestment: investmentAmount, outcomeAmount: totalOutcome, timeInYears: years)
        let irr = irrPercentage / 100.0

        // Generate growth points
        for month in 0 ... monthsTotal {
            let yearFraction = Double(month) / 12.0
            let value = investmentAmount * pow(1.0 + irr, yearFraction)
            points.append(GrowthPoint(month: month, value: value))
        }

        return points
    }
}

/**
 * Data structure for follow-on portfolio unit investment batches
 */
struct PortfolioUnitBatch {
    let investmentAmount: Double
    let unitPrice: Double
    let investmentDate: Date
}
