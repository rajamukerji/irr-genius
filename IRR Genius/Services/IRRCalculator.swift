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
        (0...months).map { month in
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
        for month in 0...months {
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
} 