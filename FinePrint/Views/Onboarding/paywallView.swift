//
//  paywallView.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 PAYWALL VIEW - SUPERWALL PLACEHOLDER
 
 This is a placeholder for where your Superwall paywall will be displayed.
 
 **For Novice Developers:**
 - This view shows where your actual Superwall paywall will appear
 - Replace this placeholder with your Superwall integration
 - The onContinue and onSkip callbacks handle user actions
 - Integrates with the theme system for consistent styling
 
 **To Implement Real Paywall:**
 1. Set up your Superwall dashboard and configure paywalls
 2. Replace this placeholder with Superwall's PaywallView
 3. Handle subscription success/failure callbacks
 4. Add analytics tracking for conversion optimization
 
 **Superwall Integration:**
 - Use SuperwallService.shared.register() to trigger paywalls
 - Configure your paywall templates in the Superwall dashboard
 - Handle purchase events and subscription status
 */

import SwiftUI

struct PaywallView: View {
    
    // MARK: - Properties
    
    /// Callback when user chooses to continue with premium
    let onContinue: () -> Void
    
    /// Callback when user chooses to skip the paywall
    let onSkip: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Superwall icon placeholder
            Image(systemName: "crown")
                .font(.system(size: 80))
                .foregroundColor(Color.primaryMain)
            
            // Placeholder title
            Text("Superwall Paywall")
                .font(.displayMedium)
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("This is where your Superwall paywall will show")
                .font(.bodyMedium)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("Replace this placeholder with your actual Superwall integration")
                .font(.captionLarge)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Button area - consistent positioning across all onboarding screens
            VStack(spacing: 16) {
                Button("Continue with Premium") {
                    onContinue()
                }
                .buttonStyle(.primary)
                
                // Skip as tappable text
                Button("Skip for Now") {
                    onSkip()
                }
                .foregroundColor(Color.textSecondary)
                .font(.bodyMedium)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Preview

#Preview("Paywall View") {
    PaywallView(
        onContinue: {
            print("User chose premium!")
        },
        onSkip: {
            print("User skipped paywall")
        }
    )
}

#Preview("Dark Mode") {
    PaywallView(
        onContinue: { },
        onSkip: { }
    )
    .preferredColorScheme(.dark)
}
