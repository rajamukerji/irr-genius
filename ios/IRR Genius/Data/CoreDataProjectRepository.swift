//
//  CoreDataProjectRepository.swift
//  IRR Genius
//
//

import Foundation
import CoreData

class CoreDataProjectRepository: ProjectRepository {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init(container: NSPersistentContainer = CoreDataStack.shared.persistentContainer) {
        self.container = container
        self.context = container.viewContext
    }
    
    func saveProject(_ project: Project) async throws {
        do {
            try await context.perform {
                // Check if project already exists
                let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)
                fetchRequest.fetchLimit = 1
                
                let entity: ProjectEntity
                if let existingEntity = try self.context.fetch(fetchRequest).first {
                    entity = existingEntity
                } else {
                    entity = ProjectEntity(context: self.context)
                    entity.id = project.id
                    entity.createdDate = project.createdDate
                }
                
                // Update entity properties
                entity.name = project.name
                entity.projectDescription = project.description
                entity.modifiedDate = project.modifiedDate
                entity.color = project.color
                
                try self.context.save()
            }
        } catch {
            throw RepositoryError.persistenceError(underlying: error)
        }
    }
    
    func loadProjects() async throws -> [Project] {
        do {
            return try await context.perform {
                let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \ProjectEntity.modifiedDate, ascending: false)]
                
                let entities = try self.context.fetch(request)
                return try entities.compactMap { try self.convertToProject($0) }
            }
        } catch {
            throw RepositoryError.persistenceError(underlying: error)
        }
    }
    
    func loadProject(id: UUID) async throws -> Project? {
        do {
            return try await context.perform {
                let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1
                
                guard let entity = try self.context.fetch(request).first else {
                    return nil
                }
                
                return try self.convertToProject(entity)
            }
        } catch {
            throw RepositoryError.persistenceError(underlying: error)
        }
    }
    
    func deleteProject(id: UUID) async throws {
        do {
            try await context.perform {
                let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                
                guard let entity = try self.context.fetch(request).first else {
                    throw RepositoryError.notFound
                }
                
                self.context.delete(entity)
                try self.context.save()
            }
        } catch {
            throw RepositoryError.persistenceError(underlying: error)
        }
    }
    
    func searchProjects(query: String) async throws -> [Project] {
        do {
            return try await context.perform {
                let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
                request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR projectDescription CONTAINS[cd] %@", query, query)
                request.sortDescriptors = [NSSortDescriptor(keyPath: \ProjectEntity.modifiedDate, ascending: false)]
                
                let entities = try self.context.fetch(request)
                return try entities.compactMap { try self.convertToProject($0) }
            }
        } catch {
            throw RepositoryError.persistenceError(underlying: error)
        }
    }
    
    private func convertToProject(_ entity: ProjectEntity) throws -> Project {
        guard let id = entity.id,
              let name = entity.name,
              let createdDate = entity.createdDate,
              let modifiedDate = entity.modifiedDate else {
            throw RepositoryError.invalidData
        }
        
        return try Project(
            id: id,
            name: name,
            description: entity.projectDescription,
            createdDate: createdDate,
            modifiedDate: modifiedDate,
            color: entity.color
        )
    }
}
