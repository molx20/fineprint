//
//  Fonts.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 FONT REFERENCE GUIDE
 
 Available Font Weights:
 - .ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black
 
 Available Font Designs:
 - .default (San Francisco - iOS system font)
 - .rounded (San Francisco Rounded - friendly, modern look)
 - .monospaced (San Francisco Mono - fixed-width for code/numbers)
 - .serif (New York - elegant serif font)
 
 Usage Examples:
 - Font.system(size: 16, weight: .bold, design: .rounded)
 - Font.system(size: 14, weight: .medium, design: .monospaced)
 - Font.system(size: 18, weight: .semibold, design: .serif)
 */

import SwiftUI

extension Font {
    // MARK: - Display Fonts (Large Titles)
    static let displayLarge = Font.system(size: 36, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 32, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 28, weight: .bold, design: .default)
    
    // MARK: - Title Fonts
    static let titleLarge = Font.system(size: 24, weight: .bold, design: .default)
    static let titleMedium = Font.system(size: 22, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Headline Fonts
    static let headlineLarge = Font.system(size: 18, weight: .semibold, design: .default)
    static let headlineMedium = Font.system(size: 17, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 16, weight: .medium, design: .default)
    
    // MARK: - Body Fonts
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 15, weight: .regular, design: .default)
    
    // MARK: - Label Fonts
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)
    
    // MARK: - Caption Fonts
    static let captionLarge = Font.system(size: 12, weight: .regular, design: .default)
    static let captionMedium = Font.system(size: 11, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)
    
    // MARK: - Button Fonts
    static let buttonLarge = Font.system(size: 18, weight: .semibold, design: .default)
    static let buttonMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let buttonSmall = Font.system(size: 14, weight: .medium, design: .default)
    
    // MARK: - Specialized Fonts
    static let navigationTitle = Font.system(size: 20, weight: .semibold, design: .default)
    static let tabBarItem = Font.system(size: 12, weight: .medium, design: .default)
    static let footnote = Font.system(size: 11, weight: .regular, design: .default)
    static let overline = Font.system(size: 10, weight: .medium, design: .default).uppercaseSmallCaps()
    
    // MARK: - Monospaced Fonts (for code, numbers)
    static let codeLarge = Font.system(size: 16, weight: .regular, design: .monospaced)
    static let codeMedium = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let codeSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
    
    // MARK: - Rounded Fonts (for friendly UI)
    static let roundedLarge = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let roundedMedium = Font.system(size: 16, weight: .medium, design: .rounded)
    static let roundedSmall = Font.system(size: 14, weight: .medium, design: .rounded)
}

