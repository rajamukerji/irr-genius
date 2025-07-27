//
//  CloudKitSyncService.swift
//  IRR Genius
//
//  CloudKit synchronization service for calculations and projects
//

import Foundation
import CloudKit
import Combine

// MARK: - Sync Status
enum SyncStatus {
    case idle
    case syncing
    case success(Date)
    case error(Error)
    
    var isActive: Bool {
        if case .syncing = self { return true }
        return false
    }
    
    var lastSyncDate: Date? {
        if case .success(let date) = self { return date }
        return nil
    }
    
    var errorMessage: String? {
        if case .error(let error) = self { return error.localizedDescription }
        return nil
    }
}

// MARK: - Retry Operation
struct RetryOperation {
    let id: UUID = UUID()
    let operation: () async throws -> Void
    let description: String
    var attemptCount: Int = 0
    let maxAttempts: Int
    let createdAt: Date = Date()
    
    var canRetry: Bool {
        return attemptCount < maxAttempts
    }
}

// MARK: - Sync Conflict Resolution
enum ConflictResolution {
    case useLocal
    case useRemote
    case merge
    case askUser
}

struct SyncConflict {
    let localRecord: SavedCalculation
    let remoteRecord: SavedCalculation
    let conflictType: ConflictType
    
    enum ConflictType {
        case modificationDate
        case dataConflict([String]) // Field names that conflict
    }
}

// MARK: - CloudKit Sync Service Protocol
@MainActor
protocol CloudKitSyncServiceProtocol: ObservableObject {
    var syncStatus: SyncStatus { get }
    var isCloudKitAvailable: Bool { get }
    var lastSyncDate: Date? { get }
    var syncProgress: Double { get }
    
    func enableSync() async throws
    func disableSync() async throws
    func syncCalculations() async throws
    func syncProjects() async throws
    func uploadCalculation(_ calculation: SavedCalculation) async throws
    func uploadProject(_ project: Project) async throws
    func downloadCalculations() async throws -> [SavedCalculation]
    func downloadProjects() async throws -> [Project]
    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async throws
}

// MARK: - CloudKit Sync Service Implementation
@MainActor
class CloudKitSyncService: CloudKitSyncServiceProtocol {
    
    // MARK: - Published Properties
    @Published var syncStatus: SyncStatus = .idle
    @Published var syncProgress: Double = 0.0
    @Published var pendingConflicts: [SyncConflict] = []
    
    // MARK: - Private Properties
    private let container: CKContainer
    private let database: CKDatabase
    private let userDefaults = UserDefaults.standard
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 300 // 5 minutes
    private let repositoryManager: RepositoryManager
    private var retryQueue: [RetryOperation] = []
    private var retryTimer: Timer?
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 30 // 30 seconds
    
    // CloudKit record types
    private let calculationRecordType = "SavedCalculation"
    private let projectRecordType = "Project"
    
    // MARK: - Computed Properties
    var isCloudKitAvailable: Bool {
        return FileManager.default.ubiquityIdentityToken != nil
    }
    
    var lastSyncDate: Date? {
        return userDefaults.object(forKey: "LastSyncDate") as? Date
    }
    
    private var isSyncEnabled: Bool {
        get { userDefaults.bool(forKey: "CloudKitSyncEnabled") }
        set { userDefaults.set(newValue, forKey: "CloudKitSyncEnabled") }
    }
    
    // MARK: - Initialization
    init(container: CKContainer = CKContainer.default(), repositoryManager: RepositoryManager = RepositoryManager()) {
        self.container = container
        self.database = container.privateCloudDatabase
        self.repositoryManager = repositoryManager
        
        // Start automatic sync if enabled
        if isSyncEnabled && isCloudKitAvailable {
            startAutomaticSync()
            startRetryTimer()
        }
    }
    
    // MARK: - Sync Management
    
