//
//  UserFriendlyErrorView.swift
//  IRR Genius
//
//  Created by Kiro on 7/26/25.
//

import SwiftUI

/// Main view for displaying user-friendly errors
struct UserFriendlyErrorView: View {
    let error: UserFriendlyError
    let onAction: (SuggestedAction) -> Void
    let onDismiss: () -> Void

    @State private var showingHelp = false
    @State private var showingFeedback = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: error.category.icon)
                    .font(.system(size: 48))
                    .foregroundColor(error.category.color)

                Text(error.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(error.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Action Suggestions
            if !error.actionSuggestions.isEmpty {
                VStack(spacing: 12) {
                    Text("What you can do:")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(Array(error.actionSuggestions.enumerated()), id: \.offset) { _, suggestion in
                        ActionSuggestionRow(
                            suggestion: suggestion,
                            onTap: { onAction(suggestion.action) }
                        )
                    }
                }
            }

            // Help and Support
            VStack(spacing: 12) {
                if let helpLink = error.helpLink {
                    Button(action: {
                        showingHelp = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text(helpLink.title)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showingHelp) {
                        SafariView(url: helpLink.url)
                    }
                }

                if error.reportable {
                    Button(action: {
                        showingFeedback = true
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Send Feedback")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .sheet(isPresented: $showingFeedback) {
                        ErrorFeedbackView(error: error)
                    }
                }
            }

            // Dismiss Button
            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(error.severity.color.opacity(0.3), lineWidth: 2)
        )
    }
}

/// Row for displaying action suggestions
struct ActionSuggestionRow: View {
    let suggestion: ActionSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconForAction(suggestion.action))
                    .font(.title3)
                    .foregroundColor(suggestion.isPrimary ? .white : .blue)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(suggestion.isPrimary ? .white : .primary)

                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(suggestion.isPrimary ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(suggestion.isPrimary ? .white.opacity(0.6) : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(suggestion.isPrimary ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func iconForAction(_ action: SuggestedAction) -> String {
        switch action {
        case .retry: return "arrow.clockwise"
        case .dismiss: return "xmark"
        case .focusField: return "cursor.rays"
        case .highlightFields: return "highlighter"
        case .selectFile: return "folder"
        case .downloadTemplate: return "square.and.arrow.down"
        case .showHelp: return "questionmark.circle"
        case .showExamples: return "list.bullet.rectangle"
        case .contactSupport: return "envelope"
        case .checkNetwork: return "wifi"
        case .restartApp: return "arrow.clockwise.circle"
        case .resync: return "icloud.and.arrow.up"
        case .replaceFile: return "doc.badge.plus"
        }
    }
}

/// Compact error alert for inline display
struct ErrorAlert: View {
    let error: UserFriendlyError
    let onAction: ((SuggestedAction) -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.category.icon)
                .foregroundColor(error.severity.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(error.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(error.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if let primaryAction = error.actionSuggestions.first(where: { $0.isPrimary }) ?? error.actionSuggestions.first {
                Button(primaryAction.title) {
                    onAction?(primaryAction.action)
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(error.severity.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(error.severity.color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Error feedback form
struct ErrorFeedbackView: View {
    let error: UserFriendlyError
    @Environment(\.dismiss) private var dismiss

    @State private var userDescription = ""
    @State private var reproductionSteps = ""
    @State private var userEmail = ""
    @State private var isSubmitting = false

    @StateObject private var errorReporting = ErrorReportingService()

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Help us improve by describing what happened:")
                        .font(.body)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Error Feedback")
                }

                Section("What were you trying to do?") {
                    TextEditor(text: $userDescription)
                        .frame(minHeight: 80)
                }

                Section("How can we reproduce this issue? (Optional)") {
                    TextEditor(text: $reproductionSteps)
                        .frame(minHeight: 60)
                }

                Section("Email (Optional)") {
                    TextField("your.email@example.com", text: $userEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error Details:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Category: \(error.category)")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("Severity: \(error.severity)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Technical Information")
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        submitFeedback()
                    }
                    .disabled(userDescription.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submitFeedback() {
        isSubmitting = true

        let feedback = UserErrorFeedback(
            errorId: UUID().uuidString,
            userDescription: userDescription,
            reproductionSteps: reproductionSteps.isEmpty ? nil : reproductionSteps,
            userEmail: userEmail.isEmpty ? nil : userEmail,
            timestamp: Date()
        )

        errorReporting.submitUserFeedback(feedback)

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
            dismiss()
        }
    }
}

/// Safari view for help links
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context _: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_: SFSafariViewController, context _: Context) {
        // No updates needed
    }
}

/// Error category badge
struct ErrorCategoryBadge: View {
    let category: ErrorCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)

            Text(String(describing: category).capitalized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(category.color.opacity(0.1))
        )
        .foregroundColor(category.color)
    }
}

/// Error severity indicator
struct ErrorSeverityIndicator: View {
    let severity: ErrorSeverity

    var body: some View {
        Circle()
            .fill(severity.color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension UserFriendlyError {
        static let sampleValidationError = UserFriendlyError(
            title: "Missing Calculation Name",
            message: "Please enter a name for your calculation to save it.",
            category: .validation,
            severity: .error,
            actionSuggestions: [
                ActionSuggestion(
                    title: "Enter Name",
                    description: "Add a descriptive name for your calculation",
                    action: .focusField("name"),
                    isPrimary: true
                ),
                ActionSuggestion(
                    title: "Learn More",
                    description: "Understanding calculation naming",
                    action: .showHelp
                ),
            ],
            helpLink: HelpLink(
                title: "Naming Your Calculations",
                url: URL(string: "https://help.irrgenius.com/calculations/naming")!
            )
        )

        static let sampleNetworkError = UserFriendlyError(
            title: "No Internet Connection",
            message: "Please check your internet connection and try again.",
            category: .network,
            severity: .error,
            actionSuggestions: [
                ActionSuggestion(
                    title: "Try Again",
                    description: "Retry the operation",
                    action: .retry,
                    isPrimary: true
                ),
                ActionSuggestion(
                    title: "Check Connection",
                    description: "Verify your Wi-Fi or cellular connection",
                    action: .checkNetwork
                ),
            ]
        )
    }

    struct UserFriendlyErrorView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                UserFriendlyErrorView(
                    error: .sampleValidationError,
                    onAction: { _ in },
                    onDismiss: {}
                )
                .padding()
                .previewDisplayName("Validation Error")

                ErrorAlert(
                    error: .sampleNetworkError,
                    onAction: { _ in },
                    onDismiss: {}
                )
                .padding()
                .previewDisplayName("Error Alert")

                VStack {
                    ErrorCategoryBadge(category: .validation)
                    ErrorCategoryBadge(category: .network)
                    ErrorCategoryBadge(category: .storage)
                }
                .padding()
                .previewDisplayName("Category Badges")
            }
        }
    }
#endif

import SafariServices
