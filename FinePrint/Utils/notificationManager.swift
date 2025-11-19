//
//  notificationManager.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 NOTIFICATION MANAGER REFERENCE GUIDE
 
 Features:
 - Permission request handling
 - Immediate local notifications
 - Engagement campaigns with timed schedules
 - Badge number management
 - Rich notifications with images/actions
 - Sound and vibration control
 - Notification categories and actions
 - Campaign analytics tracking
 
 Usage Examples:
 // Request permissions
 try await NotificationManager.shared.requestPermissions()
 
 // Send immediate notification
 NotificationManager.shared.sendNotification(
     title: "Welcome!",
     body: "Thanks for joining our app"
 )
 
 // Start engagement campaign
 NotificationManager.shared.startEngagementCampaign()
 
 // Send scheduled notification
 NotificationManager.shared.scheduleNotification(
     title: "Don't forget!",
     body: "Complete your daily tasks",
     delay: 3600 // 1 hour from now
 )
 
 Configuration:
 - Set app badge: NotificationManager.shared.setBadgeCount(5)
 - Enable/disable campaigns: NotificationManager.shared.setCampaignsEnabled(true)
 - Configure campaign schedule: customize campaigns in the campaigns array
 */

import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Error Types
enum NotificationError: LocalizedError {
    case permissionDenied
    case notificationNotAllowed
    case schedulingFailed
    case invalidDelay
    case campaignAlreadyRunning
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission was denied"
        case .notificationNotAllowed:
            return "Notifications are not allowed"
        case .schedulingFailed:
            return "Failed to schedule notification"
        case .invalidDelay:
            return "Invalid delay time for notification"
        case .campaignAlreadyRunning:
            return "Engagement campaign is already running"
        }
    }
}

// MARK: - Notification Types
enum NotificationType: String {
    case immediate = "immediate"
    case campaign = "campaign"
    case reminder = "reminder"
    case achievement = "achievement"
    case welcome = "welcome"
}

// MARK: - Campaign Notification
struct CampaignNotification {
    let id: String
    let title: String
    let body: String
    let delayHours: Double
    let type: NotificationType
    let sound: UNNotificationSound
    let badge: Int?
    
    init(id: String, title: String, body: String, delayHours: Double, type: NotificationType = .campaign, sound: UNNotificationSound = .default, badge: Int? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.delayHours = delayHours
        self.type = type
        self.sound = sound
        self.badge = badge
    }
}

