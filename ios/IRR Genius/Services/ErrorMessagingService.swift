//
//  ErrorMessagingService.swift
//  IRR Genius
//
//  Created by Kiro on 7/26/25.
//

import Foundation
import SwiftUI

// MARK: - User-Friendly Error Messaging Framework

/// Service for providing user-friendly error messages and help
class ErrorMessagingService: ObservableObject {
    
    /// Converts technical errors into user-friendly messages
    func getUserFriendlyMessage(for error: Error) -> UserFriendlyError {
        switch error {
        // Validation Errors
        case let validationError as SavedCalculationValidationError:
            return handleValidationError(validationError)
            
        case let projectError as ProjectValidationError:
            return handleProjectValidationError(projectError)
            
        // Import/Export Errors
        case let importError as ImportError:
            return handleImportError(importError)
            
        // Network Errors
        case let urlError as URLError:
            return handleNetworkError(urlError)
            
        // Core Data Errors
        case let nsError as NSError where nsError.domain == "NSCocoaErrorDomain":
            return handleCoreDataError(nsError)
            
        // CloudKit Errors
        case let nsError as NSError where nsError.domain == "CKErrorDomain":
            return handleCloudKitError(nsError)
            
        // File System Errors
        case let nsError as NSError where nsError.domain == NSCocoaErrorDomain:
            return handleFileSystemError(nsError)
            
        // Generic Errors
        default:
            return UserFriendlyError(
                title: "Unexpected Error",
                message: error.localizedDescription,
                category: .system,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Try Again",
                        description: "Retry the operation",
                        action: .retry
                    ),
                    ActionSuggestion(
                        title: "Contact Support",
                        description: "Report this issue to our support team",
                        action: .contactSupport
                    )
                ],
                helpLink: HelpLink(
                    title: "General Troubleshooting",
                    url: URL(string: "https://help.irrgenius.com/troubleshooting")!
                )
            )
        }
    }
    
    // MARK: - Specific Error Handlers
    
    private func handleValidationError(_ error: SavedCalculationValidationError) -> UserFriendlyError {
        switch error {
        case .emptyName:
            return UserFriendlyError(
                title: "Missing Calculation Name",
                message: "Please enter a name for your calculation to save it.",
                category: .validation,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Enter Name",
                        description: "Add a descriptive name for your calculation",
                        action: .focusField("name")
                    )
                ],
                helpLink: HelpLink(
                    title: "Naming Your Calculations",
                    url: URL(string: "https://help.irrgenius.com/calculations/naming")!
                )
            )
            
        case .negativeInvestment:
            return UserFriendlyError(
                title: "Invalid Investment Amount",
                message: "Investment amounts must be positive values greater than zero.",
                category: .validation,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Fix Amount",
                        description: "Enter a positive dollar amount",
                        action: .focusField("initialInvestment")
                    ),
                    ActionSuggestion(
                        title: "Learn More",
                        description: "Understanding investment calculations",
                        action: .showHelp
                    )
                ],
                helpLink: HelpLink(
                    title: "Investment Amount Guidelines",
                    url: URL(string: "https://help.irrgenius.com/calculations/investment-amounts")!
                )
            )
            
        case .invalidTimeInMonths:
            return UserFriendlyError(
                title: "Invalid Time Period",
                message: "Time period must be a positive number representing months.",
                category: .validation,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Fix Time Period",
                        description: "Enter the number of months (e.g., 12 for 1 year)",
                        action: .focusField("timeInMonths")
                    ),
                    ActionSuggestion(
                        title: "Time Examples",
                        description: "See common time period examples",
                        action: .showExamples
                    )
                ],
                helpLink: HelpLink(
                    title: "Time Period Guidelines",
                    url: URL(string: "https://help.irrgenius.com/calculations/time-periods")!
                )
            )
            
        case .invalidIRR:
            return UserFriendlyError(
                title: "Invalid IRR Value",
                message: "IRR must be a realistic percentage between -100% and 1000%.",
                category: .validation,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Fix IRR",
                        description: "Enter a percentage (e.g., 15 for 15%)",
                        action: .focusField("irr")
                    ),
                    ActionSuggestion(
                        title: "IRR Examples",
                        description: "See typical IRR ranges for different investments",
                        action: .showExamples
                    )
                ],
                helpLink: HelpLink(
                    title: "Understanding IRR",
                    url: URL(string: "https://help.irrgenius.com/concepts/irr")!
                )
            )
            
        case .missingRequiredFields(let fields):
            return UserFriendlyError(
                title: "Missing Required Information",
                message: "Please fill in all required fields: \(fields.joined(separator: ", "))",
                category: .validation,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Complete Form",
                        description: "Fill in the highlighted required fields",
                        action: .highlightFields(fields)
                    )
                ],
                helpLink: HelpLink(
                    title: "Required Fields Guide",
                    url: URL(string: "https://help.irrgenius.com/calculations/required-fields")!
                )
            )
            
        default:
            return UserFriendlyError(
                title: "Validation Error",
                message: error.localizedDescription,
                category: .validation,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Review Input",
                        description: "Check your input values and try again",
                        action: .retry
                    )
                ]
            )
        }
    }
    
    private func handleProjectValidationError(_ error: ProjectValidationError) -> UserFriendlyError {
        switch error {
        case .emptyName:
            return UserFriendlyError(
                title: "Missing Project Name",
                message: "Please enter a name for your project.",
                category: .validation,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Enter Name",
                        description: "Add a descriptive name for your project",
                        action: .focusField("projectName")
                    )
                ]
            )
            
        case .invalidName(let reason):
            return UserFriendlyError(
                title: "Invalid Project Name",
                message: reason,
                category: .validation,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Fix Name",
                        description: "Use only letters, numbers, and basic punctuation",
                        action: .focusField("projectName")
                    )
                ]
            )
            
        default:
            return UserFriendlyError(
                title: "Project Error",
                message: error.localizedDescription,
                category: .validation,
                severity: .error
            )
        }
    }
    
    private func handleImportError(_ error: ImportError) -> UserFriendlyError {
        switch error {
        case .fileAccessDenied:
            return UserFriendlyError(
                title: "Cannot Access File",
                message: "The app doesn't have permission to access the selected file.",
                category: .fileAccess,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Try Different File",
                        description: "Select a file from a different location",
                        action: .selectFile
                    ),
                    ActionSuggestion(
                        title: "Check Permissions",
                        description: "Ensure the file isn't restricted or locked",
                        action: .showHelp
                    )
                ],
                helpLink: HelpLink(
                    title: "File Access Issues",
                    url: URL(string: "https://help.irrgenius.com/import/file-access")!
                )
            )
            
        case .emptyFile:
            return UserFriendlyError(
                title: "Empty File",
                message: "The selected file appears to be empty or contains no data.",
                category: .fileFormat,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Check File",
                        description: "Open the file in a spreadsheet app to verify it has data",
                        action: .showHelp
                    ),
                    ActionSuggestion(
                        title: "Try Different File",
                        description: "Select a file that contains calculation data",
                        action: .selectFile
                    )
                ],
                helpLink: HelpLink(
                    title: "File Format Requirements",
                    url: URL(string: "https://help.irrgenius.com/import/file-formats")!
                )
            )
            
        case .unsupportedFormat:
            return UserFriendlyError(
                title: "Unsupported File Format",
                message: "Please use CSV (.csv) or Excel (.xlsx, .xls) files for importing data.",
                category: .fileFormat,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Convert File",
                        description: "Save your file as CSV or Excel format",
                        action: .showHelp
                    ),
                    ActionSuggestion(
                        title: "Download Template",
                        description: "Use our template to format your data correctly",
                        action: .downloadTemplate
                    )
                ],
                helpLink: HelpLink(
                    title: "Supported File Formats",
                    url: URL(string: "https://help.irrgenius.com/import/supported-formats")!
                )
            )
            
        case .invalidNumberFormat(let row, let field, let value):
            return UserFriendlyError(
                title: "Invalid Number Format",
                message: "Row \(row) contains an invalid number in the '\(field)' column: '\(value)'",
                category: .dataFormat,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Fix Data",
                        description: "Correct the number format in your file",
                        action: .showHelp
                    ),
                    ActionSuggestion(
                        title: "Number Examples",
                        description: "See examples of valid number formats",
                        action: .showExamples
                    )
                ],
                helpLink: HelpLink(
                    title: "Number Format Guidelines",
                    url: URL(string: "https://help.irrgenius.com/import/number-formats")!
                )
            )
            
        default:
            return UserFriendlyError(
                title: "Import Error",
                message: error.localizedDescription,
                category: .importing,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Try Again",
                        description: "Retry the import operation",
                        action: .retry
                    )
                ]
            )
        }
    }
    
    private func handleNetworkError(_ error: URLError) -> UserFriendlyError {
        switch error.code {
        case .notConnectedToInternet:
            return UserFriendlyError(
                title: "No Internet Connection",
                message: "Please check your internet connection and try again.",
                category: .network,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Check Connection",
                        description: "Verify your Wi-Fi or cellular connection",
                        action: .checkNetwork
                    ),
                    ActionSuggestion(
                        title: "Try Again",
                        description: "Retry when connection is restored",
                        action: .retry
                    )
                ],
                helpLink: HelpLink(
                    title: "Connection Troubleshooting",
                    url: URL(string: "https://help.irrgenius.com/troubleshooting/network")!
                )
            )
            
        case .timedOut:
            return UserFriendlyError(
                title: "Request Timed Out",
                message: "The operation took too long to complete. This might be due to a slow connection.",
                category: .network,
                severity: .warning,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Try Again",
                        description: "Retry the operation",
                        action: .retry
                    ),
                    ActionSuggestion(
                        title: "Check Connection",
                        description: "Ensure you have a stable internet connection",
                        action: .checkNetwork
                    )
                ]
            )
            
        default:
            return UserFriendlyError(
                title: "Network Error",
                message: "A network error occurred. Please check your connection and try again.",
                category: .network,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Try Again",
                        description: "Retry the operation",
                        action: .retry
                    )
                ]
            )
        }
    }
    
    private func handleCoreDataError(_ error: NSError) -> UserFriendlyError {
        return UserFriendlyError(
            title: "Data Storage Error",
            message: "There was a problem saving or loading your data. Your work may not be saved.",
            category: .storage,
            severity: .error,
            actionSuggestions: [
                ActionSuggestion(
                    title: "Try Again",
                    description: "Retry the operation",
                    action: .retry
                ),
                ActionSuggestion(
                    title: "Restart App",
                    description: "Close and reopen the app",
                    action: .restartApp
                )
            ],
            helpLink: HelpLink(
                title: "Data Storage Issues",
                url: URL(string: "https://help.irrgenius.com/troubleshooting/storage")!
            )
        )
    }
    
    private func handleCloudKitError(_ error: NSError) -> UserFriendlyError {
        switch error.code {
        case 3: // Network unavailable
            return UserFriendlyError(
                title: "Cloud Sync Unavailable",
                message: "Cloud sync is temporarily unavailable. Your data is saved locally.",
                category: .sync,
                severity: .warning,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Try Later",
                        description: "Sync will resume when connection is restored",
                        action: .dismiss
                    )
                ]
            )
            
        case 9: // User deleted zone
            return UserFriendlyError(
                title: "Cloud Data Reset",
                message: "Your cloud data has been reset. Local data is unaffected.",
                category: .sync,
                severity: .warning,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Re-sync",
                        description: "Upload your local data to the cloud",
                        action: .resync
                    )
                ]
            )
            
        default:
            return UserFriendlyError(
                title: "Cloud Sync Error",
                message: "There was a problem syncing with iCloud. Your data is saved locally.",
                category: .sync,
                severity: .warning,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Try Again",
                        description: "Retry cloud sync",
                        action: .retry
                    )
                ]
            )
        }
    }
    
    private func handleFileSystemError(_ error: NSError) -> UserFriendlyError {
        switch error.code {
        case NSFileReadNoSuchFileError:
            return UserFriendlyError(
                title: "File Not Found",
                message: "The selected file could not be found. It may have been moved or deleted.",
                category: .fileAccess,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Select Different File",
                        description: "Choose another file to import",
                        action: .selectFile
                    )
                ]
            )
            
        case NSFileWriteFileExistsError:
            return UserFriendlyError(
                title: "File Already Exists",
                message: "A file with this name already exists. Please choose a different name.",
                category: .fileAccess,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Choose Different Name",
                        description: "Enter a unique filename",
                        action: .focusField("filename")
                    ),
                    ActionSuggestion(
                        title: "Replace File",
                        description: "Overwrite the existing file",
                        action: .replaceFile
                    )
                ]
            )
            
        default:
            return UserFriendlyError(
                title: "File System Error",
                message: "There was a problem accessing the file system.",
                category: .fileAccess,
                severity: .error,
                actionSuggestions: [
                    ActionSuggestion(
                        title: "Try Again",
                        description: "Retry the operation",
                        action: .retry
                    )
                ]
            )
        }
    }
}

