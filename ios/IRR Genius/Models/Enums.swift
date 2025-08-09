//
//  Enums.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import Foundation

enum CalculationMode: String, CaseIterable, Codable {
    case calculateIRR = "Calculate IRR"
    case calculateOutcome = "Calculate Outcome"
    case calculateInitial = "Calculate Initial Investment"
    case calculateBlendedIRR = "Calculate Blended IRR"
    case portfolioUnitInvestment = "Portfolio Unit Investment"
}

enum ValuationType: String, CaseIterable, Codable {
    case computed = "Computed (based on IRR)"
    case specified = "Specified Valuation"
}

enum ValuationMode: String, CaseIterable, Codable {
    case tagAlong = "Tag-Along (follow initial IRR)"
    case custom = "Custom Valuation"
}

enum InvestmentType: String, CaseIterable, Codable {
    case buy = "Buy"
    case sell = "Sell"
    case buySell = "Buy/Sell"
}

enum TimingType: String, CaseIterable, Codable {
    case absoluteDate = "Specific Date"
    case relativeTime = "Relative to Initial Investment"
}

enum TimeUnit: String, CaseIterable, Codable {
    case days = "Days"
    case months = "Months"
    case years = "Years"
}
