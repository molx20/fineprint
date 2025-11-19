//
//  userManager.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 USER MANAGER REFERENCE GUIDE
 
 Features:
 - User authentication state management
 - Onboarding completion tracking
 - User profile data management
 - Flexible storage backends (UserDefaults, Firebase, Core Data, etc.)
 - Integration with existing utilities (Superwall, Notifications, API)
 - Session management and persistence
 - User preferences and settings
 - Easy logout and data cleanup
 
 Usage Examples:
 // Check user state
 let isSignedIn = UserManager.shared.isSignedIn
 let needsOnboarding = !UserManager.shared.isOnboardingCompleted
 
 // Sign in user
 try await UserManager.shared.signIn(userId: "123", email: "user@example.com")
 
 // Complete onboarding
 UserManager.shared.completeOnboarding()
 
 // Update user data
 UserManager.shared.updateUserData(["name": "John Doe", "plan": "premium"])
 
 // Sign out
 await UserManager.shared.signOut()
 
 Configuration:
 - Set storage backend: UserManager.shared.setStorageBackend(FirebaseStorage())
 - Configure auto-sync: UserManager.shared.setAutoSyncEnabled(true)
 - Set debug mode: UserManager.shared.setDebugMode(true)
 */

import Foundation
import Combine
import UIKit  // Added for UIApplication notifications

// MARK: - User Manager Error Types
enum UserManagerError: LocalizedError {
    case notSignedIn
    case invalidUserData
    case storageError(Error)
    case networkError(Error)
    case authenticationFailed
    case userNotFound
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "User is not signed in"
        case .invalidUserData:
            return "Invalid user data provided"
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed"
        case .userNotFound:
            return "User not found"
        case .dataCorrupted:
            return "User data is corrupted"
        }
    }
}

// MARK: - User Model
struct User: Codable {
    let id: String
    let email: String?
    let name: String?
    let avatarURL: String?
    let createdAt: Date
    let lastLoginAt: Date
    
    // User preferences
    var preferences: [String: Any] {
        get { _preferences }
        set { _preferences = newValue }
    }
    
    // Custom data for app-specific fields
    var customData: [String: Any] {
        get { _customData }
        set { _customData = newValue }
    }
    
    // Private storage for Any types (since Codable doesn't support Any directly)
    private var _preferences: [String: Any] = [:]
    private var _customData: [String: Any] = [:]
    
    init(id: String, email: String? = nil, name: String? = nil, avatarURL: String? = nil, createdAt: Date = Date(), lastLoginAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarURL = avatarURL
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, email, name, avatarURL, createdAt, lastLoginAt, preferences, customData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastLoginAt = try container.decode(Date.self, forKey: .lastLoginAt)
        
        // Decode dictionaries as [String: Any]
        if let prefsData = try container.decodeIfPresent(Data.self, forKey: .preferences),
           let prefs = try JSONSerialization.jsonObject(with: prefsData) as? [String: Any] {
            _preferences = prefs
        }
        
        if let customData = try container.decodeIfPresent(Data.self, forKey: .customData),
           let custom = try JSONSerialization.jsonObject(with: customData) as? [String: Any] {
            _customData = custom
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastLoginAt, forKey: .lastLoginAt)
        
        // Encode dictionaries as Data
        if !_preferences.isEmpty {
            let prefsData = try JSONSerialization.data(withJSONObject: _preferences)
            try container.encode(prefsData, forKey: .preferences)
        }
        
        if !_customData.isEmpty {
            let customData = try JSONSerialization.data(withJSONObject: _customData)
            try container.encode(customData, forKey: .customData)
        }
    }
}

// MARK: - User Equatable Conformance
extension User: Equatable {
    /// Custom Equatable implementation for User
    /// Note: Compares [String: Any] dictionaries by converting to JSON for comparison
    static func == (lhs: User, rhs: User) -> Bool {
        // Compare basic properties
        guard lhs.id == rhs.id,
              lhs.email == rhs.email,
              lhs.name == rhs.name,
              lhs.avatarURL == rhs.avatarURL,
              lhs.createdAt == rhs.createdAt,
              lhs.lastLoginAt == rhs.lastLoginAt else {
            return false
        }
        
        // Compare preferences dictionary
        // Convert to JSON Data for comparison since [String: Any] doesn't conform to Equatable
        do {
            let lhsPrefsData = try JSONSerialization.data(withJSONObject: lhs._preferences)
            let rhsPrefsData = try JSONSerialization.data(withJSONObject: rhs._preferences)
            
            let lhsCustomData = try JSONSerialization.data(withJSONObject: lhs._customData)
            let rhsCustomData = try JSONSerialization.data(withJSONObject: rhs._customData)
            
            return lhsPrefsData == rhsPrefsData && lhsCustomData == rhsCustomData
        } catch {
            // If JSON serialization fails, fall back to key count comparison
            return lhs._preferences.keys.count == rhs._preferences.keys.count &&
                   lhs._customData.keys.count == rhs._customData.keys.count
        }
    }
}

