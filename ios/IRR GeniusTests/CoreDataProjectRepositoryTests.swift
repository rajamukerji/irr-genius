//
//  CoreDataProjectRepositoryTests.swift
//  IRR GeniusTests
//
//

import XCTest
import CoreData
@testable import IRR_Genius

final class CoreDataProjectRepositoryTests: XCTestCase {
    var repository: CoreDataProjectRepository!
    var testContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        testContainer = CoreDataStack.createInMemoryContainer()
        repository = CoreDataProjectRepository(container: testContainer)
    }
    
    override func tearDown() {
        repository = nil
        testContainer = nil
        super.tearDown()
    }
    
    func testSaveAndLoadProject() async throws {
        // Given
        let project = createTestProject()
        
        // When
        try await repository.saveProject(project)
        let loaded = try await repository.loadProject(id: project.id)
        
        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, project.id)
        XCTAssertEqual(loaded?.name, project.name)
        XCTAssertEqual(loaded?.description, project.description)
        XCTAssertEqual(loaded?.color, project.color)
    }
    
    func testLoadAllProjects() async throws {
        // Given
        let project1 = createTestProject(name: "Project 1")
        let project2 = createTestProject(name: "Project 2")
        
        // When
        try await repository.saveProject(project1)
        try await repository.saveProject(project2)
        let projects = try await repository.loadProjects()
        
        // Then
        XCTAssertEqual(projects.count, 2)
        XCTAssertTrue(projects.contains { $0.name == "Project 1" })
        XCTAssertTrue(projects.contains { $0.name == "Project 2" })
    }
    
    func testDeleteProject() async throws {
        // Given
        let project = createTestProject()
        try await repository.saveProject(project)
        
        // When
        try await repository.deleteProject(id: project.id)
        let loaded = try await repository.loadProject(id: project.id)
        
        // Then
        XCTAssertNil(loaded)
    }
    
    func testSearchProjects() async throws {
        // Given
        let project1 = createTestProject(name: "Real Estate Analysis")
        let project2 = createTestProject(name: "Stock Investment")
        let project3 = createTestProject(name: "Bond Study", description: "Real estate bonds")
        
        try await repository.saveProject(project1)
        try await repository.saveProject(project2)
        try await repository.saveProject(project3)
        
        // When
        let results = try await repository.searchProjects(query: "Real")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.name == "Real Estate Analysis" })
        XCTAssertTrue(results.contains { $0.name == "Bond Study" })
    }
    
    // MARK: - Helper Methods
    
    private func createTestProject(
        name: String = "Test Project",
        description: String? = "Test project description"
    ) -> Project {
        return Project(
            name: name,
            description: description,
            color: "#FF5733"
        )
    }
}
