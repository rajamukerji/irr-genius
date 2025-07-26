//
//  SavedCalculation.swift
//  IRR Genius
//
//

import Foundation

// MARK: - Validation Errors
enum SavedCalculationValidationError: LocalizedError {
    case emptyName
    case invalidName(String)
    case negativeInvestment
    case negativeOutcome
    case invalidTimeInMonths
    case invalidIRR
    case invalidFollowOnInvestments([String])
    case missingRequiredFields([String])
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Calculation name cannot be empty"
        case .invalidName(let reason):
            return "Invalid calculation name: \(reason)"
        case .negativeInvestment:
            return "Initial investment must be positive"
        case .negativeOutcome:
            return "Outcome amount must be positive"
        case .invalidTimeInMonths:
            return "Time in months must be positive"
        case .invalidIRR:
            return "IRR must be a valid percentage"
        case .invalidFollowOnInvestments(let errors):
            return "Invalid follow-on investments: \(errors.joined(separator: ", "))"
        case .missingRequiredFields(let fields):
            return "Missing required fields: \(fields.joined(separator: ", "))"
        }
    }
}

struct SavedCalculation: Identifiable, Codable {
    let id: UUID
    let name: String
    let calculationType: CalculationMode
    let createdDate: Date
    let modifiedDate: Date
    let projectId: UUID?
    
    // Calculation inputs (varies by type)
    let initialInvestment: Double?
    let outcomeAmount: Double?
    let timeInMonths: Double?
    let irr: Double?
    let followOnInvestments: [FollowOnInvestment]?
    
    // Portfolio Unit Investment specific parameters
    let unitPrice: Double?
    let successRate: Double? // Percentage (0-100)
    let outcomePerUnit: Double?
    let investorShare: Double? // Percentage (0-100)
    let feePercentage: Double? // Management/legal/servicing fees percentage (0-100)
    
    // Results
    let calculatedResult: Double?
    let growthPoints: [GrowthPoint]?
    
    // Metadata
    let notes: String?
    let tags: [String]
    
    init(id: UUID = UUID(), name: String, calculationType: CalculationMode, 
         createdDate: Date = Date(), modifiedDate: Date = Date(), projectId: UUID? = nil,
         initialInvestment: Double? = nil, outcomeAmount: Double? = nil, 
         timeInMonths: Double? = nil, irr: Double? = nil, 
         followOnInvestments: [FollowOnInvestment]? = nil,
         unitPrice: Double? = nil, successRate: Double? = nil, 
         outcomePerUnit: Double? = nil, investorShare: Double? = nil, 
         feePercentage: Double? = nil,
         calculatedResult: Double? = nil, growthPoints: [GrowthPoint]? = nil,
         notes: String? = nil, tags: [String] = []) throws {
        
        // Validate inputs during initialization
        try Self.validateName(name)
        try Self.validateCalculationInputs(
            calculationType: calculationType,
            initialInvestment: initialInvestment,
            outcomeAmount: outcomeAmount,
            timeInMonths: timeInMonths,
            irr: irr,
            unitPrice: unitPrice,
            successRate: successRate,
            outcomePerUnit: outcomePerUnit,
            investorShare: investorShare
        )
        
        if let followOns = followOnInvestments {
            try Self.validateFollowOnInvestments(followOns)
        }
        
        self.id = id
        self.name = name
        self.calculationType = calculationType
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.projectId = projectId
        self.initialInvestment = initialInvestment
        self.outcomeAmount = outcomeAmount
        self.timeInMonths = timeInMonths
        self.irr = irr
        self.followOnInvestments = followOnInvestments
        self.unitPrice = unitPrice
        self.successRate = successRate
        self.outcomePerUnit = outcomePerUnit
        self.investorShare = investorShare
        self.feePercentage = feePercentage
        self.calculatedResult = calculatedResult
        self.growthPoints = growthPoints
        self.notes = notes
        self.tags = tags
    }
    
    // MARK: - Validation Methods
    
    /// Validates the entire calculation for data integrity
    func validate() throws {
        try Self.validateName(name)
        try Self.validateCalculationInputs(
            calculationType: calculationType,
            initialInvestment: initialInvestment,
            outcomeAmount: outcomeAmount,
            timeInMonths: timeInMonths,
            irr: irr,
            unitPrice: unitPrice,
            successRate: successRate,
            outcomePerUnit: outcomePerUnit,
            investorShare: investorShare
        )
        
        if let followOns = followOnInvestments {
            try Self.validateFollowOnInvestments(followOns)
        }
    }
    
