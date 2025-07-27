//
//  OnboardingView.swift
//  IRR Genius
//

import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var showingPermissions = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to IRR Genius",
            subtitle: "Your comprehensive financial calculator",
            description: "Calculate Internal Rate of Return, project outcomes, and manage your investment portfolio with ease.",
            imageName: "chart.line.uptrend.xyaxis",
            primaryColor: .primaryBlue
        ),
        OnboardingPage(
            title: "Save & Organize",
            subtitle: "Never lose your calculations",
            description: "Save your calculations, organize them into projects, and access them anytime. Your data syncs across all your devices.",
            imageName: "folder.badge.plus",
            primaryColor: .primaryGreen
        ),
        OnboardingPage(
            title: "Import & Export",
            subtitle: "Work with your existing data",
            description: "Import data from CSV and Excel files, or export your calculations to share with colleagues and clients.",
            imageName: "square.and.arrow.up.on.square",
            primaryColor: .primaryOrange
        ),
        OnboardingPage(
            title: "Advanced Features",
            subtitle: "Professional-grade tools",
            description: "Portfolio unit investments, follow-on investment tracking, and comprehensive reporting for serious investors.",
            imageName: "briefcase.fill",
            primaryColor: .info
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(AnimationStyle.smooth, value: currentPage)
                
                // Bottom Controls
                VStack(spacing: Spacing.lg) {
                    // Page Indicator
                    HStack(spacing: Spacing.sm) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? pages[currentPage].primaryColor : Color.textTertiary)
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(AnimationStyle.spring, value: currentPage)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: Spacing.md) {
                        if currentPage > 0 {
                            AnimatedButton("Back", style: .tertiary, size: .medium) {
                                withAnimation(AnimationStyle.smooth) {
                                    currentPage -= 1
                                }
                            }
                            .accessibleButton(
                                label: "Back",
                                hint: "Go to previous onboarding page"
                            )
                        }
                        
                        Spacer()
                        
                        if currentPage < pages.count - 1 {
                            AnimatedButton("Next", icon: "arrow.right", style: .primary, size: .medium) {
                                withAnimation(AnimationStyle.smooth) {
                                    currentPage += 1
                                }
                            }
                            .accessibleButton(
                                label: "Next",
                                hint: "Go to next onboarding page"
                            )
                        } else {
                            AnimatedButton("Get Started", icon: "checkmark", style: .primary, size: .medium) {
                                showingPermissions = true
                            }
                            .accessibleButton(
                                label: "Get Started",
                                hint: "Complete onboarding and start using the app"
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.bottom, Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.textSecondary)
                    .accessibleButton(
                        label: "Skip onboarding",
                        hint: "Skip the introduction and start using the app"
                    )
                }
            }
        }
        .sheet(isPresented: $showingPermissions) {
            PermissionsView(isPresented: $showingPermissions) {
                completeOnboarding()
            }
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            AccessibilityAnnouncement.announcePageChange("Onboarding")
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(AnimationStyle.smooth) {
            isPresented = false
        }
        AccessibilityAnnouncement.announce("Onboarding completed. Welcome to IRR Genius!")
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.primaryColor)
                .accessibilityHidden(true)
            
            // Content
            VStack(spacing: Spacing.md) {
                Text(page.title)
                    .font(.headlineLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibleHeader()
                
                Text(page.subtitle)
                    .font(.titleMedium)
                    .foregroundColor(page.primaryColor)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.bodyLarge)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.subtitle). \(page.description)")
    }
}

// MARK: - Permissions View
struct PermissionsView: View {
    @Binding var isPresented: Bool
    let onComplete: () -> Void
    
    @State private var notificationsGranted = false
    @State private var cloudSyncEnabled = false
    @State private var analyticsEnabled = false
    
    private let permissions: [PermissionItem] = [
        PermissionItem(
            title: "Notifications",
            description: "Get notified about calculation updates and sync status",
            icon: "bell.fill",
            color: .primaryBlue,
            isRequired: false
        ),
        PermissionItem(
            title: "Cloud Sync",
            description: "Sync your data across devices using iCloud",
            icon: "icloud.fill",
            color: .primaryGreen,
            isRequired: false
        ),
        PermissionItem(
            title: "Analytics",
            description: "Help us improve the app with anonymous usage data",
            icon: "chart.bar.fill",
            color: .primaryOrange,
            isRequired: false
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                // Header
                VStack(spacing: Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primaryBlue)
                        .accessibilityHidden(true)
                    
                    Text("Privacy & Permissions")
                        .font(.headlineLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .accessibleHeader()
                    
                    Text("Choose which features you'd like to enable. You can change these settings anytime.")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xl)
                
                // Permissions List
                VStack(spacing: Spacing.md) {
                    ForEach(Array(permissions.enumerated()), id: \.offset) { index, permission in
                        PermissionRow(
                            permission: permission,
                            isEnabled: binding(for: index)
                        )
                    }
                }
                
                Spacer()
                
                // Action Button
                AnimatedButton("Continue", icon: "arrow.right", style: .primary, size: .large) {
                    requestPermissions()
                }
                .accessibleButton(
                    label: "Continue with selected permissions",
                    hint: "Apply permission settings and complete setup"
                )
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.horizontal, Spacing.lg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        onComplete()
                    }
                    .foregroundColor(.textSecondary)
                    .accessibleButton(
                        label: "Skip permissions",
                        hint: "Continue without enabling permissions"
                    )
                }
            }
        }
        .onAppear {
            AccessibilityAnnouncement.announcePageChange("Permissions Setup")
        }
    }
    
    private func binding(for index: Int) -> Binding<Bool> {
        switch index {
        case 0:
            return $notificationsGranted
        case 1:
            return $cloudSyncEnabled
        case 2:
            return $analyticsEnabled
        default:
            return .constant(false)
        }
    }
    
    private func requestPermissions() {
        // Request notifications if enabled
        if notificationsGranted {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        AccessibilityAnnouncement.announce("Notifications enabled")
                    }
                }
            }
        }
        
        // Save preferences
        UserDefaults.standard.set(cloudSyncEnabled, forKey: "cloudSyncEnabled")
        UserDefaults.standard.set(analyticsEnabled, forKey: "analyticsEnabled")
        
        onComplete()
    }
}

// MARK: - Permission Row
struct PermissionRow: View {
    let permission: PermissionItem
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: permission.icon)
                .font(.title2)
                .foregroundColor(permission.color)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(permission.title)
                        .font(.titleMedium)
                        .foregroundColor(.textPrimary)
                    
                    if permission.isRequired {
                        Text("Required")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.error)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                Text(permission.description)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .lineLimit(nil)
            }
            
            // Toggle
            AnimatedToggle(isOn: $isEnabled)
                .disabled(permission.isRequired)
        }
        .padding(Spacing.md)
        .cardStyle(shadow: .small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(permission.title). \(permission.description). \(isEnabled ? "Enabled" : "Disabled")")
        .accessibilityHint("Double tap to \(isEnabled ? "disable" : "enable")")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            if !permission.isRequired {
                withAnimation(AnimationStyle.spring) {
                    isEnabled.toggle()
                }
            }
        }
    }
}

// MARK: - Data Models
struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let primaryColor: Color
}

struct PermissionItem {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isRequired: Bool
}

// MARK: - Preview
#Preview {
    OnboardingView(isPresented: .constant(true))
}