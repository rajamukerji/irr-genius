//
//  EnhancedTheme.swift
//  IRR Genius
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    // Primary Colors
    static let primaryBlue = Color(red: 0.29, green: 0.56, blue: 0.89) // #4A90E2
    static let primaryGreen = Color(red: 0.31, green: 0.89, blue: 0.76) // #50E3C2
    static let primaryOrange = Color(red: 0.96, green: 0.65, blue: 0.14) // #F5A623

    // Semantic Colors
    static let success = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
    static let warning = Color(red: 1.00, green: 0.58, blue: 0.00) // #FF9500
    static let error = Color(red: 1.00, green: 0.23, blue: 0.19) // #FF3B30
    static let info = Color(red: 0.35, green: 0.34, blue: 0.84) // #5856D6

    // Background Colors
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    // Text Colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // Card Colors
    static let cardBackground = Color(.systemBackground)
    static let cardBorder = Color(.separator)

    // Investment Type Colors
    static let investmentPositive = success
    static let investmentNegative = error
    static let investmentNeutral = Color(.systemGray)
}

// MARK: - Font Extensions

extension Font {
    // Display Fonts
    static let displayLarge = Font.system(size: 57, weight: .regular)
    static let displayMedium = Font.system(size: 45, weight: .regular)
    static let displaySmall = Font.system(size: 36, weight: .regular)

    // Headline Fonts
    static let headlineLarge = Font.system(size: 32, weight: .regular)
    static let headlineMedium = Font.system(size: 28, weight: .regular)
    static let headlineSmall = Font.system(size: 24, weight: .regular)

    // Title Fonts
    static let titleLarge = Font.system(size: 22, weight: .medium)
    static let titleMedium = Font.system(size: 16, weight: .medium)
    static let titleSmall = Font.system(size: 14, weight: .medium)

    // Body Fonts
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall = Font.system(size: 12, weight: .regular)

    // Label Fonts
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)
}

// MARK: - Spacing System

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius System

enum CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let round: CGFloat = 50
}

// MARK: - Shadow System

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let none = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
    static let small = ShadowStyle(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    static let large = ShadowStyle(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    static let xl = ShadowStyle(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
}

// MARK: - Animation System

enum AnimationStyle {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.6)
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    let shadow: ShadowStyle
    let cornerRadius: CGFloat
    let backgroundColor: Color

    init(
        shadow: ShadowStyle = .medium,
        cornerRadius: CGFloat = CornerRadius.md,
        backgroundColor: Color = .cardBackground
    ) {
        self.shadow = shadow
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

struct ButtonStyle: ViewModifier {
    enum Style {
        case primary
        case secondary
        case tertiary
        case destructive
    }

    let style: Style
    let size: Size

    enum Size {
        case small
        case medium
        case large

        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: Spacing.xs, leading: Spacing.sm, bottom: Spacing.xs, trailing: Spacing.sm)
            case .medium:
                return EdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.sm, trailing: Spacing.md)
            case .large:
                return EdgeInsets(top: Spacing.md, leading: Spacing.lg, bottom: Spacing.md, trailing: Spacing.lg)
            }
        }

        var font: Font {
            switch self {
            case .small:
                return .labelSmall
            case .medium:
                return .labelMedium
            case .large:
                return .labelLarge
            }
        }
    }

    init(style: Style = .primary, size: Size = .medium) {
        self.style = style
        self.size = size
    }

    func body(content: Content) -> some View {
        content
            .font(size.font)
            .padding(size.padding)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(CornerRadius.sm)
            .shadow(
                color: shadowColor,
                radius: 2,
                x: 0,
                y: 1
            )
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .primaryBlue
        case .secondary:
            return .backgroundSecondary
        case .tertiary:
            return .clear
        case .destructive:
            return .error
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .textPrimary
        case .tertiary:
            return .primaryBlue
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary, .destructive:
            return backgroundColor.opacity(0.3)
        case .secondary:
            return .black.opacity(0.1)
        case .tertiary:
            return .clear
        }
    }
}

struct InputFieldStyle: ViewModifier {
    let isError: Bool
    let isFocused: Bool

    init(isError: Bool = false, isFocused: Bool = false) {
        self.isError = isError
        self.isFocused = isFocused
    }

    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .animation(AnimationStyle.quick, value: isFocused)
            .animation(AnimationStyle.quick, value: isError)
    }

    private var borderColor: Color {
        if isError {
            return .error
        } else if isFocused {
            return .primaryBlue
        } else {
            return .cardBorder
        }
    }

    private var borderWidth: CGFloat {
        if isError || isFocused {
            return 2
        } else {
            return 1
        }
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(
        shadow: ShadowStyle = .medium,
        cornerRadius: CGFloat = CornerRadius.md,
        backgroundColor: Color = .cardBackground
    ) -> some View {
        modifier(CardStyle(shadow: shadow, cornerRadius: cornerRadius, backgroundColor: backgroundColor))
    }

    func buttonStyle(
        style: ButtonStyle.Style = .primary,
        size: ButtonStyle.Size = .medium
    ) -> some View {
        modifier(ButtonStyle(style: style, size: size))
    }

    func inputFieldStyle(isError: Bool = false, isFocused: Bool = false) -> some View {
        modifier(InputFieldStyle(isError: isError, isFocused: isFocused))
    }

    func fadeInOut(isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
            .animation(AnimationStyle.smooth, value: isVisible)
    }

    func slideInOut(isVisible: Bool, edge: Edge = .bottom) -> some View {
        offset(y: isVisible ? 0 : (edge == .bottom ? 50 : -50))
            .opacity(isVisible ? 1 : 0)
            .animation(AnimationStyle.spring, value: isVisible)
    }

    func scaleEffect(isPressed: Bool) -> some View {
        scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(AnimationStyle.quick, value: isPressed)
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    enum Status {
        case success
        case warning
        case error
        case info
        case loading

        var color: Color {
            switch self {
            case .success:
                return .success
            case .warning:
                return .warning
            case .error:
                return .error
            case .info:
                return .info
            case .loading:
                return .primaryBlue
            }
        }

        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .error:
                return "xmark.circle.fill"
            case .info:
                return "info.circle.fill"
            case .loading:
                return "arrow.clockwise"
            }
        }
    }

    let status: Status
    let message: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .rotationEffect(.degrees(status == .loading ? 360 : 0))
                .animation(
                    status == .loading ?
                        Animation.linear(duration: 1).repeatForever(autoreverses: false) :
                        .none,
                    value: status == .loading
                )

            Text(message)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
        }
        .padding(Spacing.md)
        .background(status.color.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
        .fadeInOut(isVisible: isVisible)
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let progress: Double
    let color: Color
    let backgroundColor: Color

    init(
        progress: Double,
        color: Color = .primaryBlue,
        backgroundColor: Color = .backgroundTertiary
    ) {
        self.progress = progress
        self.color = color
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)

                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(progress))
                    .animation(AnimationStyle.smooth, value: progress)
            }
        }
        .frame(height: 4)
        .cornerRadius(2)
    }
}
