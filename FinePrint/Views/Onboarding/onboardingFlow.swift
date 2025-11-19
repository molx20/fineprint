//
//  onboardingFlow.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

import SwiftUI

/// Onboarding Flow Coordinator
/// This coordinator manages the entire onboarding experience and navigation between screens.
/// 
/// **For Novice Developers:**
/// - This is where you control which screens appear and in what order
/// - You can easily add/remove screens by modifying the OnboardingStep enum
/// - The coordinator handles all navigation logic so individual views stay simple
/// 
/// **Current Flow:**
/// 1. Welcome Screen -> introduces the app
/// 2. Paywall Screen -> presents premium features
/// 3. Question Screen -> collects user preferences
/// 4. Complete -> returns to main app
/// 
/// **Developer Features (DEBUG only):**
/// - Red "SKIP" button in top-right corner bypasses entire onboarding flow
/// - Only visible during development, hidden in production builds
/// - Useful for quickly testing the main app without going through onboarding
struct OnboardingFlowView: View {
    
    // MARK: - Properties
    
    /// Tracks the current step in the onboarding process
    /// This state drives which view is currently displayed
    @State private var currentStep: OnboardingStep = .welcome
    
    /// Flag to track if onboarding is completed
    /// When true, this view can be dismissed and the main app shown
    @State private var isCompleted = false
    
    /// Callback to handle when onboarding is fully completed
    /// This allows the parent view to know when to show the main app
    let onComplete: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main onboarding content
            Group {
                // Switch between different onboarding screens based on current step
                switch currentStep {
                case .welcome:
                    WelcomeView {
                        moveToNextStep()
                    }
                    
                case .paywall:
                    PaywallView(
                        onContinue: {
                            moveToNextStep()
                        },
                        onSkip: {
                            // Skip paywall and go to next step
                            moveToNextStep()
                        }
                    )
                    
                case .questions:
                    QuestionView {
                        moveToNextStep()
                    }
                    
                case .completed:
                    // This case triggers the completion
                    Color.clear
                        .onAppear {
                            completeOnboarding()
                        }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: currentStep)
            
            // MARK: - Developer Skip Button (DEBUG only)
            #if DEBUG
            VStack {
                HStack {
                    Spacer()
                    
                    // Skip Onboarding Button
                    Button(action: {
                        skipOnboardingForDevelopment()
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 10, weight: .bold))
                            
                            Text("DEV")
                                .font(.system(size: 6, weight: .bold))
                            
                            Text("SKIP")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                    }
                    .padding(.top, 60) // Below status bar
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
            #endif
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Moves to the next step in the onboarding flow
    /// This method contains the logic for determining what comes next
    private func moveToNextStep() {
        withAnimation {
            switch currentStep {
            case .welcome:
                currentStep = .paywall
                
            case .paywall:
                currentStep = .questions
                
            case .questions:
                currentStep = .completed
                
            case .completed:
                // Already at the end
                completeOnboarding()
            }
        }
    }
    
    /// Completes the onboarding process
    /// This method handles any final setup and notifies the parent
    private func completeOnboarding() {
        // Mark onboarding as completed in UserDefaults
        // This prevents the onboarding from showing again
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Add haptic feedback for completion
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        // Notify parent that onboarding is complete
        onComplete()
    }
    
    #if DEBUG
    /// Skip onboarding completely (development only)
    /// This method bypasses all onboarding steps and goes directly to the main app
    private func skipOnboardingForDevelopment() {
        print("🚧 DEV: Skipping onboarding flow")
        
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Complete onboarding immediately
        completeOnboarding()
    }
    #endif
    
    // MARK: - Helper Methods for Customization
    
    /// Allows jumping to a specific step (useful for testing or special cases)
    /// **For Novice Developers:** You can call this method to skip to any step during development
    func jumpToStep(_ step: OnboardingStep) {
        withAnimation {
            currentStep = step
        }
    }
    
    /// Returns whether we can go back to a previous step
    /// Currently onboarding is forward-only, but you can modify this for back navigation
    var canGoBack: Bool {
        currentStep != .welcome
    }
    
    /// Goes back to the previous step (if back navigation is enabled)
    /// **For Novice Developers:** Uncomment and modify this if you want back buttons
    func goBack() {
        withAnimation {
            switch currentStep {
            case .paywall:
                currentStep = .welcome
            case .questions:
                currentStep = .paywall
            case .completed:
                currentStep = .questions
            case .welcome:
                break // Can't go back from welcome
            }
        }
    }
}

// MARK: - Onboarding Steps Enum

/// Defines all possible steps in the onboarding flow
/// **For Novice Developers:** Add new cases here to create new onboarding screens
enum OnboardingStep: CaseIterable {
    case welcome    // First screen - introduces the app
    case paywall    // Second screen - presents premium features
    case questions  // Third screen - collects user preferences
    case completed  // Final state - triggers completion
    
    /// Human-readable name for each step (useful for debugging)
    var name: String {
        switch self {
        case .welcome: return "Welcome"
        case .paywall: return "Paywall"
        case .questions: return "Questions"
        case .completed: return "Completed"
        }
    }
    
    /// Progress percentage for each step (useful for progress indicators)
    var progress: Double {
        switch self {
        case .welcome: return 0.25
        case .paywall: return 0.5
        case .questions: return 0.75
        case .completed: return 1.0
        }
    }
}

// MARK: - Onboarding Helper

/// Helper struct to check onboarding status throughout the app
/// **For Novice Developers:** Use this to check if a user has completed onboarding
struct OnboardingHelper {
    
    /// Check if user has completed onboarding
    static var hasCompletedOnboarding: Bool {
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    /// Reset onboarding status (useful for testing or if user wants to see onboarding again)
    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
    
    /// Mark onboarding as completed manually (useful for special cases)
    static func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Preview

/// Preview for development and testing
/// Shows the onboarding flow starting from the welcome screen
#Preview("Onboarding Flow") {
    OnboardingFlowView {
        print("Onboarding completed!")
    }
}

/// Preview starting from a specific step (useful for testing individual screens)
#Preview("Paywall Step") {
    OnboardingFlowView {
        print("Onboarding completed!")
    }
    .onAppear {
        // Note: This won't work in preview, but shows the pattern for testing
        // In actual app, you could create the view with a specific starting step
    }
}
