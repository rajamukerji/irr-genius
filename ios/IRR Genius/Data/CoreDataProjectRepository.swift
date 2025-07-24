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
    
    init(container: NSPersistentContainer) {
        self.container = container
        self.context = container.viewContext
    }
    
    func saveProject(_ project: Project) async throws {
        try await context.perform {
            let entity = ProjectEntity(context: self.context)
            entity.id = project.id
            entity.name = project.name
            entity.projectDescription = project.description
            entity.createdDate = project.createdDate
            entity.modifiedDate = project.modifiedDate
            entity.color = project.color
            
            try self.context.save()
        }
    }
    
    func loadProjects() async throws -> [Project] {
        return try await context.perform {
            let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ProjectEntity.modifiedDate, ascending: false)]
            
            let entities = try self.context.fetch(request)
            return try entities.compactMap { try self.convertToProject($0) }
        }
    }
    
    func loadProject(id: UUID) async throws -> Project? {
        return try await context.perform {
            let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let entity = try self.context.fetch(request).first else {
                return nil
            }
            
            return try self.convertToProject(entity)
        }
    }
    
    func deleteProject(id: UUID) async throws {
        try await context.perform {
            let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            guard let entity = try self.context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            self.context.delete(entity)
            try self.context.save()
        }
    }
    
    func searchProjects(query: String) async throws -> [Project] {
        return try await context.perform {
            let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR projectDescription CONTAINS[cd] %@", query, query)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ProjectEntity.modifiedDate, ascending: false)]
            
            let entities = try self.context.fetch(request)
            return try entities.compactMap { try self.convertToProject($0) }
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
