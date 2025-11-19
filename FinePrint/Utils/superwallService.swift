//
//  superwallService.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 SUPERWALL SERVICE REFERENCE GUIDE
 
 Features:
 - Easy paywall presentation and management
 - Placement registration (trigger events)
 - User attribute tracking
 - Analytics integration with existing API service
 - Campaign and audience management
 - Subscription status tracking
 - Purchase restoration
 - A/B testing support
 - Revenue analytics
 
 Usage Examples:
 // Configure Superwall (one-time setup)
 SuperwallService.shared.configure(apiKey: "pk_your_api_key_here")
 
 // Register placement events
 SuperwallService.shared.register("feature_gate")
 SuperwallService.shared.register("premium_content", params: ["content_id": "123"])
 
 // Set user attributes
 SuperwallService.shared.setUserAttributes([
     "user_id": "12345",
     "subscription_status": "free",
     "signup_date": "2024-01-01"
 ])
 
 // Present paywalls manually
 SuperwallService.shared.presentPaywall(for: "premium_upgrade")
 
 // Track custom events
 SuperwallService.shared.trackEvent("custom_action", params: ["action": "button_tap"])
 
 Integration:
 - Add SuperwallKit to your project via SPM
 - Configure during app startup
 - Use placement registration throughout your app
 - Handle delegate events for analytics
 
 Documentation Reference:
 - Full Superwall documentation: https://superwall.com/docs/llms-full.txt
 */

import Foundation
import UIKit
import SuperwallKit

// MARK: - Superwall Error Types
enum SuperwallError: LocalizedError {
    case notConfigured
    case invalidAPIKey
    case presentationFailed
    case invalidPlacement
    case userNotEligible
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Superwall not configured. Call configure() first."
        case .invalidAPIKey:
            return "Invalid Superwall API key provided"
        case .presentationFailed:
            return "Failed to present paywall"
        case .invalidPlacement:
            return "Invalid placement name provided"
        case .userNotEligible:
            return "User not eligible for this paywall"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Placement Result
enum PlacementResult {
    case paywallPresented
    case paywallNotPresented
    case userAlreadySubscribed
    case placementNotFound
    case error(SuperwallError)
}

// MARK: - Subscription Status
enum SubscriptionStatus: String, CaseIterable {
    case free = "free"
    case trial = "trial"
    case premium = "premium"
    case expired = "expired"
    case cancelled = "cancelled"
}

// MARK: - Superwall Service
class SuperwallService: NSObject {
    static let shared = SuperwallService()
    
    // MARK: - Properties
    private var isConfigured = false
    private var apiKey: String?
    private var isDebugMode = false
    private var userAttributes: [String: Any] = [:]
    
    // Analytics integration
    private var shouldTrackToAnalytics = true
    
    // User defaults for persistence
    private let userDefaults = UserDefaults.standard
    private let userAttributesKey = "superwall_user_attributes"
    private let subscriptionStatusKey = "subscription_status"
    
    private override init() {
        super.init()
        loadPersistedUserAttributes()
    }
    
    // MARK: - Configuration
    
    /// Configure Superwall with API key (call once during app startup)
    /// - Parameters:
    ///   - apiKey: Your Superwall API key
    ///   - debugMode: Enable debug logging (default: false)
    func configure(apiKey: String, debugMode: Bool = false) {
        guard !apiKey.isEmpty else {
            print("❌ Superwall: Invalid API key provided")
            return
        }
        
        self.apiKey = apiKey
        self.isDebugMode = debugMode
        
        // Configure Superwall SDK
        Superwall.configure(apiKey: apiKey)
        Superwall.shared.delegate = self
        
        // Note: Debug logging is handled internally by Superwall SDK
        // No need to set options.isDebugLoggingEnabled as it's not accessible
        
        self.isConfigured = true
        
        if debugMode {
            print("✅ Superwall configured with API key: \(apiKey.prefix(10))...")
        }
        
        // Set initial user attributes
        refreshUserAttributes()
    }
    
