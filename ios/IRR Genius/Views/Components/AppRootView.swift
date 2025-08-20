//
//  AppRootView.swift
//  IRR Genius
//
//  Root app view that ensures splash screen shows immediately
//

import SwiftUI

struct AppRootView: View {
    @State private var isInitialized = false
    @State private var loadingMessage = "Starting up..."
    
    var body: some View {
        ZStack {
            // Always show background immediately
            Color.blue.opacity(0.1)
                .ignoresSafeArea()
            
            if isInitialized {
                MainTabView()
                    .transition(.opacity)
            } else {
                SimpleSplashView(message: loadingMessage)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isInitialized)
        .onAppear {
            startInitialization()
        }
    }
    
    private func startInitialization() {
        Task {
            // Ensure splash screen shows for at least 2 seconds
            let startTime = Date()
            
            // Update loading message
            await MainActor.run {
                loadingMessage = "Loading application..."
            }
            
            // Add a small delay to ensure splash screen renders
            try? await Task.sleep(for: .milliseconds(500))
            
            await MainActor.run {
                loadingMessage = "Preparing interface..."
            }
            
            // Ensure minimum display time
            let elapsedTime = Date().timeIntervalSince(startTime)
            let minimumDisplayTime: TimeInterval = 2.0
            
            if elapsedTime < minimumDisplayTime {
                let remainingTime = minimumDisplayTime - elapsedTime
                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }
            
            // Mark as initialized
            await MainActor.run {
                isInitialized = true
            }
        }
    }
}

#Preview {
    AppRootView()
}