    /// Validates calculation name
    static func validateName(_ name: String) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SavedCalculationValidationError.emptyName
        }
        
        guard name.count <= 100 else {
            throw SavedCalculationValidationError.invalidName("Name too long (max 100 characters)")
        }
        
        // Check for invalid characters
        let invalidChars = CharacterSet(charactersIn: "<>:\"/\\|?*")
        guard name.rangeOfCharacter(from: invalidChars) == nil else {
            throw SavedCalculationValidationError.invalidName("Contains invalid characters")
        }
    }
    
    /// Validates calculation inputs based on calculation type
    static func validateCalculationInputs(
        calculationType: CalculationMode,
        initialInvestment: Double?,
        outcomeAmount: Double?,
        timeInMonths: Double?,
        irr: Double?,
        unitPrice: Double? = nil,
        successRate: Double? = nil,
        outcomePerUnit: Double? = nil,
        investorShare: Double? = nil
    ) throws {
        var missingFields: [String] = []
        
        switch calculationType {
        case .calculateIRR:
            if let investment = initialInvestment {
                guard investment > 0 else { throw SavedCalculationValidationError.negativeInvestment }
            } else {
                missingFields.append("Initial Investment")
            }
            
            if let outcome = outcomeAmount {
                guard outcome > 0 else { throw SavedCalculationValidationError.negativeOutcome }
            } else {
                missingFields.append("Outcome Amount")
            }
            
            if let time = timeInMonths {
                guard time > 0 else { throw SavedCalculationValidationError.invalidTimeInMonths }
            } else {
                missingFields.append("Time in Months")
            }
            
        case .calculateOutcome:
            if let investment = initialInvestment {
                guard investment > 0 else { throw SavedCalculationValidationError.negativeInvestment }
            } else {
                missingFields.append("Initial Investment")
            }
            
            if let irrValue = irr {
                guard irrValue > -100 && irrValue < 1000 else { throw SavedCalculationValidationError.invalidIRR }
            } else {
                missingFields.append("IRR")
            }
            
            if let time = timeInMonths {
                guard time > 0 else { throw SavedCalculationValidationError.invalidTimeInMonths }
            } else {
                missingFields.append("Time in Months")
            }
            
        case .calculateInitial:
            if let outcome = outcomeAmount {
                guard outcome > 0 else { throw SavedCalculationValidationError.negativeOutcome }
            } else {
                missingFields.append("Outcome Amount")
            }
            
            if let irrValue = irr {
                guard irrValue > -100 && irrValue < 1000 else { throw SavedCalculationValidationError.invalidIRR }
            } else {
                missingFields.append("IRR")
            }
            
            if let time = timeInMonths {
                guard time > 0 else { throw SavedCalculationValidationError.invalidTimeInMonths }
            } else {
                missingFields.append("Time in Months")
            }
            
        case .calculateBlendedIRR:
            if let investment = initialInvestment {
                guard investment > 0 else { throw SavedCalculationValidationError.negativeInvestment }
            } else {
                missingFields.append("Initial Investment")
            }
            
            if let outcome = outcomeAmount {
                guard outcome > 0 else { throw SavedCalculationValidationError.negativeOutcome }
            } else {
                missingFields.append("Outcome Amount")
            }
            
            if let time = timeInMonths {
                guard time > 0 else { throw SavedCalculationValidationError.invalidTimeInMonths }
            } else {
                missingFields.append("Time in Months")
            }
            
        case .portfolioUnitInvestment:
            if let investment = initialInvestment {
                guard investment > 0 else { throw SavedCalculationValidationError.negativeInvestment }
            } else {
                missingFields.append("Investment Amount")
            }
            
            if let price = unitPrice {
                guard price > 0 else { throw SavedCalculationValidationError.negativeInvestment }
            } else {
                missingFields.append("Unit Price")
            }
            
            if let rate = successRate {
                guard rate >= 0 && rate <= 100 else { throw SavedCalculationValidationError.invalidIRR }
            } else {
                missingFields.append("Success Rate")
            }
            
            if let outcome = outcomePerUnit {
                guard outcome > 0 else { throw SavedCalculationValidationError.negativeOutcome }
            } else {
                missingFields.append("Outcome Per Unit")
            }
            
            if let share = investorShare {
                guard share >= 0 && share <= 100 else { throw SavedCalculationValidationError.invalidIRR }
            } else {
                missingFields.append("Investor Share")
            }
            
            if let time = timeInMonths {
                guard time > 0 else { throw SavedCalculationValidationError.invalidTimeInMonths }
            } else {
                missingFields.append("Time in Months")
            }
        }
        
        if !missingFields.isEmpty {
            throw SavedCalculationValidationError.missingRequiredFields(missingFields)
        }
    }
    
    /// Validates follow-on investments
    static func validateFollowOnInvestments(_ investments: [FollowOnInvestment]) throws {
        var errors: [String] = []
        
        for (index, investment) in investments.enumerated() {
            do {
                try investment.validate()
            } catch {
                errors.append("Investment \(index + 1): \(error.localizedDescription)")
            }
        }
        
        if !errors.isEmpty {
            throw SavedCalculationValidationError.invalidFollowOnInvestments(errors)
        }
    }
    
    /// Checks if calculation has all required data for its type
    var isComplete: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    /// Returns a summary of the calculation for display purposes
    var summary: String {
        switch calculationType {
        case .calculateIRR:
            if let result = calculatedResult {
                return "IRR: \(String(format: "%.2f", result))%"
            } else {
                return "IRR calculation"
            }
        case .calculateOutcome:
            if let result = calculatedResult {
                return "Outcome: $\(String(format: "%.2f", result))"
            } else {
                return "Outcome calculation"
            }
        case .calculateInitial:
            if let result = calculatedResult {
                return "Initial: $\(String(format: "%.2f", result))"
            } else {
                return "Initial investment calculation"
            }
        case .calculateBlendedIRR:
            if let result = calculatedResult {
                return "Blended IRR: \(String(format: "%.2f", result))%"
            } else {
                return "Blended IRR calculation"
            }
        case .portfolioUnitInvestment:
            if let result = calculatedResult {
                return "Portfolio IRR: \(String(format: "%.2f", result))%"
            } else {
                return "Portfolio unit investment"
            }
        }
    }
    
    /// Creates a copy with updated modification date
    func withUpdatedModificationDate() -> SavedCalculation {
        return try! SavedCalculation(
            id: id,
            name: name,
            calculationType: calculationType,
            createdDate: createdDate,
            modifiedDate: Date(),
            projectId: projectId,
            initialInvestment: initialInvestment,
            outcomeAmount: outcomeAmount,
            timeInMonths: timeInMonths,
            irr: irr,
            followOnInvestments: followOnInvestments,
            unitPrice: unitPrice,
            successRate: successRate,
            outcomePerUnit: outcomePerUnit,
            investorShare: investorShare,
            feePercentage: feePercentage,
            calculatedResult: calculatedResult,
            growthPoints: growthPoints,
            notes: notes,
            tags: tags
        )
    }
}