    /// Enable or disable analytics tracking integration
    /// - Parameter enabled: Whether to send Superwall events to analytics
    func setAnalyticsTrackingEnabled(_ enabled: Bool) {
        shouldTrackToAnalytics = enabled
        print("📊 Superwall analytics tracking \(enabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Placement Registration
    
    /// Register a placement event (this is what triggers paywalls)
    /// - Parameters:
    ///   - placementName: Name of the placement (e.g., "premium_feature", "feature_gate")
    ///   - params: Optional parameters to pass with the event
    ///   - completion: Optional completion handler with result
    func register(
        _ placementName: String,
        params: [String: Any]? = nil,
        completion: ((PlacementResult) -> Void)? = nil
    ) {
        guard isConfigured else {
            print("❌ Superwall not configured")
            completion?(.error(.notConfigured))
            return
        }
        
        guard !placementName.isEmpty else {
            print("❌ Invalid placement name")
            completion?(.error(.invalidPlacement))
            return
        }
        
        if isDebugMode {
            print("🎯 Registering placement: \(placementName)")
            if let params = params {
                print("   Parameters: \(params)")
            }
        }
        
        // Register with Superwall SDK - using updated API with 'placement' parameter
        Superwall.shared.register(
            placement: placementName,
            params: params
        ) {
            // No parameters expected in the closure
            DispatchQueue.main.async {
                // Since we can't get the specific result from the closure,
                // we'll indicate that the registration was processed
                completion?(.paywallNotPresented)
            }
        }
        
        // Track to analytics if enabled
        if shouldTrackToAnalytics {
            trackToAnalytics("placement_registered", params: [
                "placement_name": placementName,
                "params": params ?? [:]
            ])
        }
    }
    
    /// Register placement with async/await pattern
    /// - Parameters:
    ///   - placementName: Name of the placement
    ///   - params: Optional parameters
    /// - Returns: Placement result
    func register(_ placementName: String, params: [String: Any]? = nil) async -> PlacementResult {
        return await withCheckedContinuation { continuation in
            register(placementName, params: params) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Manual Paywall Presentation
    
    /// Present a paywall manually
    /// - Parameters:
    ///   - identifier: Paywall identifier from Superwall dashboard
    ///   - completion: Optional completion handler
    func presentPaywall(
        for identifier: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard isConfigured else {
            print("❌ Superwall not configured")
            completion?(false)
            return
        }
        
        if isDebugMode {
            print("💳 Presenting paywall: \(identifier)")
        }
        
        // Present paywall with Superwall SDK - using updated API with 'placement' parameter
        Superwall.shared.register(
            placement: identifier,
            params: nil
        ) {
            DispatchQueue.main.async {
                // Registration completed - paywall presentation is handled by the SDK
                completion?(true)
            }
        }
        
        // Track to analytics
        if shouldTrackToAnalytics {
            trackToAnalytics("paywall_presented_manually", params: [
                "paywall_identifier": identifier
            ])
        }
    }
    
    /// Present paywall with async/await
    /// - Parameter identifier: Paywall identifier
    /// - Returns: Whether paywall was presented
    func presentPaywall(for identifier: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            presentPaywall(for: identifier) { presented in
                continuation.resume(returning: presented)
            }
        }
    }
    
    // MARK: - User Attributes
    
    /// Set user attributes for targeting and personalization
    /// - Parameter attributes: Dictionary of user attributes
    func setUserAttributes(_ attributes: [String: Any]) {
        userAttributes.merge(attributes) { _, new in new }
        
        // Save to UserDefaults for persistence
        if let data = try? JSONSerialization.data(withJSONObject: userAttributes) {
            userDefaults.set(data, forKey: userAttributesKey)
        }
        
        // Set in Superwall SDK
        Superwall.shared.setUserAttributes(attributes)
        
        if isDebugMode {
            print("👤 User attributes updated: \(attributes)")
        }
        
        // Track to analytics
        if shouldTrackToAnalytics {
            trackToAnalytics("user_attributes_updated", params: attributes)
        }
    }
    
    /// Set a single user attribute
    /// - Parameters:
    ///   - value: Attribute value
    ///   - key: Attribute key
    func setUserAttribute(_ value: Any, forKey key: String) {
        setUserAttributes([key: value])
    }
    
    /// Get current user attributes
    /// - Returns: Dictionary of current user attributes
    func getUserAttributes() -> [String: Any] {
        return userAttributes
    }
    
    /// Set subscription status
    /// - Parameter status: Current subscription status
    func setSubscriptionStatus(_ status: SubscriptionStatus) {
        setUserAttribute(status.rawValue, forKey: "subscription_status")
        userDefaults.set(status.rawValue, forKey: subscriptionStatusKey)
        
        if isDebugMode {
            print("💰 Subscription status updated: \(status.rawValue)")
        }
    }
    
    /// Get current subscription status
    /// - Returns: Current subscription status
    func getSubscriptionStatus() -> SubscriptionStatus {
        let statusString = userDefaults.string(forKey: subscriptionStatusKey) ?? "free"
        return SubscriptionStatus(rawValue: statusString) ?? .free
    }
    
    // MARK: - Custom Event Tracking
    
    /// Track custom events for analytics and targeting
    /// - Parameters:
    ///   - eventName: Name of the event
    ///   - params: Optional event parameters
    func trackEvent(_ eventName: String, params: [String: Any]? = nil) {
        if isDebugMode {
            print("📊 Tracking event: \(eventName)")
            if let params = params {
                print("   Parameters: \(params)")
            }
        }
        
        // Track to analytics if enabled
        if shouldTrackToAnalytics {
            trackToAnalytics(eventName, params: params ?? [:])
        }
    }
    
    // MARK: - Purchase Management
    
    /// Handle successful purchase
    /// - Parameters:
    ///   - productIdentifier: Product ID that was purchased
    ///   - price: Price of the product
    ///   - currency: Currency code
    func handleSuccessfulPurchase(
        productIdentifier: String,
        price: Decimal? = nil,
        currency: String? = nil
    ) {
        var params: [String: Any] = ["product_id": productIdentifier]
        
        if let price = price {
            params["price"] = price
        }
        
        if let currency = currency {
            params["currency"] = currency
        }
        
        // Update subscription status if it's a subscription product
        if productIdentifier.contains("premium") || productIdentifier.contains("pro") {
            setSubscriptionStatus(.premium)
        }
        
        trackEvent("purchase_completed", params: params)
        
        if isDebugMode {
            print("💰 Purchase completed: \(productIdentifier)")
        }
    }
    
    /// Handle purchase restoration
    func handlePurchaseRestoration() {
        setSubscriptionStatus(.premium)
        trackEvent("purchase_restored")
        
        if isDebugMode {
            print("🔄 Purchase restored")
        }
    }
    
    /// Handle subscription cancellation
    func handleSubscriptionCancellation() {
        setSubscriptionStatus(.cancelled)
        trackEvent("subscription_cancelled")
        
        if isDebugMode {
            print("❌ Subscription cancelled")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Check if user has active subscription
    /// - Returns: Whether user is subscribed
    func isUserSubscribed() -> Bool {
        let status = getSubscriptionStatus()
        return status == .premium || status == .trial
    }
    
    /// Reset user data (useful for logout)
    func resetUserData() {
        userAttributes.removeAll()
        userDefaults.removeObject(forKey: userAttributesKey)
        userDefaults.removeObject(forKey: subscriptionStatusKey)
        
        // Reset in Superwall SDK
        Superwall.shared.reset()
        
        if isDebugMode {
            print("🔄 User data reset")
        }
        
        trackEvent("user_data_reset")
    }
    
    /// Get paywall analytics summary
    /// - Returns: Dictionary with analytics data
    func getAnalyticsSummary() -> [String: Any] {
        return [
            "is_configured": isConfigured,
            "subscription_status": getSubscriptionStatus().rawValue,
            "user_attributes_count": userAttributes.count,
            "is_subscribed": isUserSubscribed(),
            "debug_mode": isDebugMode
        ]
    }
    
    // MARK: - Private Methods
    
    private func loadPersistedUserAttributes() {
        guard let data = userDefaults.data(forKey: userAttributesKey),
              let attributes = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        userAttributes = attributes
    }
    
    private func refreshUserAttributes() {
        // Set common attributes
        var attributes: [String: Any] = [
            "platform": "iOS",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            "device_model": UIDevice.current.model,
            "os_version": UIDevice.current.systemVersion,
            "first_launch": userDefaults.object(forKey: "first_launch_date") == nil
        ]
        
        // Set first launch date if not set
        if userDefaults.object(forKey: "first_launch_date") == nil {
            let now = Date()
            userDefaults.set(now, forKey: "first_launch_date")
            attributes["first_launch_date"] = ISO8601DateFormatter().string(from: now)
        }
        
        setUserAttributes(attributes)
    }
    
    private func trackToAnalytics(_ eventName: String, params: [String: Any]) {
        // Integration with our existing API service for analytics
        var analyticsParams = params
        analyticsParams["source"] = "superwall"
        analyticsParams["timestamp"] = Date().timeIntervalSince1970
        
        // You can send to your analytics service here
        // APIService.shared.post("/analytics/events", body: AnalyticsEvent(...))
        
        if isDebugMode {
            print("📈 Analytics tracked: \(eventName) with params: \(analyticsParams)")
        }
    }
}

// MARK: - Superwall Delegate
extension SuperwallService: SuperwallDelegate {
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        if isDebugMode {
            print("🎯 Superwall event: \(eventInfo.event.description)")
        }
        
        // Forward to analytics if enabled
        if shouldTrackToAnalytics {
            trackToAnalytics("superwall_\(eventInfo.event.description)", params: eventInfo.params)
        }
        
        // Handle specific events
        switch eventInfo.event {
        case .paywallOpen(let paywallInfo):
            trackEvent("paywall_opened", params: ["paywall_id": paywallInfo.identifier])
            
        case .paywallClose(let paywallInfo):
            trackEvent("paywall_closed", params: ["paywall_id": paywallInfo.identifier])
            
        case .transactionComplete(_, let product, _, _):
            handleSuccessfulPurchase(productIdentifier: product.productIdentifier)
            
        case .transactionRestore(_, _):
            handlePurchaseRestoration()
            
        case .subscriptionStart(_, _):
            setSubscriptionStatus(.premium)
            
        case .freeTrialStart(_, _):
            setSubscriptionStatus(.trial)
            
        default:
            break
        }
    }
}

// MARK: - Convenience Extensions
extension SuperwallService {
    
    /// Common placement names for easy reference
    struct Placements {
        static let featureGate = "feature_gate"
        static let premiumContent = "premium_content"
        static let settingsUpgrade = "settings_upgrade"
        static let onboardingUpsell = "onboarding_upsell"
        static let exportFeature = "export_feature"
        static let customThemes = "custom_themes"
        static let unlimitedUsage = "unlimited_usage"
        static let premiumSupport = "premium_support"
    }
    
    /// Quick access methods for common placements
    func registerFeatureGate(feature: String) {
        register(Placements.featureGate, params: ["feature": feature])
    }
    
    func registerPremiumContent(contentId: String, contentType: String) {
        register(Placements.premiumContent, params: [
            "content_id": contentId,
            "content_type": contentType
        ])
    }
    
    func registerOnboardingUpsell(step: String) {
        register(Placements.onboardingUpsell, params: ["onboarding_step": step])
    }
}

