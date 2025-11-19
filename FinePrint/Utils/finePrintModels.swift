//
//  finePrintModels.swift
//  FinePrint
//
//  Data models for FinePrint API integration
//

import Foundation

// MARK: - Analysis Request

struct AnalyzeURLRequest: Codable {
    let url: String
    let userId: String

    enum CodingKeys: String, CodingKey {
        case url
        case userId = "user_id"
    }
}

// MARK: - Analysis Response

struct AnalyzeResponse: Codable {
    let success: Bool
    let analysis: AnalysisResult?
    let message: String?
    let scansRemainingToday: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case analysis
        case message
        case scansRemainingToday = "scans_remaining_today"
    }
}

struct AnalysisResult: Codable, Identifiable {
    var id = UUID() // For SwiftUI List
    let offerSummary: String
    let plainEnglishSummary: String
    let hiddenRequirements: [String]
    let redFlags: [String]
    let riskScore: Int
    let clarityScore: Int
    let cancellationDifficulty: CancellationDifficulty
    let riskScoreExplanation: String?
    let clarityScoreExplanation: String?

    enum CodingKeys: String, CodingKey {
        case offerSummary
        case plainEnglishSummary
        case hiddenRequirements
        case redFlags
        case riskScore
        case clarityScore
        case cancellationDifficulty
        case riskScoreExplanation
        case clarityScoreExplanation
    }
}

enum CancellationDifficulty: String, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var color: String {
        switch self {
        case .easy: return "Success"
        case .medium: return "Warning"
        case .hard: return "Error"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .hard: return "xmark.circle.fill"
        }
    }
}

// MARK: - Error Response

struct APIErrorResponse: Codable {
    let success: Bool
    let error: String
    let message: String
    let errorCode: String?

    enum CodingKeys: String, CodingKey {
        case success
        case error
        case message
        case errorCode = "error_code"
    }
}

// MARK: - Scan History Item (for in-memory cache)

struct ScanHistoryItem: Identifiable {
    let id = UUID()
    let date: Date
    let analysis: AnalysisResult
    let sourceType: ScanSourceType
    let sourceIdentifier: String // URL or "Image"
}

enum ScanSourceType {
    case url

    var icon: String {
        return "link"
    }
}

// MARK: - API Error Codes

enum FinePrintError: Error, LocalizedError {
    case limitReached(message: String)
    case analysisFailed(message: String)
    case networkError(message: String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .limitReached(let message):
            return message
        case .analysisFailed(let message):
            return message
        case .networkError(let message):
            return message
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
