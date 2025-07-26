//
//  CloudKitSyncSettingsView.swift
//  IRR Genius
//
//  CloudKit sync settings and management UI
//

import SwiftUI
import CloudKit

struct CloudKitSyncSettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingConflictResolution = false
    @State private var selectedConflict: SyncConflict?
    @State private var showingSyncError = false
    @State private var syncErrorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // CloudKit Status Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "icloud")
                        .foregroundColor(dataManager.isCloudKitEnabled ? .blue : .gray)
                    Text("iCloud Sync")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { dataManager.isCloudKitEnabled },
                        set: { enabled in
                            Task {
                                if enabled {
                                    await dataManager.enableCloudKitSync()
                                } else {
                                    await dataManager.disableCloudKitSync()
                                }
                            }
                        }
                    ))
                }
                
                if dataManager.isCloudKitEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        // Sync Status
                        HStack {
                            Image(systemName: syncStatusIcon)
                                .foregroundColor(syncStatusColor)
                            Text(syncStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        // Last Sync Date
                        if let lastSync = dataManager.lastSyncDate {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text("Last sync: \(lastSync, formatter: syncDateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        
                        // Sync Progress
                        if dataManager.isSyncing {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Syncing...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(dataManager.syncProgress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                ProgressView(value: dataManager.syncProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                            }
                        }
                    }
                    .padding(.leading, 24)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Manual Sync Button
            if dataManager.isCloudKitEnabled {
                Button(action: {
                    Task {
                        await dataManager.manualSync()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync Now")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(dataManager.isSyncing)
            }
            
            // Conflict Resolution Section
            if !dataManager.pendingConflicts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Sync Conflicts")
                            .font(.headline)
                        Spacer()
                        Text("\(dataManager.pendingConflicts.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Text("Some calculations have conflicting changes that need to be resolved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Resolve Conflicts") {
                        showingConflictResolution = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            // CloudKit Information
            VStack(alignment: .leading, spacing: 8) {
                Text("About iCloud Sync")
                    .font(.headline)
                
                Text("When enabled, your calculations and projects are automatically synchronized across all your devices using iCloud. Your data is encrypted and stored securely in your personal iCloud account.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !dataManager.isCloudKitEnabled {
                    Text("• Requires iCloud account\n• Uses your iCloud storage quota\n• Automatic sync every 5 minutes\n• Offline-first with conflict resolution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingConflictResolution) {
            ConflictResolutionView(conflicts: dataManager.pendingConflicts) { conflict, resolution in
                Task {
                    await dataManager.resolveSyncConflict(conflict, resolution: resolution)
                }
            }
        }
        .alert("Sync Error", isPresented: $showingSyncError) {
            Button("OK") { }
        } message: {
            Text(syncErrorMessage)
        }
        .onReceive(dataManager.$syncStatus) { status in
            if case .error(let error) = status {
                syncErrorMessage = error.localizedDescription
                showingSyncError = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var syncStatusIcon: String {
        switch dataManager.syncStatus {
        case .idle:
            return "checkmark.circle"
        case .syncing:
            return "arrow.clockwise"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var syncStatusColor: Color {
        switch dataManager.syncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
    
    private var syncStatusText: String {
        switch dataManager.syncStatus {
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .success(let date):
            return "Last synced \(date, formatter: relativeDateFormatter)"
        case .error(let error):
            return "Sync failed: \(error.localizedDescription)"
        }
    }
    
    private var syncDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

// MARK: - Conflict Resolution View

struct ConflictResolutionView: View {
    let conflicts: [SyncConflict]
    let onResolve: (SyncConflict, ConflictResolution) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(conflicts, id: \.localRecord.id) { conflict in
                ConflictRowView(conflict: conflict, onResolve: onResolve)
            }
            .navigationTitle("Resolve Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Conflict Row View

struct ConflictRowView: View {
    let conflict: SyncConflict
    let onResolve: (SyncConflict, ConflictResolution) -> Void
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Conflict Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conflict.localRecord.name)
                        .font(.headline)
                    Text(conflict.localRecord.calculationType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Details") {
                    showingDetails = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Conflict Description
            Text(conflictDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Resolution Buttons
            HStack(spacing: 12) {
                Button("Use Local") {
                    onResolve(conflict, .useLocal)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Use Remote") {
                    onResolve(conflict, .useRemote)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Merge") {
                    onResolve(conflict, .merge)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingDetails) {
            ConflictDetailsView(conflict: conflict)
        }
    }
    
    private var conflictDescription: String {
        switch conflict.conflictType {
        case .modificationDate:
            return "Both local and remote versions were modified at the same time."
        case .dataConflict(let fields):
            return "Conflicting data in: \(fields.joined(separator: ", "))"
        }
    }
}

// MARK: - Conflict Details View

struct ConflictDetailsView: View {
    let conflict: SyncConflict
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Local Version
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Local Version")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        CalculationDetailsView(calculation: conflict.localRecord)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Remote Version
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Remote Version")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        CalculationDetailsView(calculation: conflict.remoteRecord)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Conflict Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Calculation Details View

struct CalculationDetailsView: View {
    let calculation: SavedCalculation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailRow(label: "Name", value: calculation.name)
            DetailRow(label: "Type", value: calculation.calculationType.displayName)
            DetailRow(label: "Modified", value: calculation.modifiedDate, formatter: dateFormatter)
            
            if let initialInvestment = calculation.initialInvestment {
                DetailRow(label: "Initial Investment", value: initialInvestment, formatter: currencyFormatter)
            }
            
            if let outcomeAmount = calculation.outcomeAmount {
                DetailRow(label: "Outcome Amount", value: outcomeAmount, formatter: currencyFormatter)
            }
            
            if let timeInMonths = calculation.timeInMonths {
                DetailRow(label: "Time (Months)", value: timeInMonths, formatter: numberFormatter)
            }
            
            if let irr = calculation.irr {
                DetailRow(label: "IRR", value: irr, formatter: percentFormatter)
            }
            
            if let result = calculation.calculatedResult {
                DetailRow(label: "Result", value: result, formatter: resultFormatter)
            }
            
            if let notes = calculation.notes, !notes.isEmpty {
                DetailRow(label: "Notes", value: notes)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private var percentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private var resultFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

// MARK: - Detail Row View

struct DetailRow: View {
    let label: String
    let value: String
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    init<T>(label: String, value: T, formatter: NumberFormatter) where T: Numeric {
        self.label = label
        self.value = formatter.string(from: NSNumber(value: Double(exactly: value) ?? 0)) ?? "\(value)"
    }
    
    init(label: String, value: Date, formatter: DateFormatter) {
        self.label = label
        self.value = formatter.string(from: value)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }
}

// MARK: - Preview

struct CloudKitSyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CloudKitSyncSettingsView()
                .environmentObject(DataManager())
        }
    }
}