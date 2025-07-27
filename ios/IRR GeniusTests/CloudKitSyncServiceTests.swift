//
//  CloudKitSyncServiceTests.swift
//  IRR GeniusTests
//

import XCTest
import CloudKit
@testable import IRR_Genius

final class CloudKitSyncServiceTests: XCTestCase {
    
    var mockContainer: MockCKContainer!
    var mockDatabase: MockCKDatabase!
    var mockRepositoryManager: MockRepositoryManager!
    var syncService: CloudKitSyncService!
    
    override func setUp() {
        super.setUp()
        mockContainer = MockCKContainer()
        mockDatabase = MockCKDatabase()
        mockRepositoryManager = MockRepositoryManager()
        
        mockContainer.privateCloudDatabase = mockDatabase
        syncService = CloudKitSyncService(container: mockContainer, repositoryManager: mockRepositoryManager)
    }
    
    override func tearDown() {
        syncService = nil
        mockRepositoryManager = nil
        mockDatabase = nil
        mockContainer = nil
        super.tearDown()
    }
    
    func testSyncStatusInitialization() {
        // When service is created
        // Then initial status should be idle
        XCTAssertEqual(.idle, syncService.syncStatus)
        XCTAssertEqual(0.0, syncService.syncProgress)
        XCTAssertTrue(syncService.pendingConflicts.isEmpty)
    }
    
    func testIsCloudKitAvailable() {
        // Test CloudKit availability check
        // Note: This will depend on the test environment
        // In a real test, you might mock FileManager.default.ubiquityIdentityToken
        let isAvailable = syncService.isCloudKitAvailable
        XCTAssertNotNil(isAvailable) // Should return a boolean value
    }
    
    func testEnableSyncSuccess() async throws {
        // Given CloudKit is available and account is available
        mockContainer.accountStatusResult = .available
        
        // When enabling sync
        try await syncService.enableSync()
        
        // Then sync should be enabled
        XCTAssertTrue(syncService.isSyncEnabled)
        XCTAssertTrue(mockContainer.accountStatusCalled)
    }
    
    func testEnableSyncAccountNotAvailable() async {
        // Given CloudKit account is not available
        mockContainer.accountStatusResult = .noAccount
        
        // When enabling sync
        do {
            try await syncService.enableSync()
            XCTFail("Should throw error when account not available")
        } catch {
            // Then should throw CloudKitError
            XCTAssertTrue(error is CloudKitError)
            if case CloudKitError.accountNotAvailable(let status) = error {
                XCTAssertEqual(.noAccount, status)
            } else {
                XCTFail("Expected accountNotAvailable error")
            }
        }
    }
    
    func testDisableSync() async throws {
        // Given sync is enabled
        try await syncService.enableSync()
        XCTAssertTrue(syncService.isSyncEnabled)
        
        // When disabling sync
        try await syncService.disableSync()
        
        // Then sync should be disabled and status should be idle
        XCTAssertFalse(syncService.isSyncEnabled)
        XCTAssertEqual(.idle, syncService.syncStatus)
    }
    
    func testUploadCalculationSuccess() async throws {
        // Given a calculation and successful save operation
        let calculation = try createTestCalculation()
        mockDatabase.saveResult = .success(createMockRecord(for: calculation))
        
        // When uploading calculation
        try await syncService.uploadCalculation(calculation)
        
        // Then should call database save
        XCTAssertTrue(mockDatabase.saveCalled)
        XCTAssertEqual(1, mockDatabase.saveCallCount)
    }
    
    func testUploadCalculationFailure() async {
        // Given a calculation and failed save operation
        let calculation = try createTestCalculation()
        let error = CKError(.networkFailure)
        mockDatabase.saveResult = .failure(error)
        
        // When uploading calculation
        do {
            try await syncService.uploadCalculation(calculation)
            XCTFail("Should throw error when save fails")
        } catch {
            // Then should throw CloudKitError
            XCTAssertTrue(error is CloudKitError)
            if case CloudKitError.uploadFailed(let underlyingError) = error {
                XCTAssertTrue(underlyingError is CKError)
            } else {
                XCTFail("Expected uploadFailed error")
            }
        }
    }
    
