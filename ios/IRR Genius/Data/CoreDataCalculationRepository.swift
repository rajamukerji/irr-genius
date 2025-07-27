//
//  CoreDataCalculationRepository.swift
//  IRR Genius
//
//

import Foundation
import CoreData

class CoreDataCalculationRepository: CalculationRepository {
    private let container: NSPersistentContainer
    let context: NSManagedObjectContext
    
    init(container: NSPersistentContainer = CoreDataStack.shared.persistentContainer) {
        self.container = container
        self.context = container.viewContext
    }
    
    func saveCalculation(_ calculation: SavedCalculation) async throws {
        do {
            try await context.perform {
                // Check if calculation already exists
                let fetchRequest: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", calculation.id as CVarArg)
                fetchRequest.fetchLimit = 1
                
                let entity: SavedCalculationEntity
                if let existingEntity = try self.context.fetch(fetchRequest).first {
                    entity = existingEntity
                } else {
                    entity = SavedCalculationEntity(context: self.context)
                    entity.id = calculation.id
                    entity.createdDate = calculation.createdDate
                }
                
                // Update entity properties
                entity.name = calculation.name
                entity.calculationType = Int16(calculation.calculationType.rawValue.hashValue)
                entity.modifiedDate = calculation.modifiedDate
                entity.notes = calculation.notes
                entity.tags = calculation.tagsJSON
                entity.projectId = calculation.projectId
                
                // Encode comprehensive input data as JSON
                let inputData = CalculationInputData(
                    initialInvestment: calculation.initialInvestment,
                    outcomeAmount: calculation.outcomeAmount,
                    timeInMonths: calculation.timeInMonths,
                    irr: calculation.irr,
                    unitPrice: calculation.unitPrice,
                    successRate: calculation.successRate,
                    outcomePerUnit: calculation.outcomePerUnit,
                    investorShare: calculation.investorShare,
                    feePercentage: calculation.feePercentage,
                    followOnInvestments: calculation.followOnInvestments
                )
                
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                entity.inputData = try encoder.encode(inputData)
                
                // Encode result data as JSON
                let resultData = CalculationResultData(
                    calculatedResult: calculation.calculatedResult,
                    growthPoints: calculation.growthPoints
                )
                entity.resultData = try encoder.encode(resultData)
                
                try self.context.save()
            }
        } catch {
            throw RepositoryError.persistenceError(underlying: error)
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
    
    func convertToSavedCalculation(_ entity: SavedCalculationEntity) throws -> SavedCalculation {
        guard let id = entity.id,
              let name = entity.name,
              let createdDate = entity.createdDate,
              let modifiedDate = entity.modifiedDate else {
            throw RepositoryError.invalidData
        }
        
        // Decode input data with proper error handling
        var inputData: CalculationInputData?
        if let data = entity.inputData {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                inputData = try decoder.decode(CalculationInputData.self, from: data)
            } catch {
                throw RepositoryError.persistenceError(underlying: error)
            }
        }
        
        // Decode result data with proper error handling
        var resultData: CalculationResultData?
        if let data = entity.resultData {
            do {
                let decoder = JSONDecoder()
                resultData = try decoder.decode(CalculationResultData.self, from: data)
            } catch {
                throw RepositoryError.persistenceError(underlying: error)
            }
        }
        
        // Convert calculation type with better mapping
        let calculationType = CalculationMode.allCases.first { $0.rawValue.hashValue == Int(entity.calculationType) } ?? .calculateIRR
        
        // Parse tags using the proper JSON method
        let tags = SavedCalculation.tags(from: entity.tags)
        
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
            followOnInvestments: inputData?.followOnInvestments,
            unitPrice: inputData?.unitPrice,
            successRate: inputData?.successRate,
            outcomePerUnit: inputData?.outcomePerUnit,
            investorShare: inputData?.investorShare,
            feePercentage: inputData?.feePercentage,
            calculatedResult: resultData?.calculatedResult,
            growthPoints: resultData?.growthPoints,
            notes: entity.notes,
            tags: tags
        )
    }
}

// Helper structs for JSON encoding/decoding
struct CalculationInputData: Codable {
    let initialInvestment: Double?
    let outcomeAmount: Double?
    let timeInMonths: Double?
    let irr: Double?
    
    // Portfolio Unit Investment specific parameters
    let unitPrice: Double?
    let successRate: Double?
    let outcomePerUnit: Double?
    let investorShare: Double?
    let feePercentage: Double?
    
    // Follow-on investments
    let followOnInvestments: [FollowOnInvestment]?
}

struct CalculationResultData: Codable {
    let calculatedResult: Double?
    let growthPoints: [GrowthPoint]?
}
