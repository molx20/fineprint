//
//  mainView.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 MAIN VIEW - TAB BAR CONTAINER
 
 This is the main container view that holds the tab bar navigation.
 
 **For Novice Developers:**
 - This view contains the main TabView that users see after onboarding
 - Simple two-tab structure: Home and Settings
 - Easy to add/remove tabs by modifying the TabView structure
 - Uses the theme system for consistent styling
 - Integrates with UserManager for state management
 
 **Current Tabs:**
 1. Home - Main app content and dashboard
 2. Settings - App settings and preferences
 
 **To Customize:**
 1. Add new tabs by adding more cases to the Tab enum
 2. Create corresponding view files for new tabs
 3. Update tab icons and titles to match your app
 4. Modify the tab order by changing the order in TabView
 
 **Integration:**
 - Observes UserManager for state changes
 - Handles dynamic tab content based on user status
 - Supports deep linking and programmatic tab switching
 */

import SwiftUI

struct MainView: View {
    
    // MARK: - Properties
    
    /// Current selected tab
    @State private var selectedTab: Tab = .home
    
    /// User manager for state management
    @StateObject private var userManager = UserManager.shared
    
    // MARK: - Tab Definition
    
    /// Available tabs in the app
    enum Tab: String, CaseIterable {
        case home = "home"
        case settings = "settings"
        
        /// Tab display title
        var title: String {
            switch self {
            case .home: return "Home"
            case .settings: return "Settings"
            }
        }
        
        /// Tab icon (system name)
        var icon: String {
            switch self {
            case .home: return "house"
            case .settings: return "gearshape"
            }
        }
        
        /// Tab icon when selected
        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == .home ? Tab.home.selectedIcon : Tab.home.icon)
                    Text(Tab.home.title)
                }
                .tag(Tab.home)
            
            // MARK: - Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == .settings ? Tab.settings.selectedIcon : Tab.settings.icon)
                    Text(Tab.settings.title)
                }
                .tag(Tab.settings)
        }
                        .accentColor(Color.primaryMain)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    // MARK: - Methods
    
    /// Configures the tab bar appearance using the theme system
    private func setupTabBarAppearance() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.backgroundPrimary)
        
        // Configure selected item appearance
                    appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.primaryMain)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.primaryMain)
        ]
        
        // Configure normal item appearance
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.textSecondary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    /// Programmatically switch to a specific tab
    /// - Parameter tab: The tab to switch to
    func switchToTab(_ tab: Tab) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = tab
        }
    }
}

// HomeView is now defined in homeView.swift

// MARK: - Preview

#Preview("Main View") {
    MainView()
}

#Preview("Dark Mode") {
    MainView()
        .preferredColorScheme(.dark)
}

