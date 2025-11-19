//
//  FinePrintApp.swift
//  FinePrint
//
//  Main app entry point
//

/*
 FINEPRINT APP - MAIN ENTRY POINT
 
 This is the main app file that controls the entire application flow.
 
 **For Novice Developers:**
 This file manages the app's navigation between different major screens:
 
 **App Flow:**
 1. SplashView (2 seconds) → Shows app logo and handles initial setup
 2. Then either:
    - OnboardingFlowView → If user hasn't completed onboarding
    - MainView (TabBar) → If user has completed onboarding
 
 **Key Features:**
 - Automatic navigation based on user's onboarding status
 - Smooth transitions between views
 - Essential services configuration (UserManager, Superwall, etc.)
 - Environment objects shared across the app
 
 **To Customize:**
 - Modify splash duration in handleAppLaunch()
 - Add new service configurations in configureUtilities()
 - Update API keys and configuration as needed
 - Add additional environment objects if needed
 
 **Services Configured:**
 - UserManager: User authentication and data management
 - SuperwallService: Paywall and subscription management
 - NotificationManager: Push notifications and badges
 */

import SwiftUI

@main
struct FinePrintApp: App {
    
    // MARK: - State Management
    @StateObject private var userManager = UserManager.shared
    @State private var showSplash = true
    
    init() {
        // Configure essential utilities during app startup
        configureUtilities()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    // Show appropriate view based on onboarding status
                    if userManager.isOnboardingCompleted {
                        MainView()
                            .environmentObject(userManager)
                            .transition(.opacity)
                    } else {
                        OnboardingFlowView {
                            // Mark onboarding as completed when user finishes
                            userManager.completeOnboarding()
                        }
                        .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .animation(.easeInOut(duration: 0.5), value: userManager.isOnboardingCompleted)
            .onAppear {
                handleAppLaunch()
            }
        }
    }
    
    // MARK: - Utility Configuration
    
    private func configureUtilities() {
        // Configure Superwall Service (Full approach as requested)
        configureSuperwallService()
        
        // Configure User Manager (Basic setup)
        configureUserManager()
        
        print("✅ Essential utilities configured")
    }
    
    private func configureSuperwallService() {
        // TODO: Replace with your actual Superwall API key
        let superwallAPIKey = "pk_your_superwall_api_key_here"
        
        #if DEBUG
        SuperwallService.shared.configure(apiKey: superwallAPIKey, debugMode: true)
        #else
        SuperwallService.shared.configure(apiKey: superwallAPIKey, debugMode: false)
        #endif
        
        // Enable analytics integration
        SuperwallService.shared.setAnalyticsTrackingEnabled(true)
        
        print("💰 Superwall Service configured")
    }
    
    private func configureUserManager() {
        #if DEBUG
        UserManager.shared.setDebugMode(true)
        #endif
        
        // Enable auto-sync when app becomes active
        UserManager.shared.setAutoSyncEnabled(true)
        
        // TODO: If using Firebase or Core Data, set custom storage backend here
        // UserManager.shared.setStorageBackend(FirebaseStorage())
        
        print("👤 User Manager configured")
    }
    
    // MARK: - App Launch
    
    /// Handles the complete app launch sequence
    /// This method runs when the app first appears and sets up all necessary services
    private func handleAppLaunch() {
        Task {
            // Step 1: Clear any notification badges from previous sessions
            NotificationManager.shared.clearBadge()
            
            // Step 2: Check if user is already signed in from previous sessions
            let isAuthenticated = await UserManager.shared.checkAuthenticationStatus()
            
            // Step 3: Configure Superwall based on user authentication status
            if isAuthenticated {
                // User is signed in, set up personalized Superwall attributes
                await setupSuperwallForUser()
            } else {
                // User is not signed in, set basic anonymous attributes
                setBasicSuperwallAttributes()
            }
            
            print("🚀 App launch completed - Auth: \(isAuthenticated), Onboarding: \(userManager.isOnboardingCompleted)")
            
            // Step 4: Show splash for minimum 2 seconds for better UX, then transition to main content
            // Note: The actual destination (onboarding vs main app) is determined by userManager.isOnboardingCompleted
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupSuperwallForUser() async {
        guard let user = UserManager.shared.currentUser else { return }
        
        // Update Superwall user attributes for signed-in user
        SuperwallService.shared.setUserAttributes([
            "user_id": user.id,
            "email": user.email ?? "",
            "name": user.name ?? "",
            "account_age_days": Int(Date().timeIntervalSince(user.createdAt) / 86400),
            "onboarding_completed": UserManager.shared.isOnboardingCompleted,
            "user_type": "authenticated"
        ])
        
        print("🔗 Superwall configured for user: \(user.id)")
    }
    
    private func setBasicSuperwallAttributes() {
        // Set basic attributes for anonymous users
        SuperwallService.shared.setUserAttributes([
            "user_type": "anonymous",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "platform": "iOS",
            "device_model": UIDevice.current.model,
            "os_version": UIDevice.current.systemVersion,
            "onboarding_completed": UserManager.shared.isOnboardingCompleted
        ])
        
        print("🔗 Superwall configured for anonymous user")
    }
}