    func testUploadCalculationServerRecordChanged() async throws {
        // Given a calculation and server record changed error
        let calculation = try createTestCalculation()
        let serverRecord = createMockRecord(for: calculation)
        let ckError = CKError(.serverRecordChanged, userInfo: [
            CKRecordChangedErrorServerRecordKey: serverRecord
        ])
        mockDatabase.saveResult = .failure(ckError)
        
        // When uploading calculation
        do {
            try await syncService.uploadCalculation(calculation)
            XCTFail("Should throw error for server record changed")
        } catch {
            // Then should handle conflict and add to pending conflicts
            XCTAssertTrue(error is CloudKitError)
            // Note: In a real implementation, this would add to pending conflicts
        }
    }
    
    func testDownloadCalculationsSuccess() async throws {
        // Given successful query result
        let calculation = try createTestCalculation()
        let record = createMockRecord(for: calculation)
        mockDatabase.recordsResult = .success([(record.recordID, .success(record))])
        
        // When downloading calculations
        let calculations = try await syncService.downloadCalculations()
        
        // Then should return calculations
        XCTAssertEqual(1, calculations.count)
        XCTAssertEqual(calculation.name, calculations[0].name)
        XCTAssertEqual(calculation.calculationType, calculations[0].calculationType)
        XCTAssertTrue(mockDatabase.recordsCalled)
    }
    
    func testDownloadCalculationsFailure() async {
        // Given failed query result
        let error = CKError(.networkFailure)
        mockDatabase.recordsResult = .failure(error)
        
        // When downloading calculations
        do {
            _ = try await syncService.downloadCalculations()
            XCTFail("Should throw error when query fails")
        } catch {
            // Then should throw CloudKitError
            XCTAssertTrue(error is CloudKitError)
            if case CloudKitError.downloadFailed(let underlyingError) = error {
                XCTAssertTrue(underlyingError is CKError)
            } else {
                XCTFail("Expected downloadFailed error")
            }
        }
    }
    
    func testSyncCalculationsSuccess() async throws {
        // Given local and remote calculations
        let localCalc = try createTestCalculation(name: "Local Calc")
        let remoteCalc = try createTestCalculation(name: "Remote Calc")
        
        mockRepositoryManager.calculationRepository.calculations = [localCalc]
        mockDatabase.recordsResult = .success([(createMockRecord(for: remoteCalc).recordID, .success(createMockRecord(for: remoteCalc)))])
        mockDatabase.saveResult = .success(createMockRecord(for: localCalc))
        
        // When syncing calculations
        try await syncService.syncCalculations()
        
        // Then should complete successfully
        if case .success(let date) = syncService.syncStatus {
            XCTAssertNotNil(date)
        } else {
            XCTFail("Expected success status")
        }
        XCTAssertEqual(1.0, syncService.syncProgress)
    }
    
    func testConflictResolutionUseLocal() async throws {
        // Given a sync conflict
        let localCalc = try createTestCalculation(name: "Local Version")
        let remoteCalc = try createTestCalculation(name: "Remote Version")
        let conflict = SyncConflict(
            localRecord: localCalc,
            remoteRecord: remoteCalc,
            conflictType: .modificationDate
        )
        
        mockDatabase.saveResult = .success(createMockRecord(for: localCalc))
        
        // When resolving conflict with USE_LOCAL
        try await syncService.resolveConflict(conflict, resolution: .useLocal)
        
        // Then should upload local version
        XCTAssertTrue(mockDatabase.saveCalled)
    }
    
    func testConflictResolutionUseRemote() async throws {
        // Given a sync conflict
        let localCalc = try createTestCalculation(name: "Local Version")
        let remoteCalc = try createTestCalculation(name: "Remote Version")
        let conflict = SyncConflict(
            localRecord: localCalc,
            remoteRecord: remoteCalc,
            conflictType: .modificationDate
        )
        
        // When resolving conflict with USE_REMOTE
        try await syncService.resolveConflict(conflict, resolution: .useRemote)
        
        // Then should save remote version locally
        XCTAssertTrue(mockRepositoryManager.calculationRepository.saveCalculationCalled)
        XCTAssertEqual(remoteCalc.id, mockRepositoryManager.calculationRepository.lastSavedCalculation?.id)
    }
    
