//
//  PerformanceMonitoringService.swift
//  IRR Genius
//

import Foundation
import os.log
import UIKit

// MARK: - Performance Monitoring Service

class PerformanceMonitoringService {
    static let shared = PerformanceMonitoringService()

    private let logger = Logger(subsystem: "com.irrgenius.app", category: "Performance")
    private var metrics: [String: PerformanceMetric] = [:]
    private let queue = DispatchQueue(label: "performance.monitoring", qos: .utility)

    private init() {
        setupMemoryWarningObserver()
        startPeriodicReporting()
    }

    // MARK: - Performance Tracking

    func startTracking(_ operation: String) -> PerformanceTracker {
        return PerformanceTracker(operation: operation, service: self)
    }

    func recordMetric(_ operation: String, duration: TimeInterval, success: Bool = true) {
        queue.async { [weak self] in
            guard let self = self else { return }

            if self.metrics[operation] == nil {
                self.metrics[operation] = PerformanceMetric(operation: operation)
            }

            self.metrics[operation]?.addMeasurement(duration: duration, success: success)

            // Log slow operations
            if duration > 1.0 {
                self.logger.warning("Slow operation: \(operation) took \(String(format: "%.1f", duration * 1000))ms")
            }
        }
    }

    func recordError(_ operation: String, error: Error) {
        queue.async { [weak self] in
            guard let self = self else { return }

            if self.metrics[operation] == nil {
                self.metrics[operation] = PerformanceMetric(operation: operation)
            }

            self.metrics[operation]?.addError(error)
            self.logger.error("Operation failed: \(operation) - \(error.localizedDescription)")
        }
    }

    // MARK: - Memory Monitoring

    func getCurrentMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0 // MB
            let maxMemory = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0 // MB

