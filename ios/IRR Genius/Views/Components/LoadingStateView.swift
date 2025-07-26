//
//  LoadingStateView.swift
//  IRR Genius
//
//  Loading states and progress indicators
//

import SwiftUI

// MARK: - Loading State Types
enum LoadingState {
    case idle
    case loading(message: String)
    case success(message: String)
    case error(message: String)
}

// MARK: - Loading Overlay View
struct LoadingOverlayView: View {
    let state: LoadingState
    let onRetry: (() -> Void)?
    
    init(state: LoadingState, onRetry: (() -> Void)? = nil) {
        self.state = state
        self.onRetry = onRetry
    }
    
    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
                
            case .loading(let message):
                LoadingView(message: message)
                
            case .success(let message):
                SuccessView(message: message)
                
            case .error(let message):
                ErrorView(message: message, onRetry: onRetry)
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    @State private var animationAmount = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .shadow(radius: 8)
    }
}

// MARK: - Success View
struct SuccessView: View {
    let message: String
    @State private var showCheckmark = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "checkmark")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .scaleEffect(showCheckmark ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .shadow(radius: 8)
        .onAppear {
            showCheckmark = true
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let onRetry = onRetry {
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .shadow(radius: 8)
    }
}

// MARK: - Progress Bar View
struct ProgressBarView: View {
    let progress: Double
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2.0)
            
            HStack {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Inline Loading View
struct InlineLoadingView: View {
    let message: String
    let isCompact: Bool
    
    init(message: String, isCompact: Bool = false) {
        self.message = message
        self.isCompact = isCompact
    }
    
    var body: some View {
        HStack(spacing: isCompact ? 8 : 12) {
            ProgressView()
                .scaleEffect(isCompact ? 0.8 : 1.0)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text(message)
                .font(isCompact ? .caption : .subheadline)
                .foregroundColor(.secondary)
        }
        .padding(isCompact ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 6 : 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Timeout Handler
class TimeoutHandler: ObservableObject {
    @Published var hasTimedOut = false
    private var timer: Timer?
    
    func startTimeout(duration: TimeInterval) {
        timer?.invalidate()
        hasTimedOut = false
        
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            DispatchQueue.main.async {
                self.hasTimedOut = true
            }
        }
    }
    
    func cancelTimeout() {
        timer?.invalidate()
        hasTimedOut = false
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Loading State Modifier
struct LoadingStateModifier: ViewModifier {
    let loadingState: LoadingState
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(loadingState != .idle)
            
            if loadingState != .idle {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                LoadingOverlayView(state: loadingState, onRetry: onRetry)
            }
        }
    }
}

extension View {
    func loadingState(_ state: LoadingState, onRetry: (() -> Void)? = nil) -> some View {
        modifier(LoadingStateModifier(loadingState: state, onRetry: onRetry))
    }
}

// MARK: - Background Sync Indicator
struct BackgroundSyncIndicator: View {
    @Binding var isVisible: Bool
    let message: String
    
    var body: some View {
        if isVisible {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: isVisible)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView(message: "Calculating IRR...")
        
        SuccessView(message: "Calculation saved successfully!")
        
        ErrorView(message: "Failed to save calculation. Please try again.") {
            print("Retry tapped")
        }
        
        ProgressBarView(progress: 0.65, message: "Importing data...")
        
        InlineLoadingView(message: "Loading calculations...")
        
        InlineLoadingView(message: "Syncing...", isCompact: true)
    }
    .padding()
}