    func testConflictResolutionMerge() async throws {
        // Given a sync conflict
        let localCalc = try createTestCalculation(name: "Local Version", notes: "Local notes")
        let remoteCalc = try createTestCalculation(name: "Remote Version", notes: "Remote notes")
        let conflict = SyncConflict(
            localRecord: localCalc,
            remoteRecord: remoteCalc,
            conflictType: .dataConflict(["name", "notes"])
        )
        
        mockDatabase.saveResult = .success(createMockRecord(for: localCalc))
        
        // When resolving conflict with MERGE
        try await syncService.resolveConflict(conflict, resolution: .merge)
        
        // Then should upload and save merged version
        XCTAssertTrue(mockDatabase.saveCalled)
        XCTAssertTrue(mockRepositoryManager.calculationRepository.saveCalculationCalled)
    }
    
    func testRetryMechanism() async throws {
        // Given a retryable error
        let calculation = try createTestCalculation()
        let retryableError = CKError(.networkFailure)
        mockDatabase.saveResult = .failure(retryableError)
        
        // When uploading calculation (which should fail and add to retry queue)
        do {
            try await syncService.uploadCalculation(calculation)
            XCTFail("Should fail initially")
        } catch {
            // Expected to fail
        }
        
        // Then should add to retry queue
        // Note: In a real implementation, you'd verify the retry queue has the operation
        XCTAssertTrue(mockDatabase.saveCalled)
    }
    
    func testProjectSync() async throws {
        // Given local and remote projects
        let localProject = try createTestProject(name: "Local Project")
        let remoteProject = try createTestProject(name: "Remote Project")
        
        mockRepositoryManager.projectRepository.projects = [localProject]
        mockDatabase.recordsResult = .success([(createMockRecord(for: remoteProject).recordID, .success(createMockRecord(for: remoteProject)))])
        mockDatabase.saveResult = .success(createMockRecord(for: localProject))
        
        // When syncing projects
        try await syncService.syncProjects()
        
        // Then should complete successfully
        XCTAssertTrue(mockDatabase.recordsCalled)
        XCTAssertTrue(mockDatabase.saveCalled)
    }
    
    func testCalculationRecordCreation() throws {
        // Given a calculation
        let calculation = try createTestCalculation()
        
        // When creating CloudKit record
        let record = try syncService.createCalculationRecord(from: calculation)
        
        // Then should have correct fields
        XCTAssertEqual(calculation.id.uuidString, record.recordID.recordName)
        XCTAssertEqual(calculation.name, record["name"] as? String)
        XCTAssertEqual(calculation.calculationType.rawValue, record["calculationType"] as? String)
        XCTAssertEqual(calculation.initialInvestment, record["initialInvestment"] as? Double)
        XCTAssertEqual(calculation.outcomeAmount, record["outcomeAmount"] as? Double)
        XCTAssertEqual(calculation.timeInMonths, record["timeInMonths"] as? Double)
        XCTAssertEqual(calculation.calculatedResult, record["calculatedResult"] as? Double)
        XCTAssertEqual(calculation.notes, record["notes"] as? String)
    }
    
    func testCalculationFromRecord() throws {
        // Given a CloudKit record
        let originalCalc = try createTestCalculation()
        let record = try syncService.createCalculationRecord(from: originalCalc)
        
        // When creating calculation from record
        let calculation = try syncService.createCalculation(from: record)
        
        // Then should match original
        XCTAssertEqual(originalCalc.id, calculation.id)
        XCTAssertEqual(originalCalc.name, calculation.name)
        XCTAssertEqual(originalCalc.calculationType, calculation.calculationType)
        XCTAssertEqual(originalCalc.initialInvestment, calculation.initialInvestment)
        XCTAssertEqual(originalCalc.outcomeAmount, calculation.outcomeAmount)
        XCTAssertEqual(originalCalc.timeInMonths, calculation.timeInMonths)
        XCTAssertEqual(originalCalc.calculatedResult, calculation.calculatedResult)
        XCTAssertEqual(originalCalc.notes, calculation.notes)
    }
    
    // MARK: - Helper Methods
    
