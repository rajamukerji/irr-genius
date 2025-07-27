//
//  SettingsView.swift
//  IRR Genius
//
//  Created by Kiro on 7/24/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAbout = false
    @State private var showingCloudKitSettings = false
    @State private var showingClearDataAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data Management")) {
                    // CloudKit Sync Settings
                    NavigationLink(destination: CloudKitSyncSettingsView()) {
                        HStack {
                            Image(systemName: "icloud")
                                .foregroundColor(dataManager.isCloudKitEnabled ? .blue : .gray)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("iCloud Sync")
                                if dataManager.isCloudKitEnabled {
                                    Text("Enabled")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Disabled")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if dataManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if !dataManager.pendingConflicts.isEmpty {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    // Auto-Save Settings
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Toggle("Auto-Save Calculations", isOn: Binding(
                                get: { dataManager.autoSaveConfiguration.isEnabled },
                                set: { enabled in
                                    var config = dataManager.autoSaveConfiguration
                                    config = AutoSaveConfiguration(
                                        isEnabled: enabled,
                                        saveDelay: config.saveDelay,
                                        draftSaveInterval: config.draftSaveInterval,
                                        showSaveDialog: config.showSaveDialog
                                    )
                                    dataManager.updateAutoSaveConfiguration(config)
                                }
                            ))
                            if dataManager.autoSaveConfiguration.isEnabled {
                                Text("Automatically saves calculations after completion")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Clear Data
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Button("Clear All Data") {
                            showingClearDataAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Import & Export")) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Button("Export All Calculations") {
                            dataManager.exportCalculations(dataManager.calculations)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Button("Export to CSV") {
                            dataManager.exportCalculationsToCSV(dataManager.calculations)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Button("Import from File") {
                            // TODO: Navigate to import screen
                        }
                    }
                }
                
                Section(header: Text("Storage Info")) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Saved Calculations")
                            Text("\(dataManager.calculations.count) calculations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Projects")
                            Text("\(dataManager.projects.count) projects")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    if dataManager.isCloudKitEnabled {
                        HStack {
                            Image(systemName: "icloud")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last Sync")
                                if let lastSync = dataManager.lastSyncDate {
                                    Text(lastSync, formatter: relativeDateFormatter)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Never")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("App Information")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Button("About IRR Genius") {
                            showingAbout = true
                        }
                    }
                    
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(.yellow)
                            .frame(width: 24)
                        Button("Rate App") {
                            // TODO: Implement app rating
                            if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView(isPresented: $showingAbout)
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await clearAllData()
                }
            }
        } message: {
            Text("This will permanently delete all your saved calculations and projects. This action cannot be undone.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func clearAllData() async {
        // Clear all calculations
        for calculation in dataManager.calculations {
            await dataManager.deleteCalculation(calculation)
        }
        
        // Clear all projects
        for project in dataManager.projects {
            await dataManager.deleteProject(project)
        }
    }
    
    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

struct AboutView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "function")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("IRR Genius")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("A powerful tool for calculating Internal Rate of Return (IRR) and managing investment calculations.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}