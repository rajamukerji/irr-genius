//
//  ProjectsView.swift
//  IRR Genius
//
//  Created by Kiro on 7/24/25.
//

import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var showingCreateProject = false
    @State private var editingProject: Project?
    @State private var projectToDelete: Project?
    @State private var showingDeleteAlert = false
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return dataManager.projects.sorted { $0.createdDate > $1.createdDate }
        } else {
            return dataManager.projects.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                (project.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.createdDate > $1.createdDate }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if filteredProjects.isEmpty {
                    ProjectsEmptyStateView(searchText: searchText)
                } else {
                    List {
                        ForEach(filteredProjects) { project in
                            ProjectRowView(project: project)
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", role: .destructive) {
                                        projectToDelete = project
                                        showingDeleteAlert = true
                                    }
                                    Button("Edit") {
                                        editingProject = project
                                    }
                                }
                        }
                    }
                    .refreshable {
                        await dataManager.refreshData()
                    }
                }
            }
            .navigationTitle("Projects")
            .searchable(text: $searchText, prompt: "Search projects...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView(
                isPresented: $showingCreateProject,
                dataManager: dataManager
            )
        }
        .sheet(item: $editingProject) { project in
            EditProjectView(
                project: project,
                isPresented: .constant(true),
                dataManager: dataManager,
                onDismiss: { editingProject = nil }
            )
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let project = projectToDelete {
                    Task {
                        await dataManager.deleteProject(project)
                    }
                }
            }
        } message: {
            if let project = projectToDelete {
                Text("Are you sure you want to delete '\(project.name)'? This action cannot be undone. Calculations in this project will be moved to 'No Project'.")
            }
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                    if let description = project.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("0")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("calculations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(project.createdDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ProjectsEmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "folder.badge.plus" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No Projects" : "No Results Found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(searchText.isEmpty ? 
                 "Create projects to organize your calculations. Projects help you group related calculations together." :
                 "No projects match '\(searchText)'. Try adjusting your search terms.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CreateProjectView: View {
    @Binding var isPresented: Bool
    let dataManager: DataManager
    @State private var projectName = ""
    @State private var projectDescription = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $projectName)
                    TextField("Description (Optional)", text: $projectDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedDescription = projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        Task {
                            do {
                                let newProject = try Project(
                                    name: trimmedName,
                                    description: trimmedDescription.isEmpty ? nil : trimmedDescription
                                )
                                await dataManager.saveProject(newProject)
                            } catch {
                                print("Failed to create project: \(error)")
                            }
                        }
                        isPresented = false
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct EditProjectView: View {
    let project: Project
    @Binding var isPresented: Bool
    let dataManager: DataManager
    let onDismiss: () -> Void
    @State private var projectName: String
    @State private var projectDescription: String
    
    init(project: Project, isPresented: Binding<Bool>, dataManager: DataManager, onDismiss: @escaping () -> Void) {
        self.project = project
        self._isPresented = isPresented
        self.dataManager = dataManager
        self.onDismiss = onDismiss
        self._projectName = State(initialValue: project.name)
        self._projectDescription = State(initialValue: project.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $projectName)
                    TextField("Description (Optional)", text: $projectDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Group {
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(project.createdDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Calculations")
                            Spacer()
                            Text("0")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Project Information")
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedDescription = projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        Task {
                            do {
                                let updatedProject = try Project(
                                    id: project.id,
                                    name: trimmedName,
                                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                                    createdDate: project.createdDate
                                )
                                await dataManager.saveProject(updatedProject)
                            } catch {
                                print("Failed to update project: \(error)")
                            }
                        }
                        onDismiss()
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}