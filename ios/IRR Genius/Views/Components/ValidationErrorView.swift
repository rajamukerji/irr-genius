//
//  ValidationErrorView.swift
//  IRR Genius
//
//  Created by Kiro on 7/26/25.
//

import SwiftUI

/// View for displaying validation errors in a user-friendly format
struct ValidationErrorView: View {
    let errors: [ValidationError]
    let showSuggestions: Bool
    let onDismiss: (() -> Void)?

    init(errors: [ValidationError], showSuggestions: Bool = true, onDismiss: (() -> Void)? = nil) {
        self.errors = errors
        self.showSuggestions = showSuggestions
        self.onDismiss = onDismiss
    }

    var body: some View {
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("Please fix the following issues:")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if let onDismiss = onDismiss {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(errors) { error in
                        ValidationErrorRowView(
                            error: error,
                            showSuggestion: showSuggestions
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/// Individual validation error row
struct ValidationErrorRowView: View {
    let error: ValidationError
    let showSuggestion: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconForSeverity(error.severity))
                .foregroundColor(colorForSeverity(error.severity))
                .font(.caption)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(error.message)
                    .font(.body)
                    .foregroundColor(.primary)

                if showSuggestion, let suggestion = error.suggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            Spacer()
        }
    }

    private func iconForSeverity(_ severity: ValidationError.Severity) -> String {
        switch severity {
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private func colorForSeverity(_ severity: ValidationError.Severity) -> Color {
        switch severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

/// Compact validation summary view
struct ValidationSummaryView: View {
    let errorCount: Int
    let warningCount: Int
    let onTap: () -> Void

    var body: some View {
        if errorCount > 0 || warningCount > 0 {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    if errorCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("\(errorCount)")
                                .foregroundColor(.red)
                        }
                    }

                    if warningCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(warningCount)")
                                .foregroundColor(.orange)
                        }
                    }

                    Text("issues found")
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
}

/// Toast-style validation notification
struct ValidationToastView: View {
    let message: String
    let severity: ValidationError.Severity
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            HStack(spacing: 8) {
                Image(systemName: iconForSeverity(severity))
                    .foregroundColor(colorForSeverity(severity))

                Text(message)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Button("Dismiss") {
                    withAnimation {
                        isShowing = false
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }

    private func iconForSeverity(_ severity: ValidationError.Severity) -> String {
        switch severity {
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private func colorForSeverity(_ severity: ValidationError.Severity) -> Color {
        switch severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension ValidationError {
        static let sampleErrors: [ValidationError] = [
            ValidationError(
                field: "initialInvestment",
                message: "Initial investment must be positive",
                suggestion: "Enter a value greater than 0",
                severity: .error
            ),
            ValidationError(
                field: "name",
                message: "Name contains invalid characters",
                suggestion: "Remove characters like < > : \" / \\ | ? *",
                severity: .error
            ),
            ValidationError(
                field: "timeInMonths",
                message: "Time period seems unusually long",
                suggestion: "Consider if 120+ months is correct",
                severity: .warning
            ),
        ]
    }

    struct ValidationErrorView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                ValidationErrorView(errors: ValidationError.sampleErrors)
                    .padding()
                    .previewDisplayName("Error List")

                ValidationSummaryView(errorCount: 2, warningCount: 1) {
                    print("Tapped")
                }
                .padding()
                .previewDisplayName("Summary")

                ValidationToastView(
                    message: "Calculation saved successfully",
                    severity: .info,
                    isShowing: .constant(true)
                )
                .padding()
                .previewDisplayName("Toast")
            }
        }
    }
#endif