// MARK: - Storage Backend Protocol
protocol UserStorageBackend {
    func saveUser(_ user: User) async throws
    func loadUser() async throws -> User?
    func deleteUser() async throws
    func saveOnboardingStatus(_ completed: Bool) async throws
    func loadOnboardingStatus() async throws -> Bool
    func saveUserData(_ data: [String: Any]) async throws
    func loadUserData() async throws -> [String: Any]
}

// MARK: - UserDefaults Storage Backend
class UserDefaultsStorage: UserStorageBackend {
    private let userDefaults = UserDefaults.standard
    private let userKey = "saved_user"
    private let onboardingKey = "onboarding_completed"
    private let userDataKey = "user_data"
    
    func saveUser(_ user: User) async throws {
        let data = try JSONEncoder().encode(user)
        userDefaults.set(data, forKey: userKey)
    }
    
    func loadUser() async throws -> User? {
        guard let data = userDefaults.data(forKey: userKey) else { return nil }
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func deleteUser() async throws {
        userDefaults.removeObject(forKey: userKey)
    }
    
    func saveOnboardingStatus(_ completed: Bool) async throws {
        userDefaults.set(completed, forKey: onboardingKey)
    }
    
    func loadOnboardingStatus() async throws -> Bool {
        return userDefaults.bool(forKey: onboardingKey)
    }
    
    func saveUserData(_ data: [String: Any]) async throws {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        userDefaults.set(jsonData, forKey: userDataKey)
    }
    
    func loadUserData() async throws -> [String: Any] {
        guard let data = userDefaults.data(forKey: userDataKey),
              let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

// MARK: - User Manager
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isSignedIn: Bool = false
    @Published var isOnboardingCompleted: Bool = false
    @Published var userData: [String: Any] = [:]
    
    // MARK: - Private Properties
    private var storageBackend: UserStorageBackend
    private var isDebugMode = false
    private var autoSyncEnabled = true
    private var cancellables = Set<AnyCancellable>()
    
    // User defaults keys for local state
    private let lastSyncKey = "last_sync_date"
    private let sessionTokenKey = "session_token"
    
    private init() {
        // Default to UserDefaults storage
        self.storageBackend = UserDefaultsStorage()
        
        // Load initial state
        Task {
            await loadInitialState()
        }
        
        // Setup observers
        setupObservers()
    }
    
    // MARK: - Configuration
    
    /// Set the storage backend (UserDefaults, Firebase, Core Data, etc.)
    /// - Parameter backend: Storage backend implementation
    func setStorageBackend(_ backend: UserStorageBackend) {
        self.storageBackend = backend
        
        // Reload state with new backend
        Task {
            await loadInitialState()
        }
        
        if isDebugMode {
            print("👤 User storage backend updated")
        }
    }
    
    /// Enable or disable debug logging
    /// - Parameter enabled: Whether debug mode is enabled
    func setDebugMode(_ enabled: Bool) {
        self.isDebugMode = enabled
        print("🐛 UserManager debug mode \(enabled ? "enabled" : "disabled")")
    }
    
    /// Enable or disable automatic data syncing
    /// - Parameter enabled: Whether auto-sync is enabled
    func setAutoSyncEnabled(_ enabled: Bool) {
        self.autoSyncEnabled = enabled
        
        if isDebugMode {
            print("🔄 Auto-sync \(enabled ? "enabled" : "disabled")")
        }
    }
    
    // MARK: - Authentication
    
    /// Sign in a user
    /// - Parameters:
    ///   - userId: Unique user identifier
    ///   - email: User's email (optional)
    ///   - name: User's name (optional)
    ///   - avatarURL: User's avatar URL (optional)
    func signIn(userId: String, email: String? = nil, name: String? = nil, avatarURL: String? = nil) async throws {
        guard !userId.isEmpty else {
            throw UserManagerError.invalidUserData
        }
        
        let user = User(
            id: userId,
            email: email,
            name: name,
            avatarURL: avatarURL,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        try await storageBackend.saveUser(user)
        
        await MainActor.run {
            self.currentUser = user
            self.isSignedIn = true
        }
        
        // Integrate with other services
        await setupUserServices(user)
        
        if isDebugMode {
            print("✅ User signed in: \(userId)")
        }
    }
    
    /// Sign out the current user
    func signOut() async {
        do {
            // Clean up storage
            try await storageBackend.deleteUser()
            
            // Clean up session
            UserDefaults.standard.removeObject(forKey: sessionTokenKey)
            
            await MainActor.run {
                self.currentUser = nil
                self.isSignedIn = false
                self.userData = [:]
            }
            
            // Clean up other services
            await cleanupUserServices()
            
            if isDebugMode {
                print("👋 User signed out")
            }
        } catch {
            if isDebugMode {
                print("❌ Error during sign out: \(error)")
            }
        }
    }
    
    /// Check if user is currently signed in
    /// - Returns: Whether user is signed in
    func checkAuthenticationStatus() async -> Bool {
        do {
            let user = try await storageBackend.loadUser()
            
            await MainActor.run {
                self.currentUser = user
                self.isSignedIn = user != nil
            }
            
            return user != nil
        } catch {
            if isDebugMode {
                print("❌ Error checking auth status: \(error)")
            }
            return false
        }
    }
    
    // MARK: - Onboarding
    
    /// Mark onboarding as completed
    func completeOnboarding() {
        Task {
            do {
                try await storageBackend.saveOnboardingStatus(true)
                
                await MainActor.run {
                    self.isOnboardingCompleted = true
                }
                
                if isDebugMode {
                    print("🎉 Onboarding completed")
                }
                
                // Start engagement campaigns if user is signed in
                if isSignedIn {
                    NotificationManager.shared.startEngagementCampaign()
                }
            } catch {
                if isDebugMode {
                    print("❌ Error saving onboarding status: \(error)")
                }
            }
        }
    }
    
    /// Reset onboarding status (useful for testing)
    func resetOnboarding() {
        Task {
            do {
                try await storageBackend.saveOnboardingStatus(false)
                
                await MainActor.run {
                    self.isOnboardingCompleted = false
                }
                
                if isDebugMode {
                    print("🔄 Onboarding reset")
                }
            } catch {
                if isDebugMode {
                    print("❌ Error resetting onboarding: \(error)")
                }
            }
        }
    }
    
    // MARK: - User Data Management
    
    /// Update user data
    /// - Parameter data: Dictionary of user data to update
    func updateUserData(_ data: [String: Any]) {
        Task {
            do {
                // Merge with existing data
                var updatedData = userData
                updatedData.merge(data) { _, new in new }
                
                try await storageBackend.saveUserData(updatedData)
                
                // Capture the final data to avoid concurrency issues
                let finalData = updatedData
                await MainActor.run {
                    self.userData = finalData
                }
                
                if isDebugMode {
                    print("📝 User data updated: \(data.keys)")
                }
                
                // Update Superwall attributes if user is signed in
                if isSignedIn {
                    await updateSuperwallAttributes()
                }
            } catch {
                if isDebugMode {
                    print("❌ Error updating user data: \(error)")
                }
            }
        }
    }
    
    /// Get specific user data value
    /// - Parameter key: Data key
    /// - Returns: Value for the key
    func getUserData(for key: String) -> Any? {
        return userData[key]
    }
    
    /// Remove specific user data
    /// - Parameter key: Key to remove
    func removeUserData(for key: String) {
        var updatedData = userData
        updatedData.removeValue(forKey: key)
        updateUserData(updatedData)
    }
    
    /// Update user profile
    /// - Parameters:
    ///   - name: User's name
    ///   - email: User's email
    ///   - avatarURL: User's avatar URL
    func updateProfile(name: String? = nil, email: String? = nil, avatarURL: String? = nil) async throws {
        guard var user = currentUser else {
            throw UserManagerError.notSignedIn
        }
        
        // Update user object
        if let name = name {
            user = User(id: user.id, email: user.email, name: name, avatarURL: user.avatarURL, createdAt: user.createdAt, lastLoginAt: user.lastLoginAt)
        }
        
        if let email = email {
            user = User(id: user.id, email: email, name: user.name, avatarURL: user.avatarURL, createdAt: user.createdAt, lastLoginAt: user.lastLoginAt)
        }
        
        if let avatarURL = avatarURL {
            user = User(id: user.id, email: user.email, name: user.name, avatarURL: avatarURL, createdAt: user.createdAt, lastLoginAt: user.lastLoginAt)
        }
        
        try await storageBackend.saveUser(user)
        
        // Capture the final user to avoid concurrency issues
        let updatedUser = user
        await MainActor.run {
            self.currentUser = updatedUser
        }
        
        if isDebugMode {
            print("👤 User profile updated")
        }
    }
    
    // MARK: - Session Management
    
    /// Set session token
    /// - Parameter token: Session token
    func setSessionToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: sessionTokenKey)
        
        if isDebugMode {
            print("🔑 Session token updated")
        }
    }
    
    /// Get current session token
    /// - Returns: Session token if available
    func getSessionToken() -> String? {
        return UserDefaults.standard.string(forKey: sessionTokenKey)
    }
    
    /// Clear session token
    func clearSessionToken() {
        UserDefaults.standard.removeObject(forKey: sessionTokenKey)
        
        if isDebugMode {
            print("🗑️ Session token cleared")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Force sync user data with backend
    func syncUserData() async throws {
        guard isSignedIn else {
            throw UserManagerError.notSignedIn
        }
        
        // Load fresh data from backend
        let user = try await storageBackend.loadUser()
        let onboardingStatus = try await storageBackend.loadOnboardingStatus()
        let userData = try await storageBackend.loadUserData()
        
        await MainActor.run {
            self.currentUser = user
            self.isOnboardingCompleted = onboardingStatus
            self.userData = userData
        }
        
        // Update last sync time
        UserDefaults.standard.set(Date(), forKey: lastSyncKey)
        
        if isDebugMode {
            print("🔄 User data synced")
        }
    }
    
    /// Get user analytics summary
    /// - Returns: Dictionary with user analytics data
    func getAnalyticsSummary() -> [String: Any] {
        return [
            "is_signed_in": isSignedIn,
            "user_id": currentUser?.id ?? "anonymous",
            "onboarding_completed": isOnboardingCompleted,
            "user_data_count": userData.count,
            "last_login": currentUser?.lastLoginAt.timeIntervalSince1970 ?? 0,
            "account_age_days": currentUser?.createdAt.timeIntervalSinceNow ?? 0 / -86400,
            "has_session_token": getSessionToken() != nil
        ]
    }
    
    /// Reset all user data (useful for logout or testing)
    func resetAllUserData() async {
        do {
            try await storageBackend.deleteUser()
            try await storageBackend.saveOnboardingStatus(false)
            try await storageBackend.saveUserData([:])
            
            UserDefaults.standard.removeObject(forKey: sessionTokenKey)
            UserDefaults.standard.removeObject(forKey: lastSyncKey)
            
            await MainActor.run {
                self.currentUser = nil
                self.isSignedIn = false
                self.isOnboardingCompleted = false
                self.userData = [:]
            }
            
            await cleanupUserServices()
            
            if isDebugMode {
                print("🔄 All user data reset")
            }
        } catch {
            if isDebugMode {
                print("❌ Error resetting user data: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadInitialState() async {
        do {
            let user = try await storageBackend.loadUser()
            let onboardingStatus = try await storageBackend.loadOnboardingStatus()
            let userData = try await storageBackend.loadUserData()
            
            await MainActor.run {
                self.currentUser = user
                self.isSignedIn = user != nil
                self.isOnboardingCompleted = onboardingStatus
                self.userData = userData
            }
            
            if let user = user {
                await setupUserServices(user)
            }
            
            if isDebugMode {
                print("📱 User state loaded - Signed in: \(user != nil), Onboarding: \(onboardingStatus)")
            }
        } catch {
            if isDebugMode {
                print("❌ Error loading initial state: \(error)")
            }
        }
    }
    
    private func setupObservers() {
        // Auto-sync when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self = self, self.autoSyncEnabled else { return }
                Task {
                    try? await self.syncUserData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupUserServices(_ user: User) async {
        // Update Superwall attributes
        await updateSuperwallAttributes()
        
        // Set API authentication if available
        if let token = getSessionToken() {
            APIService.shared.setBearerToken(token)
        }
        
        if isDebugMode {
            print("🔗 User services configured for: \(user.id)")
        }
    }
    
    private func cleanupUserServices() async {
        // Reset Superwall user data
        SuperwallService.shared.resetUserData()
        
        // Clear API authentication
        APIService.shared.setBearerToken(nil)
        
        // Stop notification campaigns
        NotificationManager.shared.stopEngagementCampaign()
        
        if isDebugMode {
            print("🧹 User services cleaned up")
        }
    }
    
    private func updateSuperwallAttributes() async {
        guard let user = currentUser else { return }
        
        var attributes: [String: Any] = [
            "user_id": user.id,
            "onboarding_completed": isOnboardingCompleted,
            "account_age_days": Int(Date().timeIntervalSince(user.createdAt) / 86400)
        ]
        
        if let email = user.email {
            attributes["email"] = email
        }
        
        if let name = user.name {
            attributes["name"] = name
        }
        
        // Add custom user data
        attributes.merge(userData) { _, new in new }
        
        SuperwallService.shared.setUserAttributes(attributes)
    }
}

// MARK: - Convenience Extensions
extension UserManager {
    
    /// Quick check if user needs onboarding
    var needsOnboarding: Bool {
        return !isOnboardingCompleted
    }
    
    /// Quick check if user is authenticated and onboarded
    var isFullySetup: Bool {
        return isSignedIn && isOnboardingCompleted
    }
    
    /// Get user's display name (name or email or "User")
    var userDisplayName: String {
        return currentUser?.name ?? currentUser?.email ?? "User"
    }
    
    /// Get user's initials for avatar
    var userInitials: String {
        let name = userDisplayName
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

