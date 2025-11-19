//
//  APIConfig.swift
//  FinePrint
//
//  Environment-based API configuration for FinePrint backend
//

import Foundation

/// Represents the deployment environment for the app
enum AppEnvironment {
    case development  // Local development with backend on localhost
    case production   // Production backend on Railway

    /// Current active environment - change this to switch between dev and prod
    static let current: AppEnvironment = .production
}

/// Configuration for FinePrint API endpoints
struct APIConfig {

    /// Base URL for the FinePrint backend API
    static var baseURL: String {
        switch AppEnvironment.current {
        case .development:
            return developmentURL
        case .production:
            return productionURL
        }
    }

    /// Development URL - used when running backend locally
    private static var developmentURL: String {
        #if targetEnvironment(simulator)
        // Simulator can use localhost
        return "http://localhost:8001"
        #else
        // Physical device on same network needs Mac's IP
        // You can update this IP if your local network changes
        return "http://192.168.12.138:8001"
        #endif
    }

    /// Production URL - Railway hosted backend
    /// IMPORTANT: Update this after deploying to Railway!
    /// Example: "https://fineprint-backend-production.up.railway.app"
    private static let productionURL: String = "REPLACE_WITH_RAILWAY_URL"

    /// Full URL for the analyze endpoint
    static var analyzeURL: String {
        return "\(baseURL)/analyze/url"
    }

    /// Full URL for the health check endpoint
    static var healthURL: String {
        return "\(baseURL)/health"
    }

    /// Configuration information for debugging
    static var description: String {
        return """
        FinePrint API Configuration
        ---------------------------
        Environment: \(AppEnvironment.current)
        Base URL: \(baseURL)
        Analyze URL: \(analyzeURL)
        Health URL: \(healthURL)
        """
    }

    /// Check if using production environment
    static var isProduction: Bool {
        return AppEnvironment.current == .production
    }

    /// Check if using development environment
    static var isDevelopment: Bool {
        return AppEnvironment.current == .development
    }
}

// MARK: - Usage Instructions
/*
 How to use APIConfig:

 1. FOR LOCAL DEVELOPMENT:
    - Set AppEnvironment.current = .development
    - Run your backend with: python main.py
    - The app will connect to localhost:8001

 2. FOR PRODUCTION:
    - Deploy backend to Railway (see backend/README.md)
    - Copy the Railway URL (e.g., https://fineprint-backend-production.up.railway.app)
    - Update APIConfig.productionURL with your Railway URL
    - Set AppEnvironment.current = .production
    - Build and run the app

 3. SWITCHING ENVIRONMENTS:
    - Simply change AppEnvironment.current
    - Rebuild the app
    - No need to change code in other files

 4. IN YOUR CODE:
    - Use APIConfig.baseURL for the base URL
    - Use APIConfig.analyzeURL for the analyze endpoint
    - Use APIConfig.healthURL for health checks
    - Don't hardcode URLs anywhere else!
 */