// MARK: - Supporting Types

/// User-friendly error representation
struct UserFriendlyError {
    let title: String
    let message: String
    let category: ErrorCategory
    let severity: ErrorSeverity
    let actionSuggestions: [ActionSuggestion]
    let helpLink: HelpLink?
    let reportable: Bool
    
    init(
        title: String,
        message: String,
        category: ErrorCategory,
        severity: ErrorSeverity = .error,
        actionSuggestions: [ActionSuggestion] = [],
        helpLink: HelpLink? = nil,
        reportable: Bool = true
    ) {
        self.title = title
        self.message = message
        self.category = category
        self.severity = severity
        self.actionSuggestions = actionSuggestions
        self.helpLink = helpLink
        self.reportable = reportable
    }
}

/// Error categories for better organization
enum ErrorCategory {
    case validation
    case network
    case storage
    case sync
    case importing
    case exporting
    case fileAccess
    case fileFormat
    case dataFormat
    case system
    
    var icon: String {
        switch self {
        case .validation: return "exclamationmark.triangle"
        case .network: return "wifi.slash"
        case .storage: return "externaldrive.badge.xmark"
        case .sync: return "icloud.slash"
        case .importing: return "square.and.arrow.down"
        case .exporting: return "square.and.arrow.up"
        case .fileAccess: return "folder.badge.questionmark"
        case .fileFormat: return "doc.badge.ellipsis"
        case .dataFormat: return "textformat.123"
        case .system: return "gear.badge.xmark"
        }
    }
    
