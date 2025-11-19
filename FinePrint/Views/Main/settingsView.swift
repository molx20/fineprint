//
//  settingsView.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 SETTINGS VIEW - SIMPLIFIED APP PREFERENCES
 
 This view provides users with essential settings and configuration options.
 
 **For Novice Developers:**
 - This view is part of the main tab bar navigation
 - Simplified structure with only essential settings
 - Uses grouped list style for native iOS appearance
 - Includes developer tools in debug builds only
 
 **Current Sections:**
 1. App Preferences - Notifications
 2. Support - Contact founder and rate app
 3. Legal - Terms and privacy policy
 4. About - App version information
 5. Developer (DEBUG only) - Development and testing tools
 
 **To Customize:**
 1. Add new sections by creating new SettingRow structs
 2. Modify existing settings to match your app's needs
 3. Update contact information and URLs
 4. Update the developer section with your testing needs
 
 **Developer Section:**
 - Only visible in DEBUG builds (development/testing)
 - Includes tools like onboarding reset, data cleanup
 - Hidden in production builds for security
 */

import SwiftUI

struct SettingsView: View {
    
    // MARK: - Properties
    
    /// User manager for state management
    @StateObject private var userManager = UserManager.shared
    
    /// Superwall service for paywall management
    private let superwallService = SuperwallService.shared
    
    /// Show onboarding flow
    @State private var showOnboarding = false
    
    /// Show confirmation alerts
    @State private var showResetAlert = false
    @State private var showSignOutAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                
                // MARK: - App Preferences Section
                Section {
                    SettingRow(
                        icon: "bell",
                        title: "Notifications",
                        subtitle: "Manage notification preferences"
                    ) {
                        // Handle notifications settings
                        openNotificationSettings()
                    }
                } header: {
                    Text("App Preferences")
                }
                
                // MARK: - Support Section
                Section {
                    SettingRow(
                        icon: "envelope.circle",
                        title: "Contact Founder",
                        subtitle: "Get in touch with the founder"
                    ) {
                        // Handle contact founder
                        contactFounder()
                    }
                    
                    SettingRow(
                        icon: "star.circle",
                        title: "Rate App",
                        subtitle: "Leave a review on the App Store"
                    ) {
                        // Handle rate app
                        openAppStoreRating()
                    }
                } header: {
                    Text("Support")
                }
                
                // MARK: - Legal Section
                Section {
                    SettingRow(
                        icon: "doc.text",
                        title: "Terms of Service",
                        subtitle: "Read our terms of service"
                    ) {
                        // Handle terms of service
                        openTermsOfService()
                    }
                    
                    SettingRow(
                        icon: "hand.raised",
                        title: "Privacy Policy",
                        subtitle: "Read our privacy policy"
                    ) {
                        // Handle privacy policy
                        openPrivacyPolicy()
                    }
                } header: {
                    Text("Legal")
                }
                
                // MARK: - About Section
                Section {
                    AboutRow(
                        title: "Version",
                        value: getAppVersion()
                    )
                    
                    AboutRow(
                        title: "Build",
                        value: getBuildNumber()
                    )
                } header: {
                    Text("About")
                }
                
                // MARK: - Developer Section (DEBUG only)
                #if DEBUG
                Section {
                    DeveloperSection()
                } header: {
                    Text("Developer Tools")
                } footer: {
                    Text("This section is only visible in development builds and will not appear in the App Store version.")
                        .font(.captionSmall)
                        .foregroundColor(Color.textSecondary)
                }
                #endif
                
                // MARK: - Sign Out Section
                if userManager.isSignedIn {
                    Section {
                        Button("Sign Out") {
                            showSignOutAlert = true
                        }
                        .foregroundColor(Color.error)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.backgroundPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingFlowView {
                showOnboarding = false
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await userManager.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Reset Data", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will reset all app data and restart onboarding. This action cannot be undone.")
        }
    }
    
    // MARK: - Methods
    
    /// Opens notification settings
    private func openNotificationSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
    
