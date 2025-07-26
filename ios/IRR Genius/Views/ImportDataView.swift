//
//  ImportDataView.swift
//  IRR Genius
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ImportDataViewModel()
    
    @State private var showingFilePicker = false
    @State private var showingColumnMapping = false
    @State private var showingValidationResults = false
    @State private var showingImportConfirmation = false
    
    let onImportComplete: ([SavedCalculation]) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // File Selection Section
                    fileSelectionSection
                    
                    // Calculation Type Selection
                    calculationTypeSection
                    
                    // Import Progress
                    if viewModel.isProcessing {
                        progressSection
                    }
                    
                    // Error Display
                    if let error = viewModel.errorMessage {
                        errorSection(error)
                    }
                    
                    // Import Summary
                    if let result = viewModel.importResult {
                        importSummarySection(result)
                    }
                }
                .padding()
            }
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: viewModel.allowedFileTypes,
            allowsMultipleSelection: false
        ) { result in
            Task {
                await viewModel.handleFileSelection(result)
                if viewModel.importResult != nil {
                    showingColumnMapping = true
                }
            }
        }
        .sheet(isPresented: $showingColumnMapping) {
            ColumnMappingView(
                importResult: viewModel.importResult,
                currentMapping: viewModel.columnMapping,
                onMappingChanged: viewModel.updateColumnMapping,
                onConfirm: {
                    showingColumnMapping = false
                    Task {
                        await viewModel.validateData()
                        showingValidationResults = true
                    }
                }
            )
        }
        .sheet(isPresented: $showingValidationResults) {
            ValidationResultsView(
                validationResult: viewModel.validationResult,
                onConfirm: {
                    showingValidationResults = false
                    showingImportConfirmation = true
                }
            )
        }
        .alert("Confirm Import", isPresented: $showingImportConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Import") {
                if let calculations = viewModel.validationResult?.validCalculations {
                    onImportComplete(calculations)
                    dismiss()
                }
            }
        } message: {
            if let result = viewModel.validationResult {
                Text("Ready to import \(result.validRows) calculations.\(result.validationErrors.isEmpty ? "" : "\n\(result.validationErrors.count) rows will be skipped due to errors.")")
            }
        }
    }
    
    // MARK: - View Components
    
    private var fileSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select File to Import")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Choose a CSV or Excel file containing your calculation data")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.setFileType(.csv)
                    showingFilePicker = true
                }) {
                    Label("CSV File", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    viewModel.setFileType(.excel)
                    showingFilePicker = true
                }) {
                    Label("Excel File", systemImage: "tablecells")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var calculationTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calculation Type")
                .font(.headline)
                .fontWeight(.bold)
            
            Picker("Calculation Type", selection: $viewModel.selectedCalculationType) {
                ForEach(CalculationMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Processing file...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error)
                .font(.subheadline)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func importSummarySection(_ result: ImportResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Summary")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                Text("Columns: \(result.headers.count)")
                Spacer()
                Text("Rows: \(result.rows.count)")
            }
            .font(.subheadline)
            
            Text("Detected Format: \(formatDescription(result.detectedFormat))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button("Edit Mapping") {
                    showingColumnMapping = true
                }
                .buttonStyle(.bordered)
                
                Button("Validate") {
                    Task {
                        await viewModel.validateData()
                        showingValidationResults = true
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDescription(_ format: ImportFormat) -> String {
        switch format {
        case .csv(let delimiter, _):
            return "CSV (delimiter: '\(delimiter)')"
        case .excel(let sheetName, _):
            return "Excel (sheet: \(sheetName))"
        }
    }
}

// MARK: - Column Mapping View

struct ColumnMappingView: View {
    let importResult: ImportResult?
    @State var currentMapping: [String: CalculationField]
    let onMappingChanged: (String, CalculationField?) -> Void
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if let result = importResult {
                    ForEach(result.headers, id: \.self) { header in
                        ColumnMappingRow(
                            columnName: header,
                            selectedField: currentMapping[header],
                            onFieldSelected: { field in
                                onMappingChanged(header, field)
                                if field != nil {
                                    currentMapping[header] = field!
                                } else {
                                    currentMapping.removeValue(forKey: header)
                                }
                            }
                        )
                    }
                }
            }
            .navigationTitle("Map Columns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        onConfirm()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ColumnMappingRow: View {
    let columnName: String
    let selectedField: CalculationField?
    let onFieldSelected: (CalculationField?) -> Void
    
    var body: some View {
        HStack {
            Text(columnName)
                .font(.subheadline)
            
            Spacer()
            
            Menu {
                Button("Not mapped") {
                    onFieldSelected(nil)
                }
                
                ForEach(CalculationField.allCases, id: \.self) { field in
                    Button(field.displayName) {
                        onFieldSelected(field)
                    }
                }
            } label: {
                Text(selectedField?.displayName ?? "Not mapped")
                    .foregroundColor(selectedField != nil ? .primary : .secondary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Validation Results View

struct ValidationResultsView: View {
    let validationResult: ValidationResult?
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let result = validationResult {
                        // Summary
                        VStack(spacing: 8) {
                            Text("Valid: \(result.validRows)/\(result.totalRows) rows")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text("Success Rate: \(Int(result.successRate * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(result.hasErrors ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Errors
                        if !result.validationErrors.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Errors:")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                ForEach(Array(result.validationErrors.enumerated()), id: \.offset) { _, error in
                                    ValidationErrorRow(error: error)
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                
                                Text("All data is valid!")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Validation Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") {
                        onConfirm()
                        dismiss()
                    }
                    .disabled(validationResult?.validRows == 0)
                }
            }
        }
    }
}

struct ValidationErrorRow: View {
    let error: ValidationError
    
    var body: some View {
        HStack {
            Image(systemName: error.severity == .error ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                .foregroundColor(error.severity == .error ? .red : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Row \(error.row)\(error.column.map { ", Column \($0)" } ?? "")")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(error.message)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding(8)
        .background(error.severity == .error ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - View Model

@MainActor
class ImportDataViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var selectedCalculationType: CalculationMode = .calculateIRR
    @Published var fileType: ImportFileType?
    @Published var importResult: ImportResult?
    @Published var columnMapping: [String: CalculationField] = [:]
    @Published var validationResult: ValidationResult?
    
    private let csvImportService = CSVImportService()
    private let excelImportService = ExcelImportService()
    
    var allowedFileTypes: [UTType] {
        switch fileType {
        case .csv:
            return [.commaSeparatedText, .text]
        case .excel:
            return [.spreadsheet]
        case .none:
            return [.commaSeparatedText, .text, .spreadsheet]
        }
    }
    
    func setFileType(_ type: ImportFileType) {
        fileType = type
        clearError()
    }
    
    func setError(_ message: String) {
        errorMessage = message
        isProcessing = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                await processFile(url)
            }
            
        case .failure(let error):
            setError("File selection failed: \(error.localizedDescription)")
        }
    }
    
    func processFile(_ url: URL) async {
        isProcessing = true
        clearError()
        
        do {
            let result: ImportResult
            
            switch fileType {
            case .csv:
                result = try await csvImportService.importCSV(from: url)
            case .excel:
                result = try await excelImportService.importExcel(from: url)
            case .none:
                throw ImportError.unsupportedFormat
            }
            
            importResult = result
            columnMapping = result.suggestedMapping
            
        } catch {
            setError("Failed to process file: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    func updateColumnMapping(_ columnName: String, _ field: CalculationField?) {
        if let field = field {
            columnMapping[columnName] = field
        } else {
            columnMapping.removeValue(forKey: columnName)
        }
    }
    
    func validateData() async {
        guard let result = importResult else { return }
        
        isProcessing = true
        clearError()
        
        do {
            let validation: ValidationResult
            
            switch fileType {
            case .csv:
                validation = try await csvImportService.validateAndConvert(
                    importResult: result,
                    columnMapping: columnMapping,
                    calculationType: selectedCalculationType
                )
            case .excel:
                validation = try await excelImportService.validateAndConvert(
                    importResult: result,
                    columnMapping: columnMapping,
                    calculationType: selectedCalculationType
                )
            case .none:
                throw ImportError.unsupportedFormat
            }
            
            validationResult = validation
            
        } catch {
            setError("Validation failed: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
}

enum ImportFileType {
    case csv
    case excel
}