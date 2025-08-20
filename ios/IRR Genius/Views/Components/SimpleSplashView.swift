//
//  SimpleSplashView.swift
//  IRR Genius
//
//  Minimal splash screen for testing
//

import SwiftUI

struct SimpleSplashView: View {
    let message: String
    
    var body: some View {
        ZStack {
            // Simple background color
            Color.blue.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Simple logo
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "function")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
                
                // App name
                Text("IRR Genius")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Loading indicator
                ProgressView()
                    .scaleEffect(1.5)
                
                // Loading message
                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SimpleSplashView(message: "Loading...")
}