// MARK: - Serialization Extensions
extension SavedCalculation {
    /// Serializes follow-on investments to JSON data for Core Data storage
    var followOnInvestmentsData: Data? {
        guard let investments = followOnInvestments else { return nil }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(investments)
        } catch {
            print("Failed to encode follow-on investments: \(error)")
            return nil
        }
    }
    
    /// Deserializes follow-on investments from JSON data
    static func followOnInvestments(from data: Data?) -> [FollowOnInvestment]? {
        guard let data = data else { return nil }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([FollowOnInvestment].self, from: data)
        } catch {
            print("Failed to decode follow-on investments: \(error)")
            return nil
        }
    }
    
    /// Serializes growth points to JSON data for Core Data storage
    var growthPointsData: Data? {
        guard let points = growthPoints else { return nil }
        
        do {
            let encoder = JSONEncoder()
            return try encoder.encode(points)
        } catch {
            print("Failed to encode growth points: \(error)")
            return nil
        }
    }
    
    /// Deserializes growth points from JSON data
    static func growthPoints(from data: Data?) -> [GrowthPoint]? {
        guard let data = data else { return nil }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([GrowthPoint].self, from: data)
        } catch {
            print("Failed to decode growth points: \(error)")
            return nil
        }
    }
    
    /// Serializes tags array to JSON string
    var tagsJSON: String {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tags)
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            print("Failed to encode tags: \(error)")
            return "[]"
        }
    }
    
    /// Deserializes tags from JSON string
    static func tags(from json: String?) -> [String] {
        guard let json = json, let data = json.data(using: .utf8) else { return [] }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([String].self, from: data)
        } catch {
            print("Failed to decode tags: \(error)")
            return []
        }
    }
}