    var color: Color {
        switch self {
        case .validation: return .orange
        case .network: return .red
        case .storage: return .red
        case .sync: return .blue
        case .importing, .exporting: return .purple
        case .fileAccess, .fileFormat, .dataFormat: return .orange
        case .system: return .gray
        }
    }
}

/// Error severity levels
enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        }
    }
}

/// Action suggestions for error recovery
struct ActionSuggestion {
    let title: String
    let description: String
    let action: SuggestedAction
    let isPrimary: Bool
    
    init(title: String, description: String, action: SuggestedAction, isPrimary: Bool = false) {
        self.title = title
        self.description = description
        self.action = action
        self.isPrimary = isPrimary
    }
}

/// Types of suggested actions
enum SuggestedAction {
    case retry
    case dismiss
    case focusField(String)
    case highlightFields([String])
    case selectFile
    case downloadTemplate
    case showHelp
    case showExamples
    case contactSupport
    case checkNetwork
    case restartApp
    case resync
    case replaceFile
}

/// Help link information
struct HelpLink {
    let title: String
    let url: URL
}

// MARK: - Error Reporting

/// Service for collecting and reporting errors
class ErrorReportingService: ObservableObject {
    @Published var reportingEnabled: Bool = true
    
    /// Reports an error for analysis
    func reportError(_ error: Error, context: [String: Any] = [:]) {
        guard reportingEnabled else { return }
        
        // In a real app, this would send to analytics/crash reporting service
        let errorReport = ErrorReport(
            error: error,
            context: context,
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        )
        
        // Log locally for debugging
        print("Error Report: \(errorReport)")
        
        // TODO: Send to analytics service
        // Analytics.shared.reportError(errorReport)
    }
    
    /// Allows user to send feedback about an error
    func submitUserFeedback(_ feedback: UserErrorFeedback) {
        // TODO: Send feedback to support system
        print("User Feedback: \(feedback)")
    }
}

/// Error report structure
struct ErrorReport {
    let error: Error
    let context: [String: Any]
    let timestamp: Date
    let appVersion: String
}

/// User feedback about an error
struct UserErrorFeedback {
    let errorId: String
    let userDescription: String
    let reproductionSteps: String?
    let userEmail: String?
    let timestamp: Date
}