    func enableSync() async throws {
        guard isCloudKitAvailable else {
            throw CloudKitError.notAvailable
        }
        
        // Check CloudKit account status
        let accountStatus = try await container.accountStatus()
        guard accountStatus == .available else {
            throw CloudKitError.accountNotAvailable(accountStatus)
        }
        
        // Permissions are no longer required for basic CloudKit operations in iOS 17+
        // User discoverability has been deprecated
        
        isSyncEnabled = true
        startAutomaticSync()
        
        // Perform initial sync
        try await syncCalculations()
        try await syncProjects()
    }
    
    func disableSync() async throws {
        isSyncEnabled = false
        stopAutomaticSync()
        syncStatus = .idle
    }
    
    private func startAutomaticSync() {
        stopAutomaticSync()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                do {
                    try await self?.syncCalculations()
                    try await self?.syncProjects()
                } catch {
                    self?.syncStatus = .error(error)
                }
            }
        }
    }
    
    private func stopAutomaticSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - Retry Mechanism
    
    private func startRetryTimer() {
        stopRetryTimer()
        
        retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.processRetryQueue()
            }
        }
    }
    
    private func stopRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    private func addToRetryQueue(operation: @escaping () async throws -> Void, description: String) {
        let retryOperation = RetryOperation(
            operation: operation,
            description: description,
            maxAttempts: maxRetryAttempts
        )
        retryQueue.append(retryOperation)
    }
    
    private func processRetryQueue() async {
        guard !retryQueue.isEmpty else { return }
        
        var completedOperations: [UUID] = []
        
        for (index, var operation) in retryQueue.enumerated() {
            guard operation.canRetry else {
                completedOperations.append(operation.id)
                continue
            }
            
            operation.attemptCount += 1
            retryQueue[index] = operation
            
            do {
                try await operation.operation()
                completedOperations.append(operation.id)
                print("Retry operation succeeded: \(operation.description)")
            } catch {
                print("Retry operation failed (attempt \(operation.attemptCount)/\(operation.maxAttempts)): \(operation.description) - \(error)")
                
                if !operation.canRetry {
                    completedOperations.append(operation.id)
                    print("Max retry attempts reached for: \(operation.description)")
                }
            }
        }
        
        // Remove completed operations
        retryQueue.removeAll { completedOperations.contains($0.id) }
    }
    
    // MARK: - Calculation Sync
    
    func syncCalculations() async throws {
        guard isSyncEnabled && isCloudKitAvailable else { return }
        
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            // Get local calculations
            let localCalculations = try await getLocalCalculations()
            syncProgress = 0.2
            
            // Get remote calculations
            let remoteCalculations = try await downloadCalculations()
            syncProgress = 0.4
            
            // Resolve conflicts and merge
            let (toUpload, toDownload, conflicts) = try await resolveCalculationDifferences(
                local: localCalculations,
                remote: remoteCalculations
            )
            syncProgress = 0.6
            
            // Handle conflicts
            if !conflicts.isEmpty {
                pendingConflicts.append(contentsOf: conflicts)
                // For now, use last-modified-wins strategy
                for conflict in conflicts {
                    try await resolveConflict(conflict, resolution: .useLocal)
                }
            }
            
            // Upload new/modified local calculations
            for calculation in toUpload {
                try await uploadCalculation(calculation)
            }
            syncProgress = 0.8
            
            // Save new/modified remote calculations locally
            for calculation in toDownload {
                try await saveCalculationLocally(calculation)
            }
            syncProgress = 1.0
            
            // Update last sync date
            userDefaults.set(Date(), forKey: "LastSyncDate")
            syncStatus = .success(Date())
            
        } catch {
            syncStatus = .error(error)
            throw error
        }
    }
    
    func uploadCalculation(_ calculation: SavedCalculation) async throws {
        let record = try createCalculationRecord(from: calculation)
        
        do {
            _ = try await database.save(record)
        } catch let error as CKError {
            if error.code == .serverRecordChanged {
                // Handle conflict
                try await handleCalculationConflict(calculation, error: error)
            } else if shouldRetryError(error) {
                // Add to retry queue for network errors
                addToRetryQueue(
                    operation: { [weak self] in
                        try await self?.uploadCalculation(calculation)
                    },
                    description: "Upload calculation: \(calculation.name)"
                )
                throw CloudKitError.uploadFailed(error)
            } else {
                throw CloudKitError.uploadFailed(error)
            }
        }
    }
    
    func downloadCalculations() async throws -> [SavedCalculation] {
        let query = CKQuery(recordType: calculationRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            
            var calculations: [SavedCalculation] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let calculation = try? createCalculation(from: record) {
                        calculations.append(calculation)
                    }
                case .failure(let error):
                    print("Failed to fetch calculation record: \(error)")
                }
            }
            
            return calculations
        } catch {
            throw CloudKitError.downloadFailed(error)
        }
    }
    
    // MARK: - Project Sync
    
    func syncProjects() async throws {
        guard isSyncEnabled && isCloudKitAvailable else { return }
        
        do {
            // Get local projects
            let localProjects = try await getLocalProjects()
            
            // Get remote projects
            let remoteProjects = try await downloadProjects()
            
            // Resolve differences and sync
            let (toUpload, toDownload, _) = try await resolveProjectDifferences(
                local: localProjects,
                remote: remoteProjects
            )
            
            // Upload new/modified local projects
            for project in toUpload {
                try await uploadProject(project)
            }
            
            // Save new/modified remote projects locally
            for project in toDownload {
                try await saveProjectLocally(project)
            }
            
        } catch {
            throw error
        }
    }
    
    func uploadProject(_ project: Project) async throws {
        let record = try createProjectRecord(from: project)
        
        do {
            _ = try await database.save(record)
        } catch let error as CKError {
            if error.code == .serverRecordChanged {
                // Handle conflict - for projects, use last-modified-wins
                try await handleProjectConflict(project, error: error)
            } else if shouldRetryError(error) {
                // Add to retry queue for network errors
                addToRetryQueue(
                    operation: { [weak self] in
                        try await self?.uploadProject(project)
                    },
                    description: "Upload project: \(project.name)"
                )
                throw CloudKitError.uploadFailed(error)
            } else {
                throw CloudKitError.uploadFailed(error)
            }
        }
    }
    
    func downloadProjects() async throws -> [Project] {
        let query = CKQuery(recordType: projectRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            
            var projects: [Project] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let project = try? createProject(from: record) {
                        projects.append(project)
                    }
                case .failure(let error):
                    print("Failed to fetch project record: \(error)")
                }
            }
            
            return projects
        } catch {
            throw CloudKitError.downloadFailed(error)
        }
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async throws {
        switch resolution {
        case .useLocal:
            try await uploadCalculation(conflict.localRecord)
        case .useRemote:
            try await saveCalculationLocally(conflict.remoteRecord)
        case .merge:
            let mergedCalculation = try mergeCalculations(local: conflict.localRecord, remote: conflict.remoteRecord)
            try await uploadCalculation(mergedCalculation)
            try await saveCalculationLocally(mergedCalculation)
        case .askUser:
            // This will be handled by the UI layer
            break
        }
        
        // Remove resolved conflict
        pendingConflicts.removeAll { $0.localRecord.id == conflict.localRecord.id }
    }
    
    // MARK: - CloudKit Record Creation
    
    private func createCalculationRecord(from calculation: SavedCalculation) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: calculation.id.uuidString)
        let record = CKRecord(recordType: calculationRecordType, recordID: recordID)
        
        record["name"] = calculation.name
        record["calculationType"] = calculation.calculationType.rawValue
        record["createdDate"] = calculation.createdDate
        record["modifiedDate"] = calculation.modifiedDate
        record["projectId"] = calculation.projectId?.uuidString
        
        // Calculation inputs
        record["initialInvestment"] = calculation.initialInvestment
        record["outcomeAmount"] = calculation.outcomeAmount
        record["timeInMonths"] = calculation.timeInMonths
        record["irr"] = calculation.irr
        record["unitPrice"] = calculation.unitPrice
        record["successRate"] = calculation.successRate
        record["outcomePerUnit"] = calculation.outcomePerUnit
        record["investorShare"] = calculation.investorShare
        record["feePercentage"] = calculation.feePercentage
        
        // Results
        record["calculatedResult"] = calculation.calculatedResult
        
        // Metadata
        record["notes"] = calculation.notes
        record["tags"] = calculation.tagsJSON
        
        // Complex data as JSON
        if let followOnData = calculation.followOnInvestmentsData {
            record["followOnInvestments"] = followOnData
        }
        
        if let growthPointsData = calculation.growthPointsData {
            record["growthPoints"] = growthPointsData
        }
        
        return record
    }
    
    private func createProjectRecord(from project: Project) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: project.id.uuidString)
        let record = CKRecord(recordType: projectRecordType, recordID: recordID)
        
        record["name"] = project.name
        record["description"] = project.description
        record["createdDate"] = project.createdDate
        record["modifiedDate"] = project.modifiedDate
        record["color"] = project.color
        
        return record
    }
    
    // MARK: - Model Creation from CloudKit Records
    
    private func createCalculation(from record: CKRecord) throws -> SavedCalculation {
        guard let name = record["name"] as? String,
              let calculationTypeRaw = record["calculationType"] as? String,
              let calculationType = CalculationMode(rawValue: calculationTypeRaw),
              let createdDate = record["createdDate"] as? Date,
              let modifiedDate = record["modifiedDate"] as? Date else {
            throw CloudKitError.invalidRecord("Missing required calculation fields")
        }
        
        let projectId: UUID?
        if let projectIdString = record["projectId"] as? String {
            projectId = UUID(uuidString: projectIdString)
        } else {
            projectId = nil
        }
        
        // Extract follow-on investments
        let followOnInvestments: [FollowOnInvestment]?
        if let followOnData = record["followOnInvestments"] as? Data {
            followOnInvestments = SavedCalculation.followOnInvestments(from: followOnData)
        } else {
            followOnInvestments = nil
        }
        
        // Extract growth points
        let growthPoints: [GrowthPoint]?
        if let growthPointsData = record["growthPoints"] as? Data {
            growthPoints = SavedCalculation.growthPoints(from: growthPointsData)
        } else {
            growthPoints = nil
        }
        
        // Extract tags
        let tags = SavedCalculation.tags(from: record["tags"] as? String)
        
        return try SavedCalculation(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            name: name,
            calculationType: calculationType,
            createdDate: createdDate,
            modifiedDate: modifiedDate,
            projectId: projectId,
            initialInvestment: record["initialInvestment"] as? Double,
            outcomeAmount: record["outcomeAmount"] as? Double,
            timeInMonths: record["timeInMonths"] as? Double,
            irr: record["irr"] as? Double,
            followOnInvestments: followOnInvestments,
            unitPrice: record["unitPrice"] as? Double,
            successRate: record["successRate"] as? Double,
            outcomePerUnit: record["outcomePerUnit"] as? Double,
            investorShare: record["investorShare"] as? Double,
            feePercentage: record["feePercentage"] as? Double,
            calculatedResult: record["calculatedResult"] as? Double,
            growthPoints: growthPoints,
            notes: record["notes"] as? String,
            tags: tags
        )
    }
    
    private func createProject(from record: CKRecord) throws -> Project {
        guard let name = record["name"] as? String,
              let createdDate = record["createdDate"] as? Date,
              let modifiedDate = record["modifiedDate"] as? Date else {
            throw CloudKitError.invalidRecord("Missing required project fields")
        }
        
        return try Project(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            name: name,
            description: record["description"] as? String,
            createdDate: createdDate,
            modifiedDate: modifiedDate,
            color: record["color"] as? String
        )
    }
    
    // MARK: - Helper Methods
    
    private func getLocalCalculations() async throws -> [SavedCalculation] {
        let result = await repositoryManager.calculationRepository.loadCalculationsSafely()
        switch result {
        case .success(let calculations):
            return calculations
        case .failure(let error):
            throw error
        }
    }
    
    private func getLocalProjects() async throws -> [Project] {
        let result = await repositoryManager.projectRepository.loadProjectsSafely()
        switch result {
        case .success(let projects):
            return projects
        case .failure(let error):
            throw error
        }
    }
    
    private func saveCalculationLocally(_ calculation: SavedCalculation) async throws {
        let result = await repositoryManager.calculationRepository.saveCalculationSafely(calculation)
        switch result {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }
    
    private func saveProjectLocally(_ project: Project) async throws {
        let result = await repositoryManager.projectRepository.saveProjectSafely(project)
        switch result {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }
    
    private func resolveCalculationDifferences(
        local: [SavedCalculation],
        remote: [SavedCalculation]
    ) async throws -> (toUpload: [SavedCalculation], toDownload: [SavedCalculation], conflicts: [SyncConflict]) {
        
        var toUpload: [SavedCalculation] = []
        var toDownload: [SavedCalculation] = []
        var conflicts: [SyncConflict] = []
        
        let localDict = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        let remoteDict = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        
        // Find calculations to upload (local only or newer local)
        for localCalc in local {
            if let remoteCalc = remoteDict[localCalc.id] {
                // Both exist - check for conflicts
                if localCalc.modifiedDate > remoteCalc.modifiedDate {
                    toUpload.append(localCalc)
                } else if localCalc.modifiedDate < remoteCalc.modifiedDate {
                    toDownload.append(remoteCalc)
                } else if !areCalculationsEqual(localCalc, remoteCalc) {
                    // Same modification date but different data - conflict
                    conflicts.append(SyncConflict(
                        localRecord: localCalc,
                        remoteRecord: remoteCalc,
                        conflictType: .dataConflict(findDifferentFields(localCalc, remoteCalc))
                    ))
                }
            } else {
                // Local only - upload
                toUpload.append(localCalc)
            }
        }
        
        // Find calculations to download (remote only)
        for remoteCalc in remote {
            if localDict[remoteCalc.id] == nil {
                toDownload.append(remoteCalc)
            }
        }
        
        return (toUpload, toDownload, conflicts)
    }
    
    private func resolveProjectDifferences(
        local: [Project],
        remote: [Project]
    ) async throws -> (toUpload: [Project], toDownload: [Project], conflicts: [SyncConflict]) {
        
        var toUpload: [Project] = []
        var toDownload: [Project] = []
        
        let localDict = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        let remoteDict = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        
        // Find projects to upload (local only or newer local)
        for localProject in local {
            if let remoteProject = remoteDict[localProject.id] {
                if localProject.modifiedDate > remoteProject.modifiedDate {
                    toUpload.append(localProject)
                } else if localProject.modifiedDate < remoteProject.modifiedDate {
                    toDownload.append(remoteProject)
                }
            } else {
                toUpload.append(localProject)
            }
        }
        
        // Find projects to download (remote only)
        for remoteProject in remote {
            if localDict[remoteProject.id] == nil {
                toDownload.append(remoteProject)
            }
        }
        
        return (toUpload, toDownload, [])
    }
    
    private func areCalculationsEqual(_ calc1: SavedCalculation, _ calc2: SavedCalculation) -> Bool {
        return calc1.name == calc2.name &&
               calc1.calculationType == calc2.calculationType &&
               calc1.initialInvestment == calc2.initialInvestment &&
               calc1.outcomeAmount == calc2.outcomeAmount &&
               calc1.timeInMonths == calc2.timeInMonths &&
               calc1.irr == calc2.irr &&
               calc1.calculatedResult == calc2.calculatedResult &&
               calc1.notes == calc2.notes &&
               calc1.tags == calc2.tags
    }
    
    private func findDifferentFields(_ calc1: SavedCalculation, _ calc2: SavedCalculation) -> [String] {
        var differentFields: [String] = []
        
        if calc1.name != calc2.name { differentFields.append("name") }
        if calc1.initialInvestment != calc2.initialInvestment { differentFields.append("initialInvestment") }
        if calc1.outcomeAmount != calc2.outcomeAmount { differentFields.append("outcomeAmount") }
        if calc1.timeInMonths != calc2.timeInMonths { differentFields.append("timeInMonths") }
        if calc1.irr != calc2.irr { differentFields.append("irr") }
        if calc1.calculatedResult != calc2.calculatedResult { differentFields.append("calculatedResult") }
        if calc1.notes != calc2.notes { differentFields.append("notes") }
        if calc1.tags != calc2.tags { differentFields.append("tags") }
        
        return differentFields
    }
    
    private func mergeCalculations(local: SavedCalculation, remote: SavedCalculation) throws -> SavedCalculation {
        // Simple merge strategy: use the most recent non-nil values
        // In a real implementation, this would be more sophisticated
        
        return try SavedCalculation(
            id: local.id,
            name: local.modifiedDate > remote.modifiedDate ? local.name : remote.name,
            calculationType: local.calculationType,
            createdDate: min(local.createdDate, remote.createdDate),
            modifiedDate: max(local.modifiedDate, remote.modifiedDate),
            projectId: local.projectId ?? remote.projectId,
            initialInvestment: local.initialInvestment ?? remote.initialInvestment,
            outcomeAmount: local.outcomeAmount ?? remote.outcomeAmount,
            timeInMonths: local.timeInMonths ?? remote.timeInMonths,
            irr: local.irr ?? remote.irr,
            followOnInvestments: local.followOnInvestments ?? remote.followOnInvestments,
            unitPrice: local.unitPrice ?? remote.unitPrice,
            successRate: local.successRate ?? remote.successRate,
            outcomePerUnit: local.outcomePerUnit ?? remote.outcomePerUnit,
            investorShare: local.investorShare ?? remote.investorShare,
            feePercentage: local.feePercentage ?? remote.feePercentage,
            calculatedResult: local.calculatedResult ?? remote.calculatedResult,
            growthPoints: local.growthPoints ?? remote.growthPoints,
            notes: local.notes ?? remote.notes,
            tags: Array(Set(local.tags + remote.tags))
        )
    }
    
    private func handleCalculationConflict(_ calculation: SavedCalculation, error: CKError) async throws {
        // Handle server record changed error
        if let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
            let remoteCalculation = try createCalculation(from: serverRecord)
            let conflict = SyncConflict(
                localRecord: calculation,
                remoteRecord: remoteCalculation,
                conflictType: .modificationDate
            )
            pendingConflicts.append(conflict)
        }
    }
    
    private func handleProjectConflict(_ project: Project, error: CKError) async throws {
        // For projects, use simple last-modified-wins strategy
        if let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
            let remoteProject = try createProject(from: serverRecord)
            if project.modifiedDate > remoteProject.modifiedDate {
                // Local is newer, force upload
                let record = try createProjectRecord(from: project)
                _ = try await database.save(record)
            } else {
                // Remote is newer, save locally
                try await saveProjectLocally(remoteProject)
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func shouldRetryError(_ error: CKError) -> Bool {
        switch error.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited:
            return true
        case .zoneBusy, .quotaExceeded:
            return true
        default:
            return false
        }
    }
    
    deinit {
        // Timers will be automatically invalidated when deallocated
    }
}

// MARK: - CloudKit Errors
enum CloudKitError: LocalizedError {
    case notAvailable
    case accountNotAvailable(CKAccountStatus)
    case permissionDenied
    case uploadFailed(Error)
    case downloadFailed(Error)
    case invalidRecord(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "CloudKit is not available on this device"
        case .accountNotAvailable(let status):
            return "CloudKit account not available: \(status)"
        case .permissionDenied:
            return "CloudKit permission denied"
        case .uploadFailed(let error):
            return "Failed to upload to CloudKit: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Failed to download from CloudKit: \(error.localizedDescription)"
        case .invalidRecord(let message):
            return "Invalid CloudKit record: \(message)"
        }
    }
}