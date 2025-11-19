//
//  welcomeView.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

import SwiftUI

/// Welcome View - First screen in the onboarding flow
/// Minimal placeholder view to welcome users to the app
struct WelcomeView: View {
    
    // MARK: - Properties
    
    /// Callback function to handle navigation to the next screen
    let onContinue: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App Icon placeholder
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(Color.primaryMain)
            
            // Welcome message
            Text("Welcome to Your App")
                .font(.displayLarge)
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("This is your welcome screen placeholder")
                .font(.bodyMedium)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Button area - consistent positioning across all onboarding screens
            VStack(spacing: 16) {
                Button("Get Started") {
                    onContinue()
                }
                .buttonStyle(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Preview

#Preview("Welcome View") {
    WelcomeView {
        print("Continue tapped")
    }
}

#Preview("Dark Mode") {
    WelcomeView {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}

