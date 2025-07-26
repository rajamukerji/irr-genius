//
//  DataManager.swift
//  IRR Genius
//
//  Auto-save and data management functionality
//

import Foundation
import SwiftUI
import Combine
import UIKit

// MARK: - Auto-Save Configuration
struct AutoSaveConfiguration {
    let isEnabled: Bool
    let saveDelay: TimeInterval // Delay after calculation before auto-save
    let draftSaveInterval: TimeInterval // Interval for saving drafts
    let showSaveDialog: Bool // Whether to show save dialog after calculation
    
    static let `default` = AutoSaveConfiguration(
        isEnabled: true,
        saveDelay: 1.0,
        draftSaveInterval: 30.0,
        showSaveDialog: true
    )
}

// MARK: - Save Dialog Data
struct SaveDialogData {
    var name: String = ""
    var projectId: UUID? = nil
    var notes: String = ""
    var tags: [String] = []
    var isVisible: Bool = false
    var calculationToSave: SavedCalculation? = nil
}

// MARK: - Unsaved Changes Detection
struct UnsavedChanges {
    let hasChanges: Bool
    let lastModified: Date
    let changeDescription: String
    
    static let none = UnsavedChanges(hasChanges: false, lastModified: Date(), changeDescription: "")
}

// MARK: - Data Manager
@MainActor
class DataManager: ObservableObject {
    // MARK: - Published Properties
    @Published var calculations: [SavedCalculation] = []
    @Published var projects: [Project] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var saveDialogData = SaveDialogData()
    @Published var unsavedChanges = UnsavedChanges.none
    @Published var autoSaveConfiguration = AutoSaveConfiguration.default
    @Published var loadingState: LoadingState = .idle
    @Published var syncProgress: Double = 0.0
    @Published var isSyncing: Bool = false
    
    // MARK: - Private Properties
    private let repositoryManager: RepositoryManager
    private var autoSaveTimer: Timer?
    private var draftSaveTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastCalculationInputs: [String: Any] = [:]
    private var pendingCalculation: SavedCalculation?
    
    // MARK: - Initialization
    init(repositoryManager: RepositoryManager = RepositoryManager()) {
        self.repositoryManager = repositoryManager
        setupAutoSave()
        loadInitialData()
    }
    
    // MARK: - Auto-Save Setup
    private func setupAutoSave() {
        // Setup draft save timer
        if autoSaveConfiguration.isEnabled {
            startDraftSaveTimer()
        }
    }
    
