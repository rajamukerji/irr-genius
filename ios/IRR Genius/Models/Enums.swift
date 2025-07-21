//
//  Enums.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import Foundation

enum CalculationMode: String, CaseIterable {
    case calculateIRR = "Calculate IRR"
    case calculateOutcome = "Calculate Outcome"
    case calculateInitial = "Calculate Initial Investment"
    case calculateBlendedIRR = "Calculate Blended IRR"
}

enum ValuationType: String, CaseIterable {
    case computed = "Computed (based on IRR)"
    case specified = "Specified Valuation"
}

enum ValuationMode: String, CaseIterable {
    case tagAlong = "Tag-Along (follow initial IRR)"
    case custom = "Custom Valuation"
}

enum InvestmentType: String, CaseIterable {
    case buy = "Buy"
    case sell = "Sell"
    case buySell = "Buy/Sell"
}

enum TimingType: String, CaseIterable {
    case absoluteDate = "Specific Date"
    case relativeTime = "Relative to Initial Investment"
}

enum TimeUnit: String, CaseIterable {
    case days = "Days"
    case months = "Months"
    case years = "Years"
} 