//
//  SavedCalculationsView.swift
//  IRR Genius
//
//  Created by Kiro on 7/24/25.
//

import SwiftUI

struct SavedCalculationsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var selectedProject: Project?
    @State private var showingImportSheet = false
    @State private var isRefreshing = false
    
    var filteredCalculations: [SavedCalculation] {
        dataManager.calculations.filter { calculation in
            let matchesSearch = searchText.isEmpty || 
                calculation.name.localizedCaseInsensitiveContains(searchText) ||
                calculation.calculationType.rawValue.localizedCaseInsensitiveContains(searchText)
            let matchesProject = selectedProject == nil || calculation.projectId == selectedProject?.id
            return matchesSearch && matchesProject
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Project Filter
                if !dataManager.projects.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedProject == nil,
                                action: { selectedProject = nil }
                            )
                            
                            ForEach(dataManager.projects) { project in
                                FilterChip(
                                    title: project.name,
                                    isSelected: selectedProject?.id == project.id,
                                    action: { selectedProject = project }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                if filteredCalculations.isEmpty {
                    EmptyStateView(searchText: searchText)
                } else {
                    List {
                        ForEach(filteredCalculations) { calculation in
                            CalculationRowView(calculation: calculation)
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", role: .destructive) {
                                        Task {
                                            await dataManager.deleteCalculation(calculation)
                                        }
                                    }
                                    Button("Export") {
                                        dataManager.exportCalculation(calculation)
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button("Load") {
                                        // TODO: Load calculation into calculator
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .refreshable {
                        await refreshCalculations()
                    }
                }
            }
            .navigationTitle("Saved Calculations")
            .searchable(text: $searchText, prompt: "Search calculations...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Import File") {
                            showingImportSheet = true
                        }
                        Button("New Calculation") {
                            // TODO: Navigate to calculator tab
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportFileView(isPresented: $showingImportSheet)
        }
    }
    
    private func refreshCalculations() async {
        isRefreshing = true
        // Simulate data refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await dataManager.refreshData()
        isRefreshing = false
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct CalculationRowView: View {
    let calculation: SavedCalculation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(calculation.name)
                        .font(.headline)
                    Text(calculation.calculationType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let result = calculation.calculatedResult {
                        Text("\(result, specifier: "%.2f")%")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Text(calculation.createdDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "folder" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No Saved Calculations" : "No Results Found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(searchText.isEmpty ? 
                 "Your saved calculations will appear here. Start by performing a calculation and saving it." :
                 "No calculations match '\(searchText)'. Try adjusting your search terms.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Placeholder for import functionality
struct ImportFileView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Import functionality will be implemented in task 4")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Import File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}