            return MemoryUsage(
                used: usedMemory,
                available: maxMemory - usedMemory,
                total: maxMemory,
                percentage: (usedMemory / maxMemory) * 100
            )
        }

        return MemoryUsage(used: 0, available: 0, total: 0, percentage: 0)
    }

    // MARK: - App Performance Metrics

    func getAppPerformanceReport() -> AppPerformanceReport {
        let memoryUsage = getCurrentMemoryUsage()
        let launchTime = ProcessInfo.processInfo.systemUptime

        var operationMetrics: [String: OperationMetrics] = [:]

        for (operation, metric) in metrics {
            operationMetrics[operation] = OperationMetrics(
                averageDuration: metric.averageDuration,
                minDuration: metric.minDuration,
                maxDuration: metric.maxDuration,
                totalCalls: metric.totalCalls,
                successRate: metric.successRate,
                errorCount: metric.errorCount
            )
        }

        return AppPerformanceReport(
            memoryUsage: memoryUsage,
            appUptime: launchTime,
            operationMetrics: operationMetrics,
            timestamp: Date()
        )
    }

    // MARK: - Crash Detection and Reporting

    func setupCrashReporting() {
        NSSetUncaughtExceptionHandler { exception in
            PerformanceMonitoringService.shared.handleCrash(exception: exception)
        }

        signal(SIGABRT) { _ in
            PerformanceMonitoringService.shared.handleSignal(signal: "SIGABRT")
        }

        signal(SIGILL) { _ in
            PerformanceMonitoringService.shared.handleSignal(signal: "SIGILL")
        }

        signal(SIGSEGV) { _ in
            PerformanceMonitoringService.shared.handleSignal(signal: "SIGSEGV")
        }

        signal(SIGFPE) { _ in
            PerformanceMonitoringService.shared.handleSignal(signal: "SIGFPE")
        }

        signal(SIGBUS) { _ in
            PerformanceMonitoringService.shared.handleSignal(signal: "SIGBUS")
        }
    }

    private func handleCrash(exception: NSException) {
        let crashReport = CrashReport(
            type: .exception,
            name: exception.name.rawValue,
            reason: exception.reason ?? "Unknown",
            stackTrace: exception.callStackSymbols,
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: UIDevice.current.model,
            memoryUsage: getCurrentMemoryUsage()
        )

        saveCrashReport(crashReport)
        logger.fault("App crashed: \(exception.name.rawValue) - \(exception.reason ?? "Unknown")")
    }

    private func handleSignal(signal: String) {
        let crashReport = CrashReport(
            type: .signal,
            name: signal,
            reason: "Signal received",
            stackTrace: Thread.callStackSymbols,
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: UIDevice.current.model,
            memoryUsage: getCurrentMemoryUsage()
        )

        saveCrashReport(crashReport)
        logger.fault("App received signal: \(signal)")
    }

    private func saveCrashReport(_ report: CrashReport) {
        do {
            let data = try JSONEncoder().encode(report)
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let crashReportURL = documentsPath.appendingPathComponent("crash_report_\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: crashReportURL)
        } catch {
            logger.error("Failed to save crash report: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }

    private func handleMemoryWarning() {
        let memoryUsage = getCurrentMemoryUsage()
        logger.warning("Memory warning received. Current usage: \(String(format: "%.1f", memoryUsage.used))MB (\(String(format: "%.1f", memoryUsage.percentage))%)")

        // Clear caches
        CoreDataStack.shared.clearMemoryCache()
        URLCache.shared.removeAllCachedResponses()

        // Force garbage collection
        autoreleasepool {}
    }

    private func startPeriodicReporting() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.generatePeriodicReport()
        }
    }

    private func generatePeriodicReport() {
        let report = getAppPerformanceReport()

        // Log performance summary
        logger.info("Performance Report - Memory: \(String(format: "%.1f", report.memoryUsage.used))MB, Operations: \(report.operationMetrics.count)")

        // Check for performance issues
        if report.memoryUsage.percentage > 80 {
            logger.warning("High memory usage: \(String(format: "%.1f", report.memoryUsage.percentage))%")
        }

        for (operation, metrics) in report.operationMetrics {
            if metrics.averageDuration > 2.0 {
                logger.warning("Slow operation detected: \(operation) avg: \(String(format: "%.1f", metrics.averageDuration * 1000))ms")
            }

            if metrics.successRate < 0.95 {
                logger.warning("Low success rate for \(operation): \(String(format: "%.1f", metrics.successRate * 100))%")
            }
        }
    }
}

// MARK: - Performance Tracker

class PerformanceTracker {
    private let operation: String
    private let service: PerformanceMonitoringService
    private let startTime: CFAbsoluteTime

    init(operation: String, service: PerformanceMonitoringService) {
        self.operation = operation
        self.service = service
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func finish(success: Bool = true) {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        service.recordMetric(operation, duration: duration, success: success)
    }

    func finishWithError(_ error: Error) {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        service.recordMetric(operation, duration: duration, success: false)
        service.recordError(operation, error: error)
    }
}

// MARK: - Data Models

struct PerformanceMetric {
    let operation: String
    private var durations: [TimeInterval] = []
    private var errors: [Error] = []
    private var successCount: Int = 0
    private var failureCount: Int = 0

    init(operation: String) {
        self.operation = operation
    }

    mutating func addMeasurement(duration: TimeInterval, success: Bool) {
        durations.append(duration)
        if success {
            successCount += 1
        } else {
            failureCount += 1
        }

        // Keep only last 1000 measurements
        if durations.count > 1000 {
            durations.removeFirst()
        }
    }

    mutating func addError(_ error: Error) {
        errors.append(error)

        // Keep only last 100 errors
        if errors.count > 100 {
            errors.removeFirst()
        }
    }

    var averageDuration: TimeInterval {
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }

    var minDuration: TimeInterval {
        return durations.min() ?? 0
    }

    var maxDuration: TimeInterval {
        return durations.max() ?? 0
    }

    var totalCalls: Int {
        return successCount + failureCount
    }

    var successRate: Double {
        guard totalCalls > 0 else { return 0 }
        return Double(successCount) / Double(totalCalls)
    }

    var errorCount: Int {
        return errors.count
    }
}

struct MemoryUsage {
    let used: Double // MB
    let available: Double // MB
    let total: Double // MB
    let percentage: Double
}

struct OperationMetrics {
    let averageDuration: TimeInterval
    let minDuration: TimeInterval
    let maxDuration: TimeInterval
    let totalCalls: Int
    let successRate: Double
    let errorCount: Int
}

struct AppPerformanceReport {
    let memoryUsage: MemoryUsage
    let appUptime: TimeInterval
    let operationMetrics: [String: OperationMetrics]
    let timestamp: Date
}

struct CrashReport: Codable {
    enum CrashType: String, Codable {
        case exception
        case signal
    }

    let type: CrashType
    let name: String
    let reason: String
    let stackTrace: [String]
    let timestamp: Date
    let appVersion: String
    let osVersion: String
    let deviceModel: String
    let memoryUsage: MemoryUsage
}

extension MemoryUsage: Codable {}

// MARK: - Usage Example

extension PerformanceMonitoringService {
    func trackOperation<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let tracker = startTracking(operation)
        do {
            let result = try block()
            tracker.finish(success: true)
            return result
        } catch {
            tracker.finishWithError(error)
            throw error
        }
    }

    func trackAsyncOperation<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let tracker = startTracking(operation)
        do {
            let result = try await block()
            tracker.finish(success: true)
            return result
        } catch {
            tracker.finishWithError(error)
            throw error
        }
    }
}
