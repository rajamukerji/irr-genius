//
//  CalculationRepository.swift
//  IRR Genius
//
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Repository Protocols

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

// MARK: - Repository Factory Protocol

protocol RepositoryFactory {
    func makeCalculationRepository() -> CalculationRepository
    func makeProjectRepository() -> ProjectRepository
}

// MARK: - Production Repository Factory

class ProductionRepositoryFactory: RepositoryFactory {
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer = CoreDataStack.shared.persistentContainer) {
        self.container = container
    }
    
    func makeCalculationRepository() -> CalculationRepository {
        return CoreDataCalculationRepository(container: container)
    }
    
    func makeProjectRepository() -> ProjectRepository {
        return CoreDataProjectRepository(container: container)
    }
}

// MARK: - Test Repository Factory

class TestRepositoryFactory: RepositoryFactory {
    private let container: NSPersistentContainer
    
    init() {
        self.container = CoreDataStack.createInMemoryContainer()
    }
    
    func makeCalculationRepository() -> CalculationRepository {
        return CoreDataCalculationRepository(container: container)
    }
    
    func makeProjectRepository() -> ProjectRepository {
        return CoreDataProjectRepository(container: container)
    }
}

// MARK: - Repository Manager (Dependency Injection Container)

class RepositoryManager: ObservableObject {
    private let factory: RepositoryFactory
    
    lazy var calculationRepository: CalculationRepository = {
        factory.makeCalculationRepository()
    }()
    
    lazy var projectRepository: ProjectRepository = {
        factory.makeProjectRepository()
    }()
    
    init(factory: RepositoryFactory = ProductionRepositoryFactory()) {
        self.factory = factory
    }
    
    // For testing purposes
    static func createTestManager() -> RepositoryManager {
        return RepositoryManager(factory: TestRepositoryFactory())
    }
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case persistenceError(underlying: Error)
    case notFound
    case invalidData
    case duplicateEntry
    case networkError(underlying: Error)
    case syncError(underlying: Error)
    
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
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .syncError(let error):
            return "Sync error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .persistenceError:
            return "Please try again. If the problem persists, restart the app."
        case .notFound:
            return "The item may have been deleted. Please refresh and try again."
        case .invalidData:
            return "Please check your input and try again."
        case .duplicateEntry:
            return "An item with this information already exists."
        case .networkError:
            return "Please check your internet connection and try again."
        case .syncError:
            return "Please try syncing again later."
        }
    }
}

// MARK: - Repository Extensions for Convenience

extension CalculationRepository {
    /// Convenience method to save calculation with automatic validation
    func saveCalculationSafely(_ calculation: SavedCalculation) async -> Result<Void, RepositoryError> {
        do {
            try await saveCalculation(calculation)
            return .success(())
        } catch let error as RepositoryError {
            return .failure(error)
        } catch {
            return .failure(.persistenceError(underlying: error))
        }
    }
    
    /// Convenience method to load calculations with error handling
    func loadCalculationsSafely() async -> Result<[SavedCalculation], RepositoryError> {
        do {
            let calculations = try await loadCalculations()
            return .success(calculations)
        } catch let error as RepositoryError {
            return .failure(error)
        } catch {
            return .failure(.persistenceError(underlying: error))
        }
    }
}

extension ProjectRepository {
    /// Convenience method to save project with automatic validation
    func saveProjectSafely(_ project: Project) async -> Result<Void, RepositoryError> {
        do {
            try await saveProject(project)
            return .success(())
        } catch let error as RepositoryError {
            return .failure(error)
        } catch {
            return .failure(.persistenceError(underlying: error))
        }
    }
    
    /// Convenience method to load projects with error handling
    func loadProjectsSafely() async -> Result<[Project], RepositoryError> {
        do {
            let projects = try await loadProjects()
            return .success(projects)
        } catch let error as RepositoryError {
            return .failure(error)
        } catch {
            return .failure(.persistenceError(underlying: error))
        }
    }
}