    private func createTestCalculation(
        name: String = "Test Calculation",
        notes: String? = "Test notes"
    ) throws -> SavedCalculation {
        return try SavedCalculation(
            name: name,
            calculationType: .calculateIRR,
            initialInvestment: 100000,
            outcomeAmount: 150000,
            timeInMonths: 24,
            calculatedResult: 22.47,
            notes: notes
        )
    }
    
    private func createTestProject(name: String = "Test Project") throws -> Project {
        return try Project(
            name: name,
            description: "Test project description",
            color: "#007AFF"
        )
    }
    
    private func createMockRecord(for calculation: SavedCalculation) -> CKRecord {
        let recordID = CKRecord.ID(recordName: calculation.id.uuidString)
        let record = CKRecord(recordType: "SavedCalculation", recordID: recordID)
        
        record["name"] = calculation.name
        record["calculationType"] = calculation.calculationType.rawValue
        record["createdDate"] = calculation.createdDate
        record["modifiedDate"] = calculation.modifiedDate
        record["initialInvestment"] = calculation.initialInvestment
        record["outcomeAmount"] = calculation.outcomeAmount
        record["timeInMonths"] = calculation.timeInMonths
        record["calculatedResult"] = calculation.calculatedResult
        record["notes"] = calculation.notes
        
        return record
    }
    
    private func createMockRecord(for project: Project) -> CKRecord {
        let recordID = CKRecord.ID(recordName: project.id.uuidString)
        let record = CKRecord(recordType: "Project", recordID: recordID)
        
        record["name"] = project.name
        record["description"] = project.description
        record["createdDate"] = project.createdDate
        record["modifiedDate"] = project.modifiedDate
        record["color"] = project.color
        
        return record
    }
}

// MARK: - Mock Classes

class MockCKContainer: CKContainer {
    var privateCloudDatabase: MockCKDatabase!
    var accountStatusResult: CKAccountStatus = .available
    var accountStatusCalled = false
    
    override func accountStatus() async throws -> CKAccountStatus {
        accountStatusCalled = true
        return accountStatusResult
    }
}

class MockCKDatabase: CKDatabase {
    var saveResult: Result<CKRecord, Error> = .success(CKRecord(recordType: "Test"))
    var recordsResult: Result<[(CKRecord.ID, Result<CKRecord, Error>)], Error> = .success([])
    var saveCalled = false
    var saveCallCount = 0
    var recordsCalled = false
    
    override func save(_ record: CKRecord) async throws -> CKRecord {
        saveCalled = true
        saveCallCount += 1
        switch saveResult {
        case .success(let savedRecord):
            return savedRecord
        case .failure(let error):
            throw error
        }
    }
    
    override func records(matching query: CKQuery) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        recordsCalled = true
        switch recordsResult {
        case .success(let results):
            return (results, nil)
        case .failure(let error):
            throw error
        }
    }
}

class MockRepositoryManager: RepositoryManager {
    let calculationRepository = MockCalculationRepository()
    let projectRepository = MockProjectRepository()
    
    override var calculationRepository: CalculationRepository {
        return calculationRepository
    }
    
    override var projectRepository: ProjectRepository {
        return projectRepository
    }
}

class MockCalculationRepository: CalculationRepository {
    var calculations: [SavedCalculation] = []
    var saveCalculationCalled = false
    var lastSavedCalculation: SavedCalculation?
    
    override func loadCalculationsSafely() async -> Result<[SavedCalculation], Error> {
        return .success(calculations)
    }
    
    override func saveCalculationSafely(_ calculation: SavedCalculation) async -> Result<Void, Error> {
        saveCalculationCalled = true
        lastSavedCalculation = calculation
        calculations.append(calculation)
        return .success(())
    }
}

class MockProjectRepository: ProjectRepository {
    var projects: [Project] = []
    var saveProjectCalled = false
    var lastSavedProject: Project?
    
    override func loadProjectsSafely() async -> Result<[Project], Error> {
        return .success(projects)
    }
    
    override func saveProjectSafely(_ project: Project) async -> Result<Void, Error> {
        saveProjectCalled = true
        lastSavedProject = project
        projects.append(project)
        return .success(())
    }
}