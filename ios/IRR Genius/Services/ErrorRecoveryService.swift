//
//  ErrorRecoveryService.swift
//  IRR Genius
//
//  Created by Kiro on 7/26/25.
//

import Foundation
import SwiftUI
import Network

// MARK: - Error Recovery Framework

/// Protocol for operations that can be retried
protocol RetryableOperation {
    associatedtype Result
    func execute() async throws -> Result
    var maxRetries: Int { get }
    var retryDelay: TimeInterval { get }
    var shouldRetry: (Error) -> Bool { get }
}

/// Default implementation for retryable operations
extension RetryableOperation {
    var maxRetries: Int { 3 }
    var retryDelay: TimeInterval { 1.0 }
    var shouldRetry: (Error) -> Bool {
        return { error in
            // Retry on network errors, temporary failures, but not on validation errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost:
                    return true
                default:
                    return false
                }
            }
            
            let nsError = error as NSError
            // Retry on temporary system errors
            return nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoSuchFileError
        }
    }
}

/// Error recovery service for managing retries and error handling
class ErrorRecoveryService: ObservableObject {
    @Published var isRetrying: Bool = false
    @Published var retryCount: Int = 0
    @Published var lastError: Error?
    
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    @Published var isNetworkAvailable: Bool = true
    
    init() {
        startNetworkMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    /// Executes a retryable operation with automatic retry logic
    func executeWithRetry<T: RetryableOperation>(_ operation: T) async throws -> T.Result {
        var lastError: Error?
        
        for attempt in 0...operation.maxRetries {
            do {
                isRetrying = attempt > 0
                retryCount = attempt
                
                let result = try await operation.execute()
                
                // Success - reset state
                isRetrying = false
                retryCount = 0
                lastError = nil
                
                return result
                
            } catch {
                lastError = error
                self.lastError = error
                
                // Don't retry on the last attempt
                if attempt == operation.maxRetries {
                    break
                }
                
                // Check if we should retry this error
                if !operation.shouldRetry(error) {
                    break
                }
                
                // Wait before retrying with exponential backoff
                let delay = operation.retryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // All retries failed
        isRetrying = false
        throw lastError ?? NSError(domain: "ErrorRecoveryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
    }
    
    /// Manually retry the last failed operation
    func retryLastOperation<T: RetryableOperation>(_ operation: T) async throws -> T.Result {
        return try await executeWithRetry(operation)
    }
    
    /// Checks if an error is recoverable
    func isRecoverable(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost:
                return true
            default:
                return false
            }
        }
        
        let nsError = error as NSError
        // Recoverable system errors
        switch nsError.code {
        case NSFileReadNoSuchFileError, NSFileWriteFileExistsError:
            return true
        default:
            return false
        }
    }
    
    /// Provides recovery suggestions for different error types
    func getRecoverySuggestion(for error: Error) -> String? {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "Check your internet connection and try again"
            case .timedOut:
                return "The request timed out. Please try again"
            case .cannotConnectToHost:
                return "Unable to connect to server. Please try again later"
            default:
                return "Network error occurred. Please try again"
            }
        }
        
        let nsError = error as NSError
        switch nsError.code {
        case NSFileReadNoSuchFileError:
            return "File not found. Please select a valid file"
        case NSFileWriteFileExistsError:
            return "File already exists. Choose a different name"
        default:
            return "System error occurred. Please try again"
        }
    }
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
}

// MARK: - Specific Retryable Operations

/// Retryable operation for saving calculations
struct SaveCalculationOperation: RetryableOperation {
    let calculation: SavedCalculation
    let repository: CalculationRepository
    
    func execute() async throws -> Void {
        try await repository.saveCalculation(calculation)
    }
    
    var maxRetries: Int { 3 }
    var retryDelay: TimeInterval { 0.5 }
}

/// Retryable operation for loading calculations
struct LoadCalculationsOperation: RetryableOperation {
    let repository: CalculationRepository
    
    func execute() async throws -> [SavedCalculation] {
        return try await repository.loadCalculations()
    }
    
    var maxRetries: Int { 3 }
    var retryDelay: TimeInterval { 0.5 }
}

/// Retryable operation for cloud sync
struct CloudSyncOperation: RetryableOperation {
    let syncService: CloudKitSyncService
    
    func execute() async throws -> Void {
        try await syncService.syncCalculations()
    }
    
    var maxRetries: Int { 5 }
    var retryDelay: TimeInterval { 2.0 }
    
    var shouldRetry: (Error) -> Bool {
        return { error in
            // Retry on network errors and CloudKit temporary errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                    return true
                default:
                    return false
                }
            }
            
            // CloudKit specific errors that are retryable
            let nsError = error as NSError
            if nsError.domain == "CKErrorDomain" {
                switch nsError.code {
                case 3, 4, 6: // Network unavailable, network failure, service unavailable
                    return true
                default:
                    return false
                }
            }
            
