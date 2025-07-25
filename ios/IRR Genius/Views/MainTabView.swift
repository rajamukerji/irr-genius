//
//  MainTabView.swift
//  IRR Genius
//
//  Created by Kiro on 7/24/25.
//

import SwiftUI

enum AppTab: String, CaseIterable {
    case calculator = "Calculator"
    case saved = "Saved"
    case projects = "Projects"
    case settings = "Settings"
    
    var systemImage: String {
        switch self {
        case .calculator:
            return "function"
        case .saved:
            return "folder"
        case .projects:
            return "folder.badge.plus"
        case .settings:
            return "gear"
        }
    }
}

struct MainTabView: View {
    @StateObject private var dataManager = DataManager()
    @State private var selectedTab: AppTab = .calculator
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CalculatorTabView()
                .tabItem {
                    Label(AppTab.calculator.rawValue, systemImage: AppTab.calculator.systemImage)
                }
                .tag(AppTab.calculator)
            
            SavedCalculationsView()
                .tabItem {
                    Label(AppTab.saved.rawValue, systemImage: AppTab.saved.systemImage)
                }
                .tag(AppTab.saved)
            
            ProjectsView()
                .tabItem {
                    Label(AppTab.projects.rawValue, systemImage: AppTab.projects.systemImage)
                }
                .tag(AppTab.projects)
            
            SettingsView()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage)
                }
                .tag(AppTab.settings)
        }
        .environmentObject(dataManager)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle deep linking to saved calculations
        // URL format: irrgenius://calculation/{id}
        guard url.scheme == "irrgenius",
              url.host == "calculation" else { return }
        
        let pathComponents = url.pathComponents
        if pathComponents.count > 1 {
            let calculationId = pathComponents[1]
            // Navigate to saved tab and load specific calculation
            selectedTab = .saved
            // TODO: Implement navigation to specific calculation
        }
    }
}

// Wrapper for the existing calculator functionality
struct CalculatorTabView: View {
    var body: some View {
        NavigationView {
            ContentView()
                .navigationTitle("Calculator")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Placeholder for DataManager - will be implemented in data layer tasks
class DataManager: ObservableObject {
    @Published var calculations: [SavedCalculation] = []
    @Published var projects: [Project] = []
    
    func deleteCalculation(_ calculation: SavedCalculation) {
        // TODO: Implement deletion
        calculations.removeAll { $0.id == calculation.id }
    }
    
    func exportCalculation(_ calculation: SavedCalculation) {
        // TODO: Implement export
    }
    
    func createProject(name: String, description: String?) {
        let newProject = Project(
            id: UUID(),
            name: name,
            description: description,
            createdDate: Date(),
            calculationCount: 0
        )
        projects.append(newProject)
    }
    
    func updateProject(_ project: Project, name: String, description: String?) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = Project(
                id: project.id,
                name: name,
                description: description,
                createdDate: project.createdDate,
                calculationCount: project.calculationCount
            )
        }
    }
    
    func deleteProject(_ project: Project) {
        // Move calculations from this project to "No Project"
        for i in calculations.indices {
            if calculations[i].projectId == project.id {
                calculations[i] = SavedCalculation(
                    id: calculations[i].id,
                    name: calculations[i].name,
                    calculationType: calculations[i].calculationType,
                    createdDate: calculations[i].createdDate,
                    projectId: nil,
                    calculatedResult: calculations[i].calculatedResult
                )
            }
        }
        
        // Remove the project
        projects.removeAll { $0.id == project.id }
    }
    
    @MainActor
    func refreshData() async {
        // TODO: Implement data refresh from repository
        // For now, just simulate refresh
    }
}

// Placeholder models - will be implemented in data layer tasks
struct SavedCalculation: Identifiable {
    let id: UUID
    let name: String
    let calculationType: CalculationMode
    let createdDate: Date
    let projectId: UUID?
    let calculatedResult: Double?
    
    init(id: UUID = UUID(), name: String, calculationType: CalculationMode, createdDate: Date, projectId: UUID? = nil, calculatedResult: Double? = nil) {
        self.id = id
        self.name = name
        self.calculationType = calculationType
        self.createdDate = createdDate
        self.projectId = projectId
        self.calculatedResult = calculatedResult
    }
}

struct Project: Identifiable {
    let id = UUID()
    let name: String
    let description: String?
    let createdDate: Date
    let calculationCount: Int
}