// MARK: - Notification Manager
class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private var isInitialized = false
    private var campaignsEnabled = true
    
    // Badge count tracking (iOS 17.0+ compatible)
    private var currentBadgeCount: Int {
        get {
            if #available(iOS 17.0, *) {
                return userDefaults.integer(forKey: badgeCountKey)
            } else {
                return UIApplication.shared.applicationIconBadgeNumber
            }
        }
        set {
            if #available(iOS 17.0, *) {
                userDefaults.set(newValue, forKey: badgeCountKey)
            }
        }
    }
    
    // Keys for UserDefaults
    private let campaignStartedKey = "notification_campaign_started"
    private let campaignsEnabledKey = "notification_campaigns_enabled"
    private let lastNotificationDateKey = "last_notification_date"
    private let badgeCountKey = "current_badge_count"
    
    // MARK: - Default Campaign Schedule
    private let defaultCampaigns: [CampaignNotification] = [
        // Welcome series
        CampaignNotification(
            id: "welcome_1",
            title: "Welcome aboard! 🎉",
            body: "Thanks for joining us! Explore the app to get started.",
            delayHours: 0.5, // 30 minutes
            type: .welcome,
            badge: 1
        ),
        CampaignNotification(
            id: "engagement_1",
            title: "Don't miss out! 📱",
            body: "Complete your profile to unlock all features.",
            delayHours: 24, // 1 day
            type: .campaign,
            badge: 2
        ),
        CampaignNotification(
            id: "engagement_2",
            title: "We miss you! 💙",
            body: "Come back and see what's new in the app.",
            delayHours: 72, // 3 days
            type: .campaign,
            badge: 3
        ),
        CampaignNotification(
            id: "engagement_3",
            title: "Special features await! ⭐",
            body: "Discover advanced features you haven't tried yet.",
            delayHours: 168, // 1 week
            type: .campaign,
            badge: 4
        ),
        CampaignNotification(
            id: "retention_1",
            title: "You're making progress! 🚀",
            body: "Keep up the momentum and achieve your goals.",
            delayHours: 336, // 2 weeks
            type: .campaign,
            badge: 5
        ),
        CampaignNotification(
            id: "retention_2",
            title: "Monthly check-in 📊",
            body: "See how much you've accomplished this month!",
            delayHours: 720, // 30 days
            type: .campaign,
            badge: 6
        )
    ]
    
    private override init() {
        super.init()
        setupNotificationCenter()
    }
    
    // MARK: - Setup Methods
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
        isInitialized = true
    }
    
    private func setupNotificationCategories() {
        // Define notification actions
        let openAction = UNNotificationAction(
            identifier: "OPEN_ACTION",
            title: "Open App",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: []
        )
        
        // Define categories
        let generalCategory = UNNotificationCategory(
            identifier: "GENERAL",
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let campaignCategory = UNNotificationCategory(
            identifier: "CAMPAIGN",
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            generalCategory,
            campaignCategory
        ])
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions from user
    /// - Returns: Bool indicating if permission was granted
    @discardableResult
    func requestPermissions() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [
                .alert,
                .badge,
                .sound,
                .provisional,
                .criticalAlert
            ])
            
            if granted {
                // Request to add to notification settings on iOS
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                return true
            } else {
                throw NotificationError.permissionDenied
            }
        } catch {
            throw NotificationError.permissionDenied
        }
    }
    
    /// Check current authorization status
    /// - Returns: Current authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Check if notifications are enabled
    /// - Returns: Bool indicating if notifications are allowed
    func areNotificationsEnabled() async -> Bool {
        let status = await checkAuthorizationStatus()
        return status == .authorized || status == .provisional
    }
    
    // MARK: - Immediate Notifications
    
    /// Send an immediate local notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body
    ///   - sound: Notification sound (default: .default)
    ///   - badge: Badge number (optional)
    ///   - userInfo: Additional user info (optional)
    func sendNotification(
        title: String,
        body: String,
        sound: UNNotificationSound = .default,
        badge: Int? = nil,
        userInfo: [String: Any] = [:]
    ) {
        Task {
            guard await areNotificationsEnabled() else {
                print("❌ Notifications not enabled")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = sound
            content.categoryIdentifier = "GENERAL"
            
            if let badge = badge {
                content.badge = NSNumber(value: badge)
            }
            
            // Add custom user info
            var info = userInfo
            info["type"] = NotificationType.immediate.rawValue
            info["timestamp"] = Date().timeIntervalSince1970
            content.userInfo = info
            
            // Create request with unique identifier
            let identifier = "immediate_\(UUID().uuidString)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: nil // Immediate delivery
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ Immediate notification sent: \(title)")
                userDefaults.set(Date(), forKey: lastNotificationDateKey)
            } catch {
                print("❌ Failed to send notification: \(error)")
            }
        }
    }
    
    // MARK: - Scheduled Notifications
    
    /// Schedule a notification for later delivery
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body
    ///   - delay: Delay in seconds from now
    ///   - sound: Notification sound
    ///   - badge: Badge number
    ///   - userInfo: Additional user info
    /// - Returns: Notification identifier
    @discardableResult
    func scheduleNotification(
        title: String,
        body: String,
        delay: TimeInterval,
        sound: UNNotificationSound = .default,
        badge: Int? = nil,
        userInfo: [String: Any] = [:]
    ) async throws -> String {
        
        guard delay > 0 else {
            throw NotificationError.invalidDelay
        }
        
        guard await areNotificationsEnabled() else {
            throw NotificationError.notificationNotAllowed
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.categoryIdentifier = "GENERAL"
        
        if let badge = badge {
            content.badge = NSNumber(value: badge)
        }
        
        // Add custom user info
        var info = userInfo
        info["type"] = NotificationType.reminder.rawValue
        info["scheduledFor"] = Date().addingTimeInterval(delay).timeIntervalSince1970
        content.userInfo = info
        
        // Create time interval trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay,
            repeats: false
        )
        
        // Create request
        let identifier = "scheduled_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Notification scheduled for \(delay) seconds: \(title)")
            return identifier
        } catch {
            print("❌ Failed to schedule notification: \(error)")
            throw NotificationError.schedulingFailed
        }
    }
    
    // MARK: - Campaign Management
    
    /// Start the engagement campaign with predefined notifications
    func startEngagementCampaign() {
        guard !isCampaignRunning() else {
            print("⚠️ Campaign already running")
            return
        }
        
        guard campaignsEnabled else {
            print("⚠️ Campaigns are disabled")
            return
        }
        
        Task {
            guard await areNotificationsEnabled() else {
                print("❌ Cannot start campaign: notifications not enabled")
                return
            }
            
            // Mark campaign as started
            userDefaults.set(Date(), forKey: campaignStartedKey)
            
            // Schedule all campaign notifications
            for campaign in defaultCampaigns {
                await scheduleCampaignNotification(campaign)
            }
            
            print("🚀 Engagement campaign started with \(defaultCampaigns.count) notifications")
        }
    }
    
    /// Schedule a single campaign notification
    /// - Parameter campaign: Campaign notification to schedule
    private func scheduleCampaignNotification(_ campaign: CampaignNotification) async {
        let delaySeconds = campaign.delayHours * 3600 // Convert hours to seconds
        
        let content = UNMutableNotificationContent()
        content.title = campaign.title
        content.body = campaign.body
        content.sound = campaign.sound
        content.categoryIdentifier = "CAMPAIGN"
        
        if let badge = campaign.badge {
            content.badge = NSNumber(value: badge)
        }
        
        // Add campaign info
        content.userInfo = [
            "type": campaign.type.rawValue,
            "campaignId": campaign.id,
            "delayHours": campaign.delayHours,
            "scheduledFor": Date().addingTimeInterval(delaySeconds).timeIntervalSince1970
        ]
        
        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delaySeconds,
            repeats: false
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "campaign_\(campaign.id)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📅 Campaign notification scheduled: \(campaign.id) in \(campaign.delayHours)h")
        } catch {
            print("❌ Failed to schedule campaign notification \(campaign.id): \(error)")
        }
    }
    
    /// Stop the current engagement campaign
    func stopEngagementCampaign() {
        // Remove all campaign notifications
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let campaignIdentifiers = requests
                .filter { $0.identifier.hasPrefix("campaign_") }
                .map { $0.identifier }
            
            center.removePendingNotificationRequests(withIdentifiers: campaignIdentifiers)
            print("🛑 Stopped campaign: removed \(campaignIdentifiers.count) notifications")
        }
        
        // Clear campaign started flag
        userDefaults.removeObject(forKey: campaignStartedKey)
    }
    
    /// Check if a campaign is currently running
    /// - Returns: Bool indicating if campaign is active
    func isCampaignRunning() -> Bool {
        return userDefaults.object(forKey: campaignStartedKey) != nil
    }
    
    /// Enable or disable campaigns
    /// - Parameter enabled: Whether campaigns should be enabled
    func setCampaignsEnabled(_ enabled: Bool) {
        campaignsEnabled = enabled
        userDefaults.set(enabled, forKey: campaignsEnabledKey)
        
        if !enabled {
            stopEngagementCampaign()
        }
        
        print("📢 Campaigns \(enabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Badge Management
    
    /// Set the app badge count
    /// - Parameter count: Badge count (0 to clear)
    func setBadgeCount(_ count: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error = error {
                    print("❌ Failed to set badge count: \(error)")
                } else {
                    print("🔢 Badge count set to: \(count)")
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
            print("🔢 Badge count set to: \(count)")
        }
        
        // Always update our tracked count
        currentBadgeCount = count
    }
    
    /// Clear the app badge
    func clearBadge() {
        setBadgeCount(0)
    }
    
    /// Increment badge count
    /// - Parameter by: Amount to increment (default: 1)
    func incrementBadge(by amount: Int = 1) {
        let newCount = currentBadgeCount + amount
        setBadgeCount(newCount)
    }
    
    // MARK: - Utility Methods
    
    /// Get all pending notifications
    /// - Returns: Array of pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    /// Cancel a specific notification
    /// - Parameter identifier: Notification identifier to cancel
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled notification: \(identifier)")
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        stopEngagementCampaign()
        print("🗑️ Cancelled all notifications")
    }
    
    /// Get notification statistics
    /// - Returns: Dictionary with notification stats
    func getNotificationStats() async -> [String: Any] {
        let pending = await getPendingNotifications()
        let campaignNotifications = pending.filter { $0.identifier.hasPrefix("campaign_") }
        
        return [
            "totalPending": pending.count,
            "campaignPending": campaignNotifications.count,
            "campaignRunning": isCampaignRunning(),
            "campaignsEnabled": campaignsEnabled,
            "lastNotificationDate": userDefaults.object(forKey: lastNotificationDateKey) as? Date ?? "Never",
            "badgeCount": currentBadgeCount
        ]
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification tap/action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different actions
        switch response.actionIdentifier {
        case "OPEN_ACTION":
            print("📱 User chose to open app from notification")
            // Handle app opening logic here
        case "DISMISS_ACTION":
            print("❌ User dismissed notification")
        case UNNotificationDefaultActionIdentifier:
            print("📱 User tapped notification")
            // Handle default tap action
        default:
            break
        }
        
        // Log analytics
        if let type = userInfo["type"] as? String {
            print("📊 Notification interaction: \(type)")
        }
        
        completionHandler()
    }
}

