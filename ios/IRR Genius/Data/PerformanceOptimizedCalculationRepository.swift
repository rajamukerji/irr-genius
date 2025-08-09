//
//  PerformanceOptimizedCalculationRepository.swift
//  IRR Genius
//

import CoreData
import Foundation

// MARK: - Performance Optimized Repository

extension CoreDataCalculationRepository {
    // MARK: - Paginated Loading

    func loadCalculations(limit: Int, offset: Int = 0) async throws -> [SavedCalculation] {
        return try await context.perform {
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()

            // Performance optimizations
            request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedCalculationEntity.modifiedDate, ascending: false)]
            request.returnsObjectsAsFaults = false
            request.includesSubentities = false
            request.fetchLimit = limit
            request.fetchOffset = offset

            // Prefetch relationships to avoid N+1 queries
            request.relationshipKeyPathsForPrefetching = ["project"]

            let entities = try self.context.fetch(request)
            return try entities.compactMap { try self.convertToSavedCalculation($0) }
        }
    }

    // MARK: - Optimized Search with Indexing

    func searchCalculationsOptimized(query: String, limit: Int = 50) async throws -> [SavedCalculation] {
        return try await context.perform {
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()

            // Use compound predicate for better performance
            let namePredicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
            let notesPredicate = NSPredicate(format: "notes CONTAINS[cd] %@", query)
            let tagsPredicate = NSPredicate(format: "tags CONTAINS[cd] %@", query)

            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                namePredicate, notesPredicate, tagsPredicate,
            ])

            // Optimize for search
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \SavedCalculationEntity.modifiedDate, ascending: false),
            ]
            request.fetchLimit = limit
            request.returnsObjectsAsFaults = false

            let entities = try self.context.fetch(request)
            return try entities.compactMap { try self.convertToSavedCalculation($0) }
        }
    }

    // MARK: - Batch Operations

    func batchSaveCalculations(_ calculations: [SavedCalculation]) async throws {
        try await CoreDataStack.shared.performBatchOperation { context in
            for calculation in calculations {
                try self.saveCalculationInContext(calculation, context: context)
            }
            try context.save()
        }
    }

    func batchDeleteCalculations(ids: [UUID]) async throws {
        try await CoreDataStack.shared.performBatchOperation { context in
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)

            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }

    // MARK: - Statistics and Aggregation

    func getCalculationStatistics() async throws -> CalculationStatistics {
        return try await context.perform {
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()

            // Get total count
            let totalCount = try self.context.count(for: request)

            // Get counts by type
            var typeCounts: [CalculationMode: Int] = [:]
            for type in CalculationMode.allCases {
                let typeRequest: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
                typeRequest.predicate = NSPredicate(format: "calculationType == %d", type.rawValue.hashValue)
                typeCounts[type] = try self.context.count(for: typeRequest)
            }

            // Get recent calculations count (last 30 days)
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recentRequest: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
            recentRequest.predicate = NSPredicate(format: "createdDate >= %@", thirtyDaysAgo as NSDate)
            let recentCount = try self.context.count(for: recentRequest)

            return CalculationStatistics(
                totalCalculations: totalCount,
                calculationsByType: typeCounts,
                recentCalculations: recentCount
            )
        }
    }

    // MARK: - Memory Management

    func clearCache() {
        context.refreshAllObjects()
    }

    func preloadCalculations(ids: [UUID]) async throws {
        try await context.perform {
            let request: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)
            request.returnsObjectsAsFaults = false
            request.relationshipKeyPathsForPrefetching = ["project"]

            _ = try self.context.fetch(request)
        }
    }

    // MARK: - Private Helper Methods

    private func saveCalculationInContext(_ calculation: SavedCalculation, context: NSManagedObjectContext) throws {
        // Check if calculation already exists
        let fetchRequest: NSFetchRequest<SavedCalculationEntity> = SavedCalculationEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", calculation.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let entity: SavedCalculationEntity
        if let existingEntity = try context.fetch(fetchRequest).first {
            entity = existingEntity
        } else {
            entity = SavedCalculationEntity(context: context)
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
    }
}

