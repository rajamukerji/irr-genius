//
//  CalculationRepository.swift
//  IRR Genius
//
//

import Foundation

protocol CalculationRepository {
    func saveCalculation(_ calculation: SavedCalculation) async throws
    func loadCalculations() async throws -> [SavedCalculation]
    func loadCalculation(id: UUID) async throws -> SavedCalculation?
    func deleteCalculation(id: UUID) async throws
    func searchCalculations(query: String) async throws -> [SavedCalculation]
    func loadCalculationsByProject(projectId: UUID) async throws -> [SavedCalculation]
}

protocol ProjectRepository {
    func saveProject(_ project: Project) async throws
    func loadProjects() async throws -> [Project]
    func loadProject(id: UUID) async throws -> Project?
    func deleteProject(id: UUID) async throws
    func searchProjects(query: String) async throws -> [Project]
}

enum RepositoryError: LocalizedError {
    case persistenceError(underlying: Error)
    case notFound
    case invalidData
    case duplicateEntry
    
    var errorDescription: String? {
        switch self {
        case .persistenceError(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .notFound:
            return "Item not found"
        case .invalidData:
            return "Invalid data provided"
        case .duplicateEntry:
            return "Item already exists"
        }
    }
}
