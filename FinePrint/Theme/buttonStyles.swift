//
//  buttonStyles.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 BUTTON STYLES REFERENCE GUIDE
 
 Available Button Styles:
 - Primary: Main action buttons with accent color
 - Secondary: Secondary actions with outline style
 - Icon: Circular buttons for icons
 - Small/Medium/Large: Different sizes for various contexts
 - Destructive: For delete/warning actions
 - Ghost: Minimal style with no background
 
 Usage Examples:
 Button("Save") { }.buttonStyle(.primary)
 Button("Cancel") { }.buttonStyle(.secondary)
 Button { } label: { Image(systemName: "heart") }.buttonStyle(.iconSmall)
 
 Tips:
 - Use .primary for main CTAs
 - Use .secondary for less important actions
 - Use .icon styles for toolbar and navigation
 - Use .destructive for delete/warning actions
 */

import SwiftUI

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.primaryMain)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundColor(.primaryMain)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.backgroundPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.border, lineWidth: 1)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Large Button Style
struct LargeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonLarge)
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(.primaryMain)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Small Button Style
struct SmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonSmall)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.primaryMain)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Styles
struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    
    init(size: CGFloat = 44) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primaryMain)
            .frame(width: size, height: size)
            .background(.backgroundSecondary)
            .cornerRadius(size / 2)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.error)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundColor(.primaryMain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? .backgroundSecondary : .clear)
            .cornerRadius(6)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == LargeButtonStyle {
    static var large: LargeButtonStyle { LargeButtonStyle() }
}

extension ButtonStyle where Self == SmallButtonStyle {
    static var small: SmallButtonStyle { SmallButtonStyle() }
}

extension ButtonStyle where Self == IconButtonStyle {
    static var icon: IconButtonStyle { IconButtonStyle() }
    static var iconSmall: IconButtonStyle { IconButtonStyle(size: 32) }
    static var iconLarge: IconButtonStyle { IconButtonStyle(size: 56) }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    static var destructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}

