//
//  CoreDataCalculationRepository.swift
//  IRR Genius
//
//

import Foundation
import CoreData

class CoreDataCalculationRepository: CalculationRepository {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init(container: NSPersistentContainer) {
        self.container = container
        self.context = container.viewContext
    }
    
    func saveCalculation(_ calculation: SavedCalculation) async throws {
        try await context.perform {
            let entity = SavedCalculationEntity(context: self.context)
            entity.id = calculation.id
            entity.name = calculation.name
            entity.calculationType = Int16(calculation.calculationType.rawValue.hashValue)
            entity.createdDate = calculation.createdDate
            entity.modifiedDate = calculation.modifiedDate
            entity.notes = calculation.notes
            entity.tags = calculation.tags.joined(separator: ",")
            entity.projectId = calculation.projectId
            
            // Encode input data as JSON
            let inputData = CalculationInputData(
                initialInvestment: calculation.initialInvestment,
                outcomeAmount: calculation.outcomeAmount,
                timeInMonths: calculation.timeInMonths,
                irr: calculation.irr
            )
            entity.inputData = try JSONEncoder().encode(inputData)
            
            // Encode result data as JSON
            let resultData = CalculationResultData(
                calculatedResult: calculation.calculatedResult,
                growthPoints: calculation.growthPoints
            )
            entity.resultData = try JSONEncoder().encode(resultData)
            
            try self.context.save()
        }
    }
    
    func loadCalculations() async throws -> [SavedCalculation] {
        return try await context.perform {
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedCalculationEntity.modifiedDate, ascending: false)]
            
            let entities = try self.context.fetch(request)
            return try entities.compactMap { try self.convertToSavedCalculation($0) }
        }
    }
    
    func loadCalculation(id: UUID) async throws -> SavedCalculation? {
        return try await context.perform {
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let entity = try self.context.fetch(request).first else {
                return nil
            }
            
            return try self.convertToSavedCalculation(entity)
        }
    }
    
    func deleteCalculation(id: UUID) async throws {
        try await context.perform {
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            self.context.delete(entity)
            try self.context.save()
        }
    }
    
    func searchCalculations(query: String) async throws -> [SavedCalculation] {
        return try await context.perform {
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", query, query)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedCalculationEntity.modifiedDate, ascending: false)]
            
            let entities = try self.context.fetch(request)
            return try entities.compactMap { try self.convertToSavedCalculation($0) }
        }
    }
    
    func loadCalculationsByProject(projectId: UUID) async throws -> [SavedCalculation] {
        return try await context.perform {
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "projectId == %@", projectId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedCalculationEntity.modifiedDate, ascending: false)]
            
            let entities = try self.context.fetch(request)
            return try entities.compactMap { try self.convertToSavedCalculation($0) }
        }
    }
    
    private func convertToSavedCalculation(_ entity: SavedCalculationEntity) throws -> SavedCalculation {
        guard let id = entity.id,
              let name = entity.name,
              let createdDate = entity.createdDate,
              let modifiedDate = entity.modifiedDate else {
            throw RepositoryError.invalidData
        }
        
        // Decode input data
        var inputData: CalculationInputData?
        if let data = entity.inputData {
            inputData = try JSONDecoder().decode(CalculationInputData.self, from: data)
        }
        
        // Decode result data
        var resultData: CalculationResultData?
        if let data = entity.resultData {
            resultData = try JSONDecoder().decode(CalculationResultData.self, from: data)
        }
        
        // Convert calculation type
        let calculationType = CalculationMode.allCases.first { $0.rawValue.hashValue == Int(entity.calculationType) } ?? .calculateIRR
        
        // Parse tags
        let tags = entity.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
        
        return try SavedCalculation(
            id: id,
            name: name,
            calculationType: calculationType,
            createdDate: createdDate,
            modifiedDate: modifiedDate,
            projectId: entity.projectId,
            initialInvestment: inputData?.initialInvestment,
            outcomeAmount: inputData?.outcomeAmount,
            timeInMonths: inputData?.timeInMonths,
            irr: inputData?.irr,
            followOnInvestments: nil, // Simplified for now
            calculatedResult: resultData?.calculatedResult,
            growthPoints: resultData?.growthPoints,
            notes: entity.notes,
            tags: tags
        )
    }
}

// Helper structs for JSON encoding/decoding
private struct CalculationInputData: Codable {
    let initialInvestment: Double?
    let outcomeAmount: Double?
    let timeInMonths: Double?
    let irr: Double?
}

private struct CalculationResultData: Codable {
    let calculatedResult: Double?
    let growthPoints: [GrowthPoint]?
}
