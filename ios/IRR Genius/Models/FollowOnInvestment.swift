//
//  FollowOnInvestment.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import Foundation

// MARK: - Validation Errors
enum FollowOnInvestmentValidationError: LocalizedError {
    case invalidAmount
    case invalidRelativeAmount
    case invalidValuation
    case invalidIRR
    case futureDateRequired
    case invalidRelativeTime
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Investment amount must be a positive number"
        case .invalidRelativeAmount:
            return "Relative time amount must be a positive number"
        case .invalidValuation:
            return "Valuation must be a positive number"
        case .invalidIRR:
            return "IRR must be a valid percentage"
        case .futureDateRequired:
            return "Investment date must be in the future"
        case .invalidRelativeTime:
            return "Relative time must be positive"
        }
    }
}

// Data structure for follow-on investments
struct FollowOnInvestment: Identifiable, Codable, Equatable {
    let id: UUID
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
    
    init(id: UUID = UUID(), timingType: TimingType = .absoluteDate, date: Date = Date(), 
         relativeAmount: String = "1", relativeUnit: TimeUnit = .years, 
         investmentType: InvestmentType = .buy, amount: String = "0",
         valuationMode: ValuationMode = .tagAlong, valuationType: ValuationType = .computed,
         valuation: String = "0", irr: String = "0", initialInvestmentDate: Date = Date()) {
        self.id = id
        self.timingType = timingType
        self.date = date
        self.relativeAmount = relativeAmount
        self.relativeUnit = relativeUnit
        self.investmentType = investmentType
        self.amount = amount
        self.valuationMode = valuationMode
        self.valuationType = valuationType
        self.valuation = valuation
        self.irr = irr
        self.initialInvestmentDate = initialInvestmentDate
    }
    
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
    
    // MARK: - Validation Methods
    
    /// Validates the follow-on investment for data integrity
    func validate() throws {
        // Validate investment amount
        guard let amountValue = Double(amount), amountValue > 0 else {
            throw FollowOnInvestmentValidationError.invalidAmount
        }
        
        // Validate timing
        switch timingType {
        case .absoluteDate:
            // For absolute dates, ensure it's not in the past relative to initial investment
            guard date > initialInvestmentDate else {
                throw FollowOnInvestmentValidationError.futureDateRequired
            }
            
        case .relativeTime:
            guard let relativeValue = Double(relativeAmount), relativeValue > 0 else {
                throw FollowOnInvestmentValidationError.invalidRelativeAmount
            }
        }
        
        // Validate valuation based on mode
        switch valuationMode {
        case .custom:
            if valuationType == .specified {
                guard let valuationValue = Double(valuation), valuationValue > 0 else {
                    throw FollowOnInvestmentValidationError.invalidValuation
                }
            } else {
                // For computed valuation, validate IRR
                guard let irrValue = Double(irr), irrValue > -100 && irrValue < 1000 else {
                    throw FollowOnInvestmentValidationError.invalidIRR
                }
            }
        case .tagAlong:
            // Tag-along mode doesn't require additional validation
            break
        }
    }
    
    /// Checks if the follow-on investment has valid data
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    /// Returns the numeric amount value
    var numericAmount: Double? {
        return Double(amount)
    }
    
    /// Returns the numeric valuation value
    var numericValuation: Double? {
        return Double(valuation)
    }
    
    /// Returns the numeric IRR value
    var numericIRR: Double? {
        return Double(irr)
    }
    
    /// Returns the numeric relative amount value
    var numericRelativeAmount: Double? {
        return Double(relativeAmount)
    }
} 