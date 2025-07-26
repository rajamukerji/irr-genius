//
//  SaveCalculationDialog.swift
//  IRR Genius
//
//  Auto-save dialog for calculations
//

import SwiftUI

struct SaveCalculationDialog: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedProject: Project?
    @State private var newProjectName: String = ""
    @State private var showingNewProjectField: Bool = false
    @State private var tagInput: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Calculation Details")) {
                    TextField("Calculation Name", text: $dataManager.saveDialogData.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Notes (Optional)", text: $dataManager.saveDialogData.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Project")) {
                    if showingNewProjectField {
                        HStack {
                            TextField("New Project Name", text: $newProjectName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Cancel") {
                                showingNewProjectField = false
                                newProjectName = ""
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Picker("Select Project", selection: $selectedProject) {
                            Text("No Project").tag(nil as Project?)
                            ForEach(dataManager.projects) { project in
                                HStack {
                                    if let color = project.color {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 12, height: 12)
                                    }
                                    Text(project.name)
                                }
                                .tag(project as Project?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Button("Create New Project") {
                            showingNewProjectField = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Tags")) {
                    HStack {
                        TextField("Add tag", text: $tagInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                addTag()
                            }
                        
                        Button("Add") {
                            addTag()
                        }
                        .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if !dataManager.saveDialogData.tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(dataManager.saveDialogData.tags, id: \.self) { tag in
                                TagView(tag: tag) {
                                    removeTag(tag)
                                }
                            }
                        }
                    }
                }
                
                if let calculation = dataManager.saveDialogData.calculationToSave {
                    Section(header: Text("Calculation Summary")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Type:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(calculation.calculationType.displayName)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let result = calculation.calculatedResult {
                                HStack {
                                    Text("Result:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(formatResult(result, for: calculation.calculationType))
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            HStack {
                                Text("Created:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(calculation.createdDate, style: .date)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Save Calculation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dataManager.dismissSaveDialog()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveCalculation()
                        }
                    }
                    .disabled(dataManager.saveDialogData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            selectedProject = dataManager.projects.first { $0.id == dataManager.saveDialogData.projectId }
        }
        .onChange(of: selectedProject) { newProject in
            dataManager.saveDialogData.projectId = newProject?.id
        }
    }
    
    private func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty,
              !dataManager.saveDialogData.tags.contains(trimmedTag) else { return }
        
        dataManager.saveDialogData.tags.append(trimmedTag)
        tagInput = ""
    }
    
    private func removeTag(_ tag: String) {
        dataManager.saveDialogData.tags.removeAll { $0 == tag }
    }
    
    private func saveCalculation() async {
        // Create new project if needed
        if showingNewProjectField && !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let newProject = try Project(
                    name: newProjectName.trimmingCharacters(in: .whitespacesAndNewlines),
                    color: Project.defaultColors.randomElement()
                )
                await dataManager.saveProject(newProject)
                dataManager.saveDialogData.projectId = newProject.id
            } catch {
                dataManager.errorMessage = "Failed to create project: \(error.localizedDescription)"
                return
            }
        }
        
        await dataManager.saveFromDialog()
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

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue)
        .cornerRadius(12)
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SaveCalculationDialog()
        .environmentObject(DataManager())
}