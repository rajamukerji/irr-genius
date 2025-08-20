//
//  LaunchScreenView.swift
//  IRR Genius
//
//  Launch screen view for use in storyboard or SwiftUI preview
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.white,
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // App logo/icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "function")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.white)
                }
                
                // App name
                VStack(spacing: 4) {
                    Text("IRR Genius")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Investment Return Calculator")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)
                
                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}