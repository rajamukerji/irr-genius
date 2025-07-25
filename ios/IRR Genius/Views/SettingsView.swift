//
//  SettingsView.swift
//  IRR Genius
//
//  Created by Kiro on 7/24/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var syncEnabled = false
    @State private var autoSaveEnabled = true
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data Management")) {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Toggle("Cloud Sync", isOn: $syncEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Toggle("Auto-Save Calculations", isOn: $autoSaveEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Button("Clear All Data") {
                            // TODO: Implement data clearing
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
                            // TODO: Implement bulk export
                        }
                    }
                    
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Button("Import from File") {
                            // TODO: Implement import
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
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView(isPresented: $showingAbout)
        }
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