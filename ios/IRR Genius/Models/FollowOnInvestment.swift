//
//  FollowOnInvestment.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import Foundation

// Import enums from the same module

// Data structure for follow-on investments
struct FollowOnInvestment: Identifiable {
    let id = UUID()
    var timingType: TimingType
    var date: Date // Used when timingType is .absoluteDate
    var relativeAmount: String // Used when timingType is .relativeTime
    var relativeUnit: TimeUnit // Used when timingType is .relativeTime
    var investmentType: InvestmentType
    var amount: String
    var valuationMode: ValuationMode
    var valuationType: ValuationType // Only used when valuationMode is .custom
    var valuation: String // Either computed based on IRR or specified directly
    var irr: String // Used for computed valuation
    var initialInvestmentDate: Date // Reference date for relative timing
    
    // Computed property to get the actual investment date
    var investmentDate: Date {
        switch timingType {
        case .absoluteDate:
            return date
        case .relativeTime:
            let amount = Double(relativeAmount) ?? 0
            let calendar = Calendar.current
            switch relativeUnit {
            case .days:
                return calendar.date(byAdding: .day, value: Int(amount), to: initialInvestmentDate) ?? initialInvestmentDate
            case .months:
                return calendar.date(byAdding: .month, value: Int(amount), to: initialInvestmentDate) ?? initialInvestmentDate
            case .years:
                return calendar.date(byAdding: .year, value: Int(amount), to: initialInvestmentDate) ?? initialInvestmentDate
            }
        }
    }
} 