// MARK: - Project Validation Errors
enum ProjectValidationError: LocalizedError {
    case emptyName
    case invalidName(String)
    case invalidDescription(String)
    case invalidColor(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Project name cannot be empty"
        case .invalidName(let reason):
            return "Invalid project name: \(reason)"
        case .invalidDescription(let reason):
            return "Invalid project description: \(reason)"
        case .invalidColor(let reason):
            return "Invalid project color: \(reason)"
        }
    }
}

struct Project: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let createdDate: Date
    let modifiedDate: Date
    let color: String? // Hex color for UI
    
    init(id: UUID = UUID(), name: String, description: String? = nil,
         createdDate: Date = Date(), modifiedDate: Date = Date(), color: String? = nil) throws {
        
        // Validate inputs during initialization
        try Self.validateName(name)
        if let desc = description {
            try Self.validateDescription(desc)
        }
        if let colorValue = color {
            try Self.validateColor(colorValue)
        }
        
        self.id = id
        self.name = name
        self.description = description
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.color = color
    }
    
    // MARK: - Validation Methods
    
    /// Validates the entire project for data integrity
    func validate() throws {
        try Self.validateName(name)
        if let desc = description {
            try Self.validateDescription(desc)
        }
        if let colorValue = color {
            try Self.validateColor(colorValue)
        }
    }
    
    /// Validates project name
    static func validateName(_ name: String) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProjectValidationError.emptyName
        }
        
        guard name.count <= 50 else {
            throw ProjectValidationError.invalidName("Name too long (max 50 characters)")
        }
        
        // Check for invalid characters
        let invalidChars = CharacterSet(charactersIn: "<>:\"/\\|?*")
        guard name.rangeOfCharacter(from: invalidChars) == nil else {
            throw ProjectValidationError.invalidName("Contains invalid characters")
        }
    }
    
    /// Validates project description
    static func validateDescription(_ description: String) throws {
        guard description.count <= 500 else {
            throw ProjectValidationError.invalidDescription("Description too long (max 500 characters)")
        }
    }
    
    /// Validates project color (hex format)
    static func validateColor(_ color: String) throws {
        let hexPattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        let regex = try NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: color.utf16.count)
        
        guard regex.firstMatch(in: color, options: [], range: range) != nil else {
            throw ProjectValidationError.invalidColor("Must be a valid hex color (e.g., #FF0000)")
        }
    }
    
    /// Checks if project has valid data
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    /// Creates a copy with updated modification date
    func withUpdatedModificationDate() -> Project {
        return try! Project(
            id: id,
            name: name,
            description: description,
            createdDate: createdDate,
            modifiedDate: Date(),
            color: color
        )
    }
    
    /// Default project colors for UI
    static let defaultColors = [
        "#007AFF", // Blue
        "#34C759", // Green
        "#FF9500", // Orange
        "#FF3B30", // Red
        "#AF52DE", // Purple
        "#FF2D92", // Pink
        "#5AC8FA", // Light Blue
        "#FFCC00", // Yellow
        "#FF6B6B", // Light Red
        "#4ECDC4"  // Teal
    ]
}

// MARK: - Project-Calculation Relationship Extensions
extension Project {
    /// Calculates statistics for calculations associated with this project
    func calculateStatistics(from calculations: [SavedCalculation]) -> ProjectStatistics {
        let projectCalculations = calculations.filter { $0.projectId == self.id }
        
        return ProjectStatistics(
            totalCalculations: projectCalculations.count,
            completedCalculations: projectCalculations.filter { $0.isComplete }.count,
            lastModified: projectCalculations.map { $0.modifiedDate }.max(),
            calculationTypes: Dictionary(grouping: projectCalculations, by: { $0.calculationType })
                .mapValues { $0.count }
        )
    }
}

struct ProjectStatistics {
    let totalCalculations: Int
    let completedCalculations: Int
    let lastModified: Date?
    let calculationTypes: [CalculationMode: Int]
    
    var completionRate: Double {
        guard totalCalculations > 0 else { return 0.0 }
        return Double(completedCalculations) / Double(totalCalculations)
    }
}
