//
//  LoadCalculationView.swift
//  IRR Genius
//
//  Load calculation functionality for editing
//

import SwiftUI

struct LoadCalculationView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var isPresented: Bool
    let onCalculationSelected: (SavedCalculation) -> Void

    @State private var searchText = ""
    @State private var selectedCalculationType: CalculationMode?
    @State private var selectedProject: Project?
    @State private var showingDuplicateAlert = false
    @State private var calculationToDuplicate: SavedCalculation?

    var filteredCalculations: [SavedCalculation] {
        dataManager.calculations.filter { calculation in
            let matchesSearch = searchText.isEmpty ||
                calculation.name.localizedCaseInsensitiveContains(searchText) ||
                (calculation.notes?.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesType = selectedCalculationType == nil ||
                calculation.calculationType == selectedCalculationType

            let matchesProject = selectedProject == nil ||
                calculation.projectId == selectedProject?.id

            return matchesSearch && matchesType && matchesProject
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filters
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)

                    HStack(spacing: 12) {
                        // Calculation Type Filter
                        Menu {
                            Button("All Types") {
                                selectedCalculationType = nil
                            }

                            ForEach(CalculationMode.allCases, id: \.self) { mode in
                                Button(mode.displayName) {
                                    selectedCalculationType = mode
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCalculationType?.displayName ?? "All Types")
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }

                        // Project Filter
                        Menu {
                            Button("All Projects") {
                                selectedProject = nil
                            }

                            ForEach(dataManager.projects) { project in
                                Button(project.name) {
                                    selectedProject = project
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedProject?.name ?? "All Projects")
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }

                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemBackground))

                Divider()

                // Calculations List
                if filteredCalculations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No calculations found")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        if !searchText.isEmpty {
                            Text("Try adjusting your search or filters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredCalculations) { calculation in
                            CalculationLoadRow(
                                calculation: calculation,
                                onLoad: {
                                    onCalculationSelected(calculation)
                                    isPresented = false
                                },
                                onDuplicate: {
                                    calculationToDuplicate = calculation
                                    showingDuplicateAlert = true
                                },
                                onViewHistory: {
                                    // TODO: Implement history view
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Load Calculation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .alert("Duplicate Calculation", isPresented: $showingDuplicateAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Duplicate") {
                if let calculation = calculationToDuplicate {
                    Task {
                        await dataManager.duplicateCalculation(calculation)
                    }
                }
            }
        } message: {
            Text("This will create a copy of the calculation that you can modify independently.")
        }
    }
}

struct CalculationLoadRow: View {
    let calculation: SavedCalculation
    let onLoad: () -> Void
    let onDuplicate: () -> Void
    let onViewHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(calculation.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(calculation.calculationType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let result = calculation.calculatedResult {
                        Text(formatResult(result, for: calculation.calculationType))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }

                    Text(calculation.modifiedDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let notes = calculation.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if !calculation.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(calculation.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            HStack(spacing: 12) {
                Button("Load") {
                    onLoad()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Duplicate") {
                    onDuplicate()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("History") {
                    onViewHistory()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()
            }
        }
        .padding(.vertical, 8)
    }

    private func formatResult(_ result: Double, for calculationType: CalculationMode) -> String {
        switch calculationType {
        case .calculateIRR, .calculateBlendedIRR, .portfolioUnitInvestment:
            return String(format: "%.2f%%", result)
        case .calculateOutcome, .calculateInitial:
            return String(format: "$%.2f", result)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search calculations...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// CalculationMode already conforms to CaseIterable in Models/Enums.swift

#Preview {
    LoadCalculationView(isPresented: .constant(true)) { _ in }
        .environmentObject(DataManager())
}
