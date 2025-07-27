//
//  AnimatedButton.swift
//  IRR Genius
//

import SwiftUI

struct AnimatedButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle.Style
    let size: ButtonStyle.Size
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle.Style = .primary,
        size: ButtonStyle.Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                action()
            }
        }) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
                
                if !title.isEmpty {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(foregroundColor)
            .padding(size.padding)
            .frame(minWidth: minWidth)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: isPressed ? 1 : 2,
                x: 0,
                y: isPressed ? 1 : 2
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.6 : 1.0)
            .animation(AnimationStyle.quick, value: isPressed)
            .animation(AnimationStyle.quick, value: isLoading)
            .animation(AnimationStyle.quick, value: isDisabled)
        }
        .disabled(isDisabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color.backgroundTertiary
        }
        
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
        if isDisabled {
            return .textTertiary
        }
        
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .textPrimary
        case .tertiary:
            return .primaryBlue
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .tertiary:
            return .primaryBlue
        default:
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .tertiary:
            return 1
        default:
            return 0
        }
    }
    
    private var shadowColor: Color {
        if isDisabled {
            return .clear
        }
        
        switch style {
        case .primary, .destructive:
            return backgroundColor.opacity(0.3)
        case .secondary:
            return .black.opacity(0.1)
        case .tertiary:
            return .clear
        }
    }
    
    private var minWidth: CGFloat {
        switch size {
        case .small:
            return 60
        case .medium:
            return 80
        case .large:
            return 120
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let backgroundColor: Color
    let foregroundColor: Color
    
    @State private var isPressed = false
    
    init(
        icon: String,
        backgroundColor: Color = .primaryBlue,
        foregroundColor: Color = .white,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(foregroundColor)
                .frame(width: 56, height: 56)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(
                    color: backgroundColor.opacity(0.3),
                    radius: isPressed ? 4 : 8,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(AnimationStyle.quick, value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Segmented Control
struct AnimatedSegmentedControl<T: Hashable>: View {
    let options: [T]
    let optionLabels: [T: String]
    @Binding var selection: T
    
    @Namespace private var selectionAnimation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                Button(action: {
                    withAnimation(AnimationStyle.spring) {
                        selection = option
                    }
                }) {
                    Text(optionLabels[option] ?? "\(option)")
                        .font(.labelMedium)
                        .fontWeight(.medium)
                        .foregroundColor(selection == option ? .white : .textPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selection == option {
                                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                                        .fill(Color.primaryBlue)
                                        .matchedGeometryEffect(id: "selection", in: selectionAnimation)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.sm)
        .animation(AnimationStyle.spring, value: selection)
    }
}

// MARK: - Toggle Switch
struct AnimatedToggle: View {
    @Binding var isOn: Bool
    let label: String?
    let onColor: Color
    let offColor: Color
    
    init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        onColor: Color = .primaryGreen,
        offColor: Color = .backgroundTertiary
    ) {
        self.label = label
        self._isOn = isOn
        self.onColor = onColor
        self.offColor = offColor
    }
    
    var body: some View {
        HStack {
            if let label = label {
                Text(label)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            
            Button(action: {
                withAnimation(AnimationStyle.spring) {
                    isOn.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isOn ? onColor : offColor)
                        .frame(width: 50, height: 30)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: isOn ? 10 : -10)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        AnimatedButton("Primary Button", icon: "plus") {}
        AnimatedButton("Secondary", style: .secondary) {}
        AnimatedButton("Loading", isLoading: true) {}
        AnimatedButton("Disabled", isDisabled: true) {}
        
        FloatingActionButton(icon: "plus") {}
        
        AnimatedSegmentedControl(
            options: ["Option 1", "Option 2", "Option 3"],
            optionLabels: ["Option 1": "First", "Option 2": "Second", "Option 3": "Third"],
            selection: .constant("Option 1")
        )
        
        AnimatedToggle("Enable notifications", isOn: .constant(true))
    }
    .padding()
}