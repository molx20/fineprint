//
//  finePrintAPI.swift
//  FinePrint
//
//  API service for FinePrint backend integration
//

import Foundation
import UIKit

/// API service for communicating with FinePrint backend
class FinePrintAPI {
    static let shared = FinePrintAPI()

    private let session: URLSession

    // MARK: - Initialization

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // Longer timeout for OCR/scraping
        config.timeoutIntervalForResource = 180
        self.session = URLSession(configuration: config)

        // Log current API configuration on initialization
        print("FinePrint API initialized")
        print(APIConfig.description)
    }

    // MARK: - API Methods

    /// Analyze a URL for fine print
    func analyzeURL(_ urlString: String, userId: String) async throws -> AnalysisResult {
        let endpoint = APIConfig.analyzeURL

        guard let url = URL(string: endpoint) else {
            throw FinePrintError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = AnalyzeURLRequest(url: urlString, userId: userId)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Network-level error (DNS failure, timeout, no connection, etc.)
            if APIConfig.isProduction {
                throw FinePrintError.networkError(message: "We couldn't reach the FinePrint server. Please check your internet connection and try again.")
            } else {
                throw FinePrintError.networkError(message: "Could not connect to backend at \(APIConfig.baseURL). Make sure the server is running.")
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FinePrintError.invalidResponse
        }

        // Handle HTTP errors
        if httpResponse.statusCode == 429 {
            // Rate limit reached
            let errorResponse = try JSONDecoder().decode(APIErrorDetail.self, from: data)
            throw FinePrintError.limitReached(message: errorResponse.detail.message)
        }

        if httpResponse.statusCode == 422 {
            // Unprocessable content (e.g., JavaScript-heavy page)
            if let errorResponse = try? JSONDecoder().decode(APIErrorDetail.self, from: data) {
                throw FinePrintError.analysisFailed(message: errorResponse.detail.message)
            }
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(APIErrorDetail.self, from: data) {
                throw FinePrintError.analysisFailed(message: errorResponse.detail.message)
            }
            throw FinePrintError.analysisFailed(message: "Server returned status \(httpResponse.statusCode)")
        }

        // Parse success response
        let analyzeResponse = try JSONDecoder().decode(AnalyzeResponse.self, from: data)

        guard let analysis = analyzeResponse.analysis else {
            throw FinePrintError.invalidResponse
        }

        return analysis
    }

    // Image analysis removed - URL only
}

// MARK: - Helper Structures

private struct APIErrorDetail: Codable {
    let detail: ErrorDetail

    struct ErrorDetail: Codable {
        let error: String
        let message: String
    }
}