// MARK: - Statistics Data Model

struct CalculationStatistics {
    let totalCalculations: Int
    let calculationsByType: [CalculationMode: Int]
    let recentCalculations: Int

    var averageCalculationsPerType: Double {
        guard !calculationsByType.isEmpty else { return 0 }
        let total = calculationsByType.values.reduce(0, +)
        return Double(total) / Double(calculationsByType.count)
    }

    var mostUsedCalculationType: CalculationMode? {
        return calculationsByType.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Performance Monitoring

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    private init() {}

    private var operationTimes: [String: [TimeInterval]] = [:]

    func measureOperation<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let endTime = CFAbsoluteTimeGetCurrent()

        let duration = endTime - startTime
        recordOperationTime(name, duration: duration)

        #if DEBUG
            print("⏱️ \(name): \(String(format: "%.3f", duration * 1000))ms")
        #endif

        return result
    }

    func measureAsyncOperation<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()

        let duration = endTime - startTime
        recordOperationTime(name, duration: duration)

        #if DEBUG
            print("⏱️ \(name): \(String(format: "%.3f", duration * 1000))ms")
        #endif

        return result
    }

    private func recordOperationTime(_ operation: String, duration: TimeInterval) {
        if operationTimes[operation] == nil {
            operationTimes[operation] = []
        }
        operationTimes[operation]?.append(duration)

        // Keep only last 100 measurements
        if operationTimes[operation]!.count > 100 {
            operationTimes[operation]?.removeFirst()
        }
    }

    func getAverageTime(for operation: String) -> TimeInterval? {
        guard let times = operationTimes[operation], !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }

    func getPerformanceReport() -> String {
        var report = "📊 Performance Report:\n"

        for (operation, times) in operationTimes {
            guard !times.isEmpty else { continue }

            let average = times.reduce(0, +) / Double(times.count)
            let min = times.min() ?? 0
            let max = times.max() ?? 0

            report += "\(operation):\n"
            report += "  Average: \(String(format: "%.3f", average * 1000))ms\n"
            report += "  Min: \(String(format: "%.3f", min * 1000))ms\n"
            report += "  Max: \(String(format: "%.3f", max * 1000))ms\n"
            report += "  Samples: \(times.count)\n\n"
        }

        return report
    }
}

// MARK: - Lazy Loading Support

class LazyCalculationLoader {
    private let repository: CoreDataCalculationRepository
    private let pageSize: Int
    private var loadedPages: Set<Int> = []
    private var calculations: [SavedCalculation] = []

    init(repository: CoreDataCalculationRepository, pageSize: Int = 20) {
        self.repository = repository
        self.pageSize = pageSize
    }

    func loadPage(_ page: Int) async throws -> [SavedCalculation] {
        guard !loadedPages.contains(page) else {
            let startIndex = page * pageSize
            let endIndex = min(startIndex + pageSize, calculations.count)
            return Array(calculations[startIndex ..< endIndex])
        }

        let offset = page * pageSize
        let pageCalculations = try await repository.loadCalculations(limit: pageSize, offset: offset)

        // Insert calculations at the correct position
        let insertIndex = page * pageSize
        if insertIndex <= calculations.count {
            calculations.insert(contentsOf: pageCalculations, at: insertIndex)
        } else {
            calculations.append(contentsOf: pageCalculations)
        }

        loadedPages.insert(page)
        return pageCalculations
    }

    func getCalculation(at index: Int) async throws -> SavedCalculation? {
        let page = index / pageSize

        if !loadedPages.contains(page) {
            _ = try await loadPage(page)
        }

        guard index < calculations.count else { return nil }
        return calculations[index]
    }

    func reset() {
        loadedPages.removeAll()
        calculations.removeAll()
    }
}