    /// Contact the founder via email
    private func contactFounder() {
        // Replace with your actual email
        if let url = URL(string: "mailto:founder@yourapp.com?subject=App%20Feedback") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Opens App Store rating
    private func openAppStoreRating() {
        // Replace with your actual App Store ID
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Opens privacy policy
    private func openPrivacyPolicy() {
        // Replace with your actual privacy policy URL
        if let url = URL(string: "https://yourapp.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Opens terms of service
    private func openTermsOfService() {
        // Replace with your actual terms URL
        if let url = URL(string: "https://yourapp.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Gets app version
    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Gets build number
    private func getBuildNumber() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Resets all app data (developer function)
    private func resetAllData() {
        // Reset UserManager
        Task {
            await userManager.resetAllUserData()
        }
        
        // Reset Superwall
        superwallService.resetUserData()
        
        // Reset onboarding status
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        
        print("🔄 All app data reset")
    }
}

// MARK: - Setting Row

private struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                                            .foregroundColor(Color.primaryMain)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.bodyMedium)
                        .foregroundColor(Color.textPrimary)
                    
                    Text(subtitle)
                        .font(.captionMedium)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.captionLarge)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - About Row

private struct AboutRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.bodyMedium)
                .foregroundColor(Color.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.bodyMedium)
                .foregroundColor(Color.textSecondary)
        }
    }
}

// MARK: - Developer Section (DEBUG only)

#if DEBUG
private struct DeveloperSection: View {
    @State private var showOnboarding = false
    @State private var showResetAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Start Onboarding Button
            Button(action: {
                showOnboarding = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color.primaryMain)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start Onboarding")
                            .font(.bodyMedium)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Reset and show onboarding flow")
                            .font(.captionMedium)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            Divider()
                .padding(.vertical, 8)
            
            // Reset All Data Button
            Button(action: {
                showResetAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color.error)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Data")
                            .font(.bodyMedium)
                            .foregroundColor(Color.error)
                        
                        Text("Clear all app data and preferences")
                            .font(.captionMedium)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            Divider()
                .padding(.vertical, 8)
            
            // Debug Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Debug Information")
                    .font(.headlineSmall)
                    .foregroundColor(Color.textPrimary)
                
                DebugInfoRow(title: "User Manager", value: UserManager.shared.isSignedIn ? "Signed In" : "Not Signed In")
                DebugInfoRow(title: "Onboarding", value: UserManager.shared.isOnboardingCompleted ? "Completed" : "Not Completed")
                DebugInfoRow(title: "Build Config", value: "DEBUG")
                DebugInfoRow(title: "Simulator", value: isRunningInSimulator() ? "Yes" : "No")
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingFlowView {
                showOnboarding = false
                // Reset onboarding status to allow it to show again
                UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            }
        }
        .alert("Reset All Data", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllAppData()
            }
        } message: {
            Text("This will reset all app data including user preferences, onboarding status, and cached data. This action cannot be undone.")
        }
    }
    
    /// Debug info row component
    private struct DebugInfoRow: View {
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.captionMedium)
                    .foregroundColor(Color.textSecondary)
                
                Spacer()
                
                Text(value)
                    .font(.captionMedium)
                    .foregroundColor(Color.textPrimary)
            }
        }
    }
    
    /// Check if running in simulator
    private func isRunningInSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// Reset all app data
    private func resetAllAppData() {
        // Reset UserManager
        Task {
            await UserManager.shared.resetAllUserData()
        }
        
        // Reset Superwall
        SuperwallService.shared.resetUserData()
        
        // Reset onboarding
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        
        // Reset any other app-specific data
        UserDefaults.standard.removeObject(forKey: "first_launch_date")
        
        print("🔄 All app data reset from developer tools")
    }
}
#endif

// MARK: - Preview

#Preview("Settings View") {
    SettingsView()
}

#Preview("Dark Mode") {
    SettingsView()
        .preferredColorScheme(.dark)
}