    private func startDraftSaveTimer() {
        draftSaveTimer?.invalidate()
        draftSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveConfiguration.draftSaveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.saveDraftIfNeeded()
            }
        }
    }
    
    private func stopDraftSaveTimer() {
        draftSaveTimer?.invalidate()
        draftSaveTimer = nil
    }
    
    // MARK: - Data Loading
    private func loadInitialData() {
        Task {
            await loadCalculations()
            await loadProjects()
        }
    }
    
    func loadCalculations() async {
        loadingState = .loading(message: "Loading calculations...")
        errorMessage = nil
        
        let result = await repositoryManager.calculationRepository.loadCalculationsSafely()
        
        switch result {
        case .success(let loadedCalculations):
            calculations = loadedCalculations.sorted { $0.modifiedDate > $1.modifiedDate }
            loadingState = .idle
        case .failure(let error):
            errorMessage = error.localizedDescription
            loadingState = .error(message: error.localizedDescription)
        }
    }
    
    func loadProjects() async {
        let result = await repositoryManager.projectRepository.loadProjectsSafely()
        
        switch result {
        case .success(let loadedProjects):
            projects = loadedProjects.sorted { $0.modifiedDate > $1.modifiedDate }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Auto-Save Functionality
    
    /// Called after a successful calculation to trigger auto-save
    func handleCalculationCompleted(
        calculationType: CalculationMode,
        inputs: [String: Any],
        result: Double,
        growthPoints: [GrowthPoint]?
    ) {
        // Stop any existing auto-save timer
        autoSaveTimer?.invalidate()
        
        // Create calculation object
        let calculation = createCalculationFromInputs(
            calculationType: calculationType,
            inputs: inputs,
            result: result,
            growthPoints: growthPoints
        )
        
        guard let calculation = calculation else {
            errorMessage = "Failed to create calculation from inputs"
            return
        }
        
        pendingCalculation = calculation
        
        if autoSaveConfiguration.isEnabled {
            if autoSaveConfiguration.showSaveDialog {
                // Show save dialog after delay
                autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveConfiguration.saveDelay, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.showSaveDialog(for: calculation)
                    }
                }
            } else {
                // Auto-save without dialog
                autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveConfiguration.saveDelay, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        await self?.autoSaveCalculation(calculation)
                    }
                }
            }
        }
    }
    
    /// Shows save dialog for the calculation
    private func showSaveDialog(for calculation: SavedCalculation) {
        saveDialogData = SaveDialogData(
            name: generateDefaultName(for: calculation),
            projectId: nil,
            notes: "",
            tags: [],
            isVisible: true,
            calculationToSave: calculation
        )
    }
    
    /// Auto-saves calculation without user interaction
    private func autoSaveCalculation(_ calculation: SavedCalculation) async {
        let namedCalculation = try! SavedCalculation(
            id: calculation.id,
            name: generateDefaultName(for: calculation),
            calculationType: calculation.calculationType,
            createdDate: calculation.createdDate,
            modifiedDate: Date(),
            projectId: nil,
            initialInvestment: calculation.initialInvestment,
            outcomeAmount: calculation.outcomeAmount,
            timeInMonths: calculation.timeInMonths,
            irr: calculation.irr,
            followOnInvestments: calculation.followOnInvestments,
            unitPrice: calculation.unitPrice,
            successRate: calculation.successRate,
            outcomePerUnit: calculation.outcomePerUnit,
            investorShare: calculation.investorShare,
            feePercentage: calculation.feePercentage,
            calculatedResult: calculation.calculatedResult,
            growthPoints: calculation.growthPoints,
            notes: "Auto-saved calculation",
            tags: ["auto-saved"]
        )
        
        await saveCalculation(namedCalculation)
    }
    
    /// Generates a default name for a calculation
    private func generateDefaultName(for calculation: SavedCalculation) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let typeString = calculation.calculationType.displayName
        let dateString = formatter.string(from: calculation.createdDate)
        
        return "\(typeString) - \(dateString)"
    }
    
    // MARK: - Save Dialog Actions
    
    /// Saves calculation from save dialog
    func saveFromDialog() async {
        guard let calculation = saveDialogData.calculationToSave else { return }
        
        let namedCalculation = try! SavedCalculation(
            id: calculation.id,
            name: saveDialogData.name.isEmpty ? generateDefaultName(for: calculation) : saveDialogData.name,
            calculationType: calculation.calculationType,
            createdDate: calculation.createdDate,
            modifiedDate: Date(),
            projectId: saveDialogData.projectId,
            initialInvestment: calculation.initialInvestment,
            outcomeAmount: calculation.outcomeAmount,
            timeInMonths: calculation.timeInMonths,
            irr: calculation.irr,
            followOnInvestments: calculation.followOnInvestments,
            unitPrice: calculation.unitPrice,
            successRate: calculation.successRate,
            outcomePerUnit: calculation.outcomePerUnit,
            investorShare: calculation.investorShare,
            feePercentage: calculation.feePercentage,
            calculatedResult: calculation.calculatedResult,
            growthPoints: calculation.growthPoints,
            notes: saveDialogData.notes.isEmpty ? nil : saveDialogData.notes,
            tags: saveDialogData.tags
        )
        
        await saveCalculation(namedCalculation)
        dismissSaveDialog()
    }
    
    /// Dismisses save dialog
    func dismissSaveDialog() {
        saveDialogData = SaveDialogData()
        pendingCalculation = nil
    }
    
    // MARK: - Unsaved Changes Detection
    
    /// Updates input tracking for unsaved changes detection
    func updateInputs(_ inputs: [String: Any]) {
        let hasChanges = !inputs.isEmpty && inputs != lastCalculationInputs
        
        if hasChanges {
            unsavedChanges = UnsavedChanges(
                hasChanges: true,
                lastModified: Date(),
                changeDescription: "Calculation inputs modified"
            )
        } else {
            unsavedChanges = UnsavedChanges.none
        }
        
        lastCalculationInputs = inputs
    }
    
    /// Clears unsaved changes (called after save or calculation)
    func clearUnsavedChanges() {
        unsavedChanges = UnsavedChanges.none
        lastCalculationInputs = [:]
    }
    
    /// Shows warning for unsaved changes
    func showUnsavedChangesWarning() -> Bool {
        return unsavedChanges.hasChanges
    }
    
    // MARK: - Draft Saving
    
    /// Saves draft calculation if there are unsaved changes
    private func saveDraftIfNeeded() async {
        guard unsavedChanges.hasChanges,
              !lastCalculationInputs.isEmpty else { return }
        
        // Create draft calculation from current inputs
        if let draftCalculation = createDraftCalculation() {
            await saveDraftCalculation(draftCalculation)
        }
    }
    
    /// Creates a draft calculation from current inputs
    private func createDraftCalculation() -> SavedCalculation? {
        // This would need to be called with current form state
        // For now, return nil as we need form state from the view
        return nil
    }
    
    /// Saves a draft calculation
    private func saveDraftCalculation(_ calculation: SavedCalculation) async {
        let draftCalculation = try! SavedCalculation(
            id: calculation.id,
            name: "[DRAFT] \(calculation.name)",
            calculationType: calculation.calculationType,
            createdDate: calculation.createdDate,
            modifiedDate: Date(),
            projectId: calculation.projectId,
            initialInvestment: calculation.initialInvestment,
            outcomeAmount: calculation.outcomeAmount,
            timeInMonths: calculation.timeInMonths,
            irr: calculation.irr,
            followOnInvestments: calculation.followOnInvestments,
            unitPrice: calculation.unitPrice,
            successRate: calculation.successRate,
            outcomePerUnit: calculation.outcomePerUnit,
            investorShare: calculation.investorShare,
            feePercentage: calculation.feePercentage,
            calculatedResult: calculation.calculatedResult,
            growthPoints: calculation.growthPoints,
            notes: "Draft saved automatically",
            tags: ["draft", "auto-saved"]
        )
        
        await saveCalculation(draftCalculation)
    }
    
    // MARK: - Calculation Management
    
    /// Saves a calculation
    func saveCalculation(_ calculation: SavedCalculation) async {
        let result = await repositoryManager.calculationRepository.saveCalculationSafely(calculation)
        
        switch result {
        case .success:
            // Update local array
            if let index = calculations.firstIndex(where: { $0.id == calculation.id }) {
                calculations[index] = calculation
            } else {
                calculations.insert(calculation, at: 0)
            }
            clearUnsavedChanges()
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    /// Deletes a calculation
    func deleteCalculation(_ calculation: SavedCalculation) async {
        do {
            try await repositoryManager.calculationRepository.deleteCalculation(id: calculation.id)
            calculations.removeAll { $0.id == calculation.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Loads a specific calculation
    func loadCalculation(id: UUID) async -> SavedCalculation? {
        do {
            return try await repositoryManager.calculationRepository.loadCalculation(id: id)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Project Management
    
    /// Saves a project
    func saveProject(_ project: Project) async {
        let result = await repositoryManager.projectRepository.saveProjectSafely(project)
        
        switch result {
        case .success:
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index] = project
            } else {
                projects.insert(project, at: 0)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    /// Deletes a project
    func deleteProject(_ project: Project) async {
        do {
            try await repositoryManager.projectRepository.deleteProject(id: project.id)
            projects.removeAll { $0.id == project.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates a SavedCalculation from calculation inputs and results
    private func createCalculationFromInputs(
        calculationType: CalculationMode,
        inputs: [String: Any],
        result: Double,
        growthPoints: [GrowthPoint]?
    ) -> SavedCalculation? {
        
        do {
            switch calculationType {
            case .calculateIRR:
                return try SavedCalculation(
                    name: "Untitled IRR Calculation",
                    calculationType: calculationType,
                    initialInvestment: inputs["Initial Investment"] as? Double,
                    outcomeAmount: inputs["Outcome Amount"] as? Double,
                    timeInMonths: inputs["Time Period (Months)"] as? Double,
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
                
            case .calculateOutcome:
                return try SavedCalculation(
                    name: "Untitled Outcome Calculation",
                    calculationType: calculationType,
                    initialInvestment: inputs["Initial Investment"] as? Double,
                    irr: inputs["IRR"] as? Double,
                    timeInMonths: inputs["Time Period (Months)"] as? Double,
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
                
            case .calculateInitial:
                return try SavedCalculation(
                    name: "Untitled Initial Investment Calculation",
                    calculationType: calculationType,
                    outcomeAmount: inputs["Outcome Amount"] as? Double,
                    irr: inputs["IRR"] as? Double,
                    timeInMonths: inputs["Time Period (Months)"] as? Double,
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
                
            case .calculateBlendedIRR:
                return try SavedCalculation(
                    name: "Untitled Blended IRR Calculation",
                    calculationType: calculationType,
                    initialInvestment: inputs["Initial Investment"] as? Double,
                    outcomeAmount: inputs["Final Valuation"] as? Double,
                    timeInMonths: inputs["Time Period (Months)"] as? Double,
                    followOnInvestments: inputs["Follow-on Investments"] as? [FollowOnInvestment],
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
                
            case .portfolioUnitInvestment:
                return try SavedCalculation(
                    name: "Untitled Portfolio Unit Investment",
                    calculationType: calculationType,
                    initialInvestment: inputs["Initial Investment"] as? Double,
                    timeInMonths: inputs["Time Period (Months)"] as? Double,
                    unitPrice: inputs["Unit Price"] as? Double,
                    successRate: inputs["Success Rate (%)"] as? Double,
                    followOnInvestments: inputs["Follow-on Investments"] as? [FollowOnInvestment],
                    calculatedResult: result,
                    growthPoints: growthPoints
                )
            }
        } catch {
            print("Failed to create calculation: \(error)")
            return nil
        }
    }
    
    // MARK: - Export and Sharing
    
    /// Exports a calculation to PDF and shows share sheet
    func exportCalculation(_ calculation: SavedCalculation) {
        Task {
            await exportCalculationToPDF(calculation)
        }
    }
    
    /// Exports multiple calculations to PDF and shows share sheet
    func exportCalculations(_ calculations: [SavedCalculation]) {
        Task {
            await exportMultipleCalculationsToPDF(calculations)
        }
    }
    
    /// Exports calculation to CSV and shows share sheet
    func exportCalculationToCSV(_ calculation: SavedCalculation) {
        Task {
            await exportCalculationAsCSV(calculation)
        }
    }
    
    /// Exports multiple calculations to CSV and shows share sheet
    func exportCalculationsToCSV(_ calculations: [SavedCalculation]) {
        Task {
            await exportMultipleCalculationsAsCSV(calculations)
        }
    }
    
    /// Exports calculation to PDF with progress indicator
    @MainActor
    private func exportCalculationToPDF(_ calculation: SavedCalculation) async {
        loadingState = .loading(message: "Generating PDF...")
        errorMessage = nil
        
        do {
            let pdfExportService = PDFExportServiceImpl()
            let fileURL = try await pdfExportService.exportToPDF(calculation)
            
            loadingState = .success(message: "PDF generated successfully!")
            
            // Show share sheet
            await showShareSheet(for: [fileURL], subject: "IRR Calculation: \(calculation.name)")
            
            // Reset to idle after a brief success display
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.loadingState = .idle
            }
            
        } catch {
            errorMessage = "Failed to export calculation: \(error.localizedDescription)"
            loadingState = .error(message: error.localizedDescription)
        }
    }
    
    /// Exports multiple calculations to PDF with progress indicator
    @MainActor
    private func exportMultipleCalculationsToPDF(_ calculations: [SavedCalculation]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let pdfExportService = PDFExportServiceImpl()
            let fileURL = try await pdfExportService.exportMultipleCalculationsToPDF(calculations)
            
            // Show share sheet
            await showShareSheet(for: [fileURL], subject: "IRR Calculations Export")
            
        } catch {
            errorMessage = "Failed to export calculations: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Shows iOS share sheet for files
    @MainActor
    private func showShareSheet(for fileURLs: [URL], subject: String) async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            errorMessage = "Unable to present share sheet"
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: fileURLs,
            applicationActivities: nil
        )
        
        activityViewController.setValue(subject, forKey: "subject")
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present the share sheet
        await withCheckedContinuation { continuation in
            activityViewController.completionWithItemsHandler = { _, completed, _, error in
                if let error = error {
                    Task { @MainActor in
                        self.errorMessage = "Sharing failed: \(error.localizedDescription)"
                    }
                }
                
                // Clean up temporary files after sharing
                Task {
                    await self.cleanupTemporaryFiles(fileURLs)
                }
                
                continuation.resume()
            }
            
            rootViewController.present(activityViewController, animated: true)
        }
    }
    
    /// Exports calculation to CSV with progress indicator
    @MainActor
    private func exportCalculationAsCSV(_ calculation: SavedCalculation) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let csvExportService = CSVExcelExportServiceImpl()
            let fileURL = try await csvExportService.exportCalculationToCSV(calculation)
            
            // Show share sheet
            await showShareSheet(for: [fileURL], subject: "IRR Calculation Data: \(calculation.name)")
            
        } catch {
            errorMessage = "Failed to export calculation to CSV: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Exports multiple calculations to CSV with progress indicator
    @MainActor
    private func exportMultipleCalculationsAsCSV(_ calculations: [SavedCalculation]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let csvExportService = CSVExcelExportServiceImpl()
            let fileURL = try await csvExportService.exportToCSV(calculations)
            
            // Show share sheet
            await showShareSheet(for: [fileURL], subject: "IRR Calculations Data Export")
            
        } catch {
            errorMessage = "Failed to export calculations to CSV: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Cleans up temporary files after sharing
    private func cleanupTemporaryFiles(_ fileURLs: [URL]) async {
        for fileURL in fileURLs {
            do {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
            } catch {
                print("Failed to cleanup temporary file: \(error)")
            }
        }
    }
    
    // MARK: - Calculation Loading and Editing
    
    /// Loads a calculation and populates form fields
    func loadCalculationForEditing(_ calculation: SavedCalculation) {
        // This will be handled by the view layer to populate form fields
        // The DataManager provides the calculation data
    }
    
    /// Duplicates a calculation for scenario analysis
    func duplicateCalculation(_ calculation: SavedCalculation) async {
        do {
            let duplicatedCalculation = try SavedCalculation(
                name: "\(calculation.name) (Copy)",
                calculationType: calculation.calculationType,
                projectId: calculation.projectId,
                initialInvestment: calculation.initialInvestment,
                outcomeAmount: calculation.outcomeAmount,
                timeInMonths: calculation.timeInMonths,
                irr: calculation.irr,
                followOnInvestments: calculation.followOnInvestments,
                unitPrice: calculation.unitPrice,
                successRate: calculation.successRate,
                outcomePerUnit: calculation.outcomePerUnit,
                investorShare: calculation.investorShare,
                feePercentage: calculation.feePercentage,
                calculatedResult: calculation.calculatedResult,
                growthPoints: calculation.growthPoints,
                notes: calculation.notes,
                tags: calculation.tags
            )
            
            await saveCalculation(duplicatedCalculation)
        } catch {
            errorMessage = "Failed to duplicate calculation: \(error.localizedDescription)"
        }
    }
    
    /// Gets calculation history (versions of the same calculation)
    func getCalculationHistory(for calculation: SavedCalculation) async -> [SavedCalculation] {
        // For now, return calculations with similar names (indicating versions)
        let baseName = calculation.name.replacingOccurrences(of: " (Copy)", with: "")
            .replacingOccurrences(of: " - v\\d+", with: "", options: .regularExpression)
        
        return calculations.filter { calc in
            calc.id != calculation.id &&
            calc.calculationType == calculation.calculationType &&
            (calc.name.contains(baseName) || calc.name.hasPrefix(baseName))
        }.sorted { $0.modifiedDate > $1.modifiedDate }
    }
    
    /// Creates a new version of a calculation
    func createCalculationVersion(_ calculation: SavedCalculation, withName name: String) async {
        do {
            let versionedCalculation = try SavedCalculation(
                name: name,
                calculationType: calculation.calculationType,
                projectId: calculation.projectId,
                initialInvestment: calculation.initialInvestment,
                outcomeAmount: calculation.outcomeAmount,
                timeInMonths: calculation.timeInMonths,
                irr: calculation.irr,
                followOnInvestments: calculation.followOnInvestments,
                unitPrice: calculation.unitPrice,
                successRate: calculation.successRate,
                outcomePerUnit: calculation.outcomePerUnit,
                investorShare: calculation.investorShare,
                feePercentage: calculation.feePercentage,
                calculatedResult: calculation.calculatedResult,
                growthPoints: calculation.growthPoints,
                notes: calculation.notes,
                tags: calculation.tags + ["version"]
            )
            
            await saveCalculation(versionedCalculation)
        } catch {
            errorMessage = "Failed to create calculation version: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Configuration
    
    /// Updates auto-save configuration
    func updateAutoSaveConfiguration(_ config: AutoSaveConfiguration) {
        autoSaveConfiguration = config
        
        if config.isEnabled {
            startDraftSaveTimer()
        } else {
            stopDraftSaveTimer()
        }
    }
    
    // MARK: - Cleanup
    deinit {
        autoSaveTimer?.invalidate()
        draftSaveTimer?.invalidate()
    }
}

// MARK: - CalculationMode Extension
extension CalculationMode {
    var displayName: String {
        switch self {
        case .calculateIRR:
            return "IRR Calculation"
        case .calculateOutcome:
            return "Outcome Calculation"
        case .calculateInitial:
            return "Initial Investment Calculation"
        case .calculateBlendedIRR:
            return "Blended IRR Calculation"
        case .portfolioUnitInvestment:
            return "Portfolio Unit Investment"
        }
    }
}