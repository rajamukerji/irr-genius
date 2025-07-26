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

// DataManager and models are now implemented in the Data/ and Models/ directories