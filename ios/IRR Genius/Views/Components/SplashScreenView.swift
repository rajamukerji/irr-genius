//
//  SplashScreenView.swift
//  IRR Genius
//
//  App launch splash screen with logo and loading indicator
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale = 0.6
    @State private var logoOpacity = 0.0
    @State private var loadingOpacity = 0.0
    @State private var animateLoading = false
    
    let loadingMessage: String
    
    init(loadingMessage: String = "Loading...") {
        self.loadingMessage = loadingMessage
    }
    
    var body: some View {
        ZStack {
            // Background gradient
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo/App Icon Area
                VStack(spacing: 16) {
                    // App logo/icon placeholder - you can replace with actual logo
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
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
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
                    .opacity(logoOpacity)
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .rotationEffect(.degrees(animateLoading ? 360 : 0))
                    
                    Text(loadingMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(loadingOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Loading indicator animation (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                loadingOpacity = 1.0
            }
        }
        
        // Continuous loading rotation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animateLoading = true
        }
    }
}

#Preview {
    SplashScreenView(loadingMessage: "Loading calculations...")
}