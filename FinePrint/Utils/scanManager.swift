//
//  scanManager.swift
//  FinePrint
//
//  Manages scan state, history, and free/paid tier logic
//

import Foundation
import SwiftUI
import PhotosUI

/// Manages the state and logic for FinePrint scanning functionality
class ScanManager: ObservableObject {
    static let shared = ScanManager()

    // MARK: - Published Properties

    @Published var isPaid: Bool = false // Toggle this for testing paid features
    @Published var scansUsedToday: Int = 0
    @Published var scanHistory: [ScanHistoryItem] = []
    @Published var isAnalyzing: Bool = false
    @Published var currentAnalysis: AnalysisResult?
    @Published var lastError: FinePrintError?

    // MARK: - Constants

    private let maxFreeScanPerDay = 1
    private let maxHistoryItems = 10
    private let userIdKey = "finePrintUserId"

    // MARK: - Computed Properties

    var scansRemainingToday: Int {
        if isPaid {
            return -1 // Unlimited
        }
        return max(0, maxFreeScanPerDay - scansUsedToday)
    }

    var canScanToday: Bool {
        isPaid || scansRemainingToday > 0
    }

    var userId: String {
        if let existing = UserDefaults.standard.string(forKey: userIdKey) {
            return existing
        }
        // Generate new user ID
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: userIdKey)
        return newId
    }

    // MARK: - Initialization

    private init() {
        loadScanCount()
    }

    // MARK: - Scan Management

    /// Analyze a URL
    func analyzeURL(_ urlString: String) async throws -> AnalysisResult {
        guard canScanToday else {
            let error = FinePrintError.limitReached(
                message: "You've used your \(maxFreeScanPerDay) free scan for today. Upgrade to get unlimited scans."
            )
            await MainActor.run {
                self.lastError = error
            }
            throw error
        }

        await MainActor.run {
            self.isAnalyzing = true
            self.lastError = nil
        }

        do {
            let result = try await FinePrintAPI.shared.analyzeURL(urlString, userId: userId)

            await MainActor.run {
                self.currentAnalysis = result
                self.isAnalyzing = false
                self.incrementScanCount()
                self.addToHistory(result, sourceType: .url, sourceIdentifier: urlString)
            }

            return result
        } catch let error as FinePrintError {
            await MainActor.run {
                self.isAnalyzing = false
                self.lastError = error
            }
            throw error
        } catch {
            let finePrintError = FinePrintError.networkError(message: error.localizedDescription)
            await MainActor.run {
                self.isAnalyzing = false
                self.lastError = finePrintError
            }
            throw finePrintError
        }
    }

    // Image analysis removed - URL only

    /// Clear current analysis and error state
    func clearAnalysis() {
        currentAnalysis = nil
        lastError = nil
    }

    // MARK: - History Management

    private func addToHistory(_ analysis: AnalysisResult, sourceType: ScanSourceType, sourceIdentifier: String) {
        let item = ScanHistoryItem(
            date: Date(),
            analysis: analysis,
            sourceType: sourceType,
            sourceIdentifier: sourceIdentifier
        )

        scanHistory.insert(item, at: 0)

        // Limit history size
        if scanHistory.count > maxHistoryItems {
            scanHistory = Array(scanHistory.prefix(maxHistoryItems))
        }
    }

    func clearHistory() {
        scanHistory.removeAll()
    }

    // MARK: - Scan Count Tracking

    private func loadScanCount() {
        let lastScanDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date ?? Date.distantPast
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = Calendar.current.startOfDay(for: lastScanDate)

        if today == lastDate {
            scansUsedToday = UserDefaults.standard.integer(forKey: "scansUsedToday")
        } else {
            scansUsedToday = 0
        }
    }

    private func incrementScanCount() {
        scansUsedToday += 1
        UserDefaults.standard.set(scansUsedToday, forKey: "scansUsedToday")
        UserDefaults.standard.set(Date(), forKey: "lastScanDate")
    }

    func resetScanCount() {
        scansUsedToday = 0
        UserDefaults.standard.set(0, forKey: "scansUsedToday")
    }

    // MARK: - Testing Helpers

    #if DEBUG
    func togglePaidStatus() {
        isPaid.toggle()
    }

    func simulateUsedScan() {
        scansUsedToday = maxFreeScanPerDay
        UserDefaults.standard.set(scansUsedToday, forKey: "scansUsedToday")
        UserDefaults.standard.set(Date(), forKey: "lastScanDate")
    }
    #endif
}