            return false
        }
    }
}

/// Retryable operation for file import
struct FileImportOperation: RetryableOperation {
    let fileURL: URL
    let importService: CSVImportService
    
    func execute() async throws -> ImportResult {
        return try await importService.importCSV(from: fileURL)
    }
    
    var maxRetries: Int { 2 }
    var retryDelay: TimeInterval { 1.0 }
    
    var shouldRetry: (Error) -> Bool {
        return { error in
            // Only retry on file access errors, not parsing errors
            let nsError = error as NSError
            return nsError.code == NSFileReadNoSuchFileError
        }
    }
}

/// Retryable operation for PDF export
struct PDFExportOperation: RetryableOperation {
    let calculation: SavedCalculation
    let exportService: PDFExportService
    
    func execute() async throws -> URL {
        return try await exportService.exportToPDF(calculation)
    }
    
    var maxRetries: Int { 2 }
    var retryDelay: TimeInterval { 1.0 }
}

/// Retryable operation for CSV/Excel export
struct CSVExcelExportOperation: RetryableOperation {
    let calculations: [SavedCalculation]
    let exportService: CSVExcelExportService
    let format: ExportFormat
    
    enum ExportFormat {
        case csv
        case excel
    }
    
    func execute() async throws -> URL {
        switch format {
        case .csv:
            return try await exportService.exportToCSV(calculations)
        case .excel:
            return try await exportService.exportToExcel(calculations)
        }
    }
    
    var maxRetries: Int { 2 }
    var retryDelay: TimeInterval { 1.0 }
}

// MARK: - Error Recovery UI Components

/// View for displaying retry options
struct RetryView: View {
    let error: Error
    let onRetry: () async -> Void
    let onCancel: () -> Void
    let isRetrying: Bool
    
    @StateObject private var errorRecovery = ErrorRecoveryService()
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Operation Failed")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let suggestion = errorRecovery.getRecoverySuggestion(for: error) {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button("Retry") {
                    Task {
                        await onRetry()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRetrying)
            }
            
            if isRetrying {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Retrying...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
        )
    }
}

/// Automatic retry indicator
struct AutoRetryIndicator: View {
    let attempt: Int
    let maxAttempts: Int
    let isRetrying: Bool
    
    var body: some View {
        if isRetrying {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("Retrying... (\(attempt)/\(maxAttempts))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

/// Network status indicator
struct NetworkStatusView: View {
    @ObservedObject var errorRecovery: ErrorRecoveryService
    
    var body: some View {
        if !errorRecovery.isNetworkAvailable {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.red)
                
                Text("No Internet Connection")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
            )
        }
    }
}

// MARK: - Offline Support

/// Service for managing offline operations
class OfflineOperationQueue: ObservableObject {
    @Published var pendingOperations: [OfflineOperation] = []
    @Published var isProcessingQueue: Bool = false
    
    private let errorRecovery = ErrorRecoveryService()
    
    /// Adds an operation to the offline queue
    func enqueue(_ operation: OfflineOperation) {
        pendingOperations.append(operation)
        
        // Try to process immediately if online
        if errorRecovery.isNetworkAvailable {
            Task {
                await processQueue()
            }
        }
    }
    
    /// Processes all pending operations
    func processQueue() async {
        guard !isProcessingQueue && errorRecovery.isNetworkAvailable else { return }
        
        isProcessingQueue = true
        
        var remainingOperations: [OfflineOperation] = []
        
        for operation in pendingOperations {
            do {
                try await operation.execute()
                // Operation succeeded, don't add to remaining
            } catch {
                // Operation failed, keep for later retry
                remainingOperations.append(operation)
            }
        }
        
        pendingOperations = remainingOperations
        isProcessingQueue = false
    }
    
    /// Clears all pending operations
    func clearQueue() {
        pendingOperations.removeAll()
    }
}

/// Protocol for offline operations
protocol OfflineOperation {
    var id: UUID { get }
    var description: String { get }
    var createdAt: Date { get }
    func execute() async throws
}

/// Offline save operation
struct OfflineSaveOperation: OfflineOperation {
    let id = UUID()
    let calculation: SavedCalculation
    let repository: CalculationRepository
    let createdAt = Date()
    
    var description: String {
        return "Save calculation: \(calculation.name)"
    }
    
    func execute() async throws {
        try await repository.saveCalculation(calculation)
    }
}

/// Offline sync operation
struct OfflineSyncOperation: OfflineOperation {
    let id = UUID()
    let syncService: CloudKitSyncService
    let createdAt = Date()
    
    var description: String {
        return "Sync calculations to cloud"
    }
    
    func execute() async throws {
        try await syncService.syncCalculations()
    }
}