//
//  AccessibilityComponents.swift
//  IRR Genius
//

import SwiftUI

// MARK: - Accessibility Extensions
extension View {
    func accessibleButton(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    func accessibleTextField(
        label: String,
        value: String,
        hint: String? = nil,
        isSecure: Bool = false
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "")

    }
    
    func accessibleCard(
        label: String,
        value: String? = nil,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
    }
    
    func accessibleHeader(level: Int = 1) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(.h1) // SwiftUI doesn't support dynamic heading levels yet
    }
    
    func accessibleStatus(
        announcement: String
    ) -> some View {
        self
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                }
            }
    }
}

// MARK: - Accessible Input Field
struct AccessibleInputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    let isRequired: Bool
    let errorMessage: String?
    let hint: String?
    
    @FocusState private var isFocused: Bool
    
    init(
        label: String,
        placeholder: String = "",
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        isRequired: Bool = false,
        errorMessage: String? = nil,
        hint: String? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.hint = hint
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label)
                    .font(.labelMedium)
                    .foregroundColor(.textPrimary)
                    .accessibleHeader()
                
                if isRequired {
                    Text("*")
                        .font(.labelMedium)
                        .foregroundColor(.error)
                        .accessibilityLabel("required")
                }
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .focused($isFocused)
            .inputFieldStyle(isError: errorMessage != nil, isFocused: isFocused)
            .accessibleTextField(
                label: "\(label)\(isRequired ? ", required" : "")",
                value: text.isEmpty ? placeholder : text,
                hint: hint ?? (errorMessage != nil ? "Has error: \(errorMessage!)" : ""),
                isSecure: isSecure
            )
            
            if let errorMessage = errorMessage {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.error)
                        .font(.caption)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.error)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error: \(errorMessage)")
                .accessibilityAddTraits(.isStaticText)
            }
        }
    }
}

// MARK: - Accessible Calculation Result Card
struct AccessibleCalculationResultCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let trend: TrendDirection?
    let onTap: (() -> Void)?
    
    enum TrendDirection {
        case up, down, neutral
        
        var description: String {
            switch self {
            case .up:
                return "trending up"
            case .down:
                return "trending down"
            case .neutral:
                return "no change"
            }
        }
        
        var color: Color {
            switch self {
            case .up:
                return .investmentPositive
            case .down:
                return .investmentNegative
            case .neutral:
                return .investmentNeutral
            }
        }
        
        var icon: String {
            switch self {
            case .up:
                return "arrow.up.right"
            case .down:
                return "arrow.down.right"
            case .neutral:
                return "minus"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(.titleMedium)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .foregroundColor(trend.color)
                        .font(.caption)
                }
            }
            
            Text(value)
                .font(.headlineMedium)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(Spacing.md)
        .cardStyle()
        .onTapGesture {
            onTap?()
        }
        .accessibleCard(
            label: accessibilityLabel,
            hint: onTap != nil ? "Double tap to view details" : ""
        )
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }
    
    private var accessibilityLabel: String {
        var label = "\(title): \(value)"
        
        if let subtitle = subtitle {
            label += ", \(subtitle)"
        }
        
        if let trend = trend {
            label += ", \(trend.description)"
        }
        
        return label
    }
}

// MARK: - Accessible Progress View
struct AccessibleProgressView: View {
    let label: String
    let progress: Double
    let total: Double?
    let showPercentage: Bool
    
    init(
        label: String,
        progress: Double,
        total: Double? = nil,
        showPercentage: Bool = true
    ) {
        self.label = label
        self.progress = progress
        self.total = total
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label)
                    .font(.labelMedium)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if showPercentage {
                    Text(percentageText)
                        .font(.labelSmall)
                        .foregroundColor(.textSecondary)
                }
            }
            
            ProgressIndicator(progress: progress)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    private var percentageText: String {
        if let total = total {
            return "\(Int(progress))/\(Int(total))"
        } else {
            return "\(Int(progress * 100))%"
        }
    }
    
    private var accessibilityLabel: String {
        return "\(label) progress"
    }
    
    private var accessibilityValue: String {
        if let total = total {
            return "\(Int(progress)) of \(Int(total)) completed"
        } else {
            return "\(Int(progress * 100)) percent complete"
        }
    }
}

// MARK: - Accessible List Item
struct AccessibleListItem<Content: View>: View {
    let title: String
    let subtitle: String?
    let accessoryText: String?
    let onTap: (() -> Void)?
    let content: () -> Content
    
    init(
        title: String,
        subtitle: String? = nil,
        accessoryText: String? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessoryText = accessoryText
        self.onTap = onTap
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if let accessoryText = accessoryText {
                    Text(accessoryText)
                        .font(.labelMedium)
                        .foregroundColor(.textSecondary)
                }
                
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
            
            content()
        }
        .padding(Spacing.md)
        .background(Color.backgroundPrimary)
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(onTap != nil ? "Double tap to select" : "")
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }
    
    private var accessibilityLabel: String {
        var label = title
        
        if let subtitle = subtitle {
            label += ", \(subtitle)"
        }
        
        if let accessoryText = accessoryText {
            label += ", \(accessoryText)"
        }
        
        return label
    }
}

// MARK: - Accessibility Announcements
struct AccessibilityAnnouncement {
    static func announce(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    static func announcePageChange(_ pageName: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .screenChanged, argument: pageName)
        }
    }
    
    static func announceLayoutChange(focusElement: Any? = nil) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: focusElement)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: Spacing.lg) {
        AccessibleInputField(
            label: "Investment Amount",
            placeholder: "Enter amount",
            text: .constant("100000"),
            keyboardType: .decimalPad,
            isRequired: true,
            hint: "Enter the initial investment amount in dollars"
        )
        
        AccessibleCalculationResultCard(
            title: "IRR",
            value: "22.47%",
            subtitle: "Internal Rate of Return",
            trend: .up
        ) {
            print("Card tapped")
        }
        
        AccessibleProgressView(
            label: "Calculation Progress",
            progress: 0.75
        )
        
        AccessibleListItem(
            title: "Real Estate Investment",
            subtitle: "Created 2 days ago",
            accessoryText: "22.47%"
        ) {
            print("List item tapped")
        }
    }
    .padding()
}