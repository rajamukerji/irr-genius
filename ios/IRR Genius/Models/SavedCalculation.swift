//
//  SavedCalculation.swift
//  IRR Genius
//
//

import Foundation

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
         calculatedResult: Double? = nil, growthPoints: [GrowthPoint]? = nil,
         notes: String? = nil, tags: [String] = []) {
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
        self.calculatedResult = calculatedResult
        self.growthPoints = growthPoints
        self.notes = notes
        self.tags = tags
    }
}

struct Project: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let createdDate: Date
    let modifiedDate: Date
    let color: String? // Hex color for UI
    
    init(id: UUID = UUID(), name: String, description: String? = nil,
         createdDate: Date = Date(), modifiedDate: Date = Date(), color: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.color = color
    }
}
