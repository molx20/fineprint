//
//  apiService.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 API SERVICE REFERENCE GUIDE
 
 Features:
 - Secure HTTPS-only requests
 - Bearer token authentication
 - API key authentication
 - JSON encoding/decoding
 - Comprehensive error handling
 - Request/response logging (debug only)
 - Timeout configuration
 - Custom headers support
 
 Usage Examples:
 // GET request
 let users: [User] = try await APIService.shared.get("/users")
 
 // POST request with body
 let newUser = try await APIService.shared.post("/users", body: userData)
 
 // With custom headers
 let data = try await APIService.shared.get("/protected", headers: ["X-Custom": "value"])
 
 // With authentication
 APIService.shared.setBearerToken("your-token-here")
 let profile: UserProfile = try await APIService.shared.get("/profile")
 
 Configuration:
 - Set base URL: APIService.shared.configure(baseURL: "https://api.example.com")
 - Set timeout: APIService.shared.setTimeout(30)
 - Enable logging: APIService.shared.enableLogging(true)
 */

import Foundation

// MARK: - API Error Types
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response"
        case .unauthorized:
            return "Unauthorized - check your credentials"
        case .forbidden:
            return "Forbidden - insufficient permissions"
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error (Code: \(code))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Data encoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Service
class APIService {
    static let shared = APIService()
    
    // MARK: - Configuration Properties
    private var baseURL: String = ""
    private var timeout: TimeInterval = 30.0
    private var bearerToken: String?
    private var apiKey: String?
    private var commonHeaders: [String: String] = [:]
    private var isLoggingEnabled: Bool = false
    
    // MARK: - URLSession
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        
        // Security configurations
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    // MARK: - Configuration Methods
    
    /// Configure the base URL for all API calls
    /// - Parameter baseURL: The base URL (e.g., "https://api.example.com")
    func configure(baseURL: String) {
        self.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.baseURL.hasSuffix("/") {
            self.baseURL.removeLast()
        }
    }
    
    /// Set request timeout in seconds
    /// - Parameter timeout: Timeout in seconds (default: 30)
    func setTimeout(_ timeout: TimeInterval) {
        self.timeout = timeout
        // Recreate session with new timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.session = URLSession(configuration: config)
    }
    
    /// Set Bearer token for authentication
    /// - Parameter token: The bearer token
    func setBearerToken(_ token: String?) {
        self.bearerToken = token
    }
    
    /// Set API key for authentication
    /// - Parameter apiKey: The API key
    func setAPIKey(_ apiKey: String?) {
        self.apiKey = apiKey
    }
    
    /// Set common headers that will be added to all requests
    /// - Parameter headers: Dictionary of headers
    func setCommonHeaders(_ headers: [String: String]) {
        self.commonHeaders = headers
    }
    
    /// Enable or disable request/response logging (for debugging)
    /// - Parameter enabled: Whether logging is enabled
    func enableLogging(_ enabled: Bool) {
        self.isLoggingEnabled = enabled
    }
    
    // MARK: - HTTP Methods
    
    /// Perform GET request
    /// - Parameters:
    ///   - endpoint: API endpoint (e.g., "/users")
    ///   - headers: Optional additional headers
    /// - Returns: Decoded response object
    func get<T: Codable>(_ endpoint: String, headers: [String: String]? = nil) async throws -> T {
        return try await requestWithoutBody(method: .GET, endpoint: endpoint, headers: headers)
    }
    
    // MARK: - POST Methods
    
    /// Perform POST request with body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - body: Request body object
    ///   - headers: Optional additional headers
    /// - Returns: Decoded response object
    func post<T: Codable, U: Codable>(_ endpoint: String, body: U, headers: [String: String]? = nil) async throws -> T {
        return try await requestWithBody(method: .POST, endpoint: endpoint, body: body, headers: headers)
    }
    
    /// Perform POST request without body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - headers: Optional additional headers
    /// - Returns: Decoded response object
    func post<T: Codable>(_ endpoint: String, headers: [String: String]? = nil) async throws -> T {
        return try await requestWithoutBody(method: .POST, endpoint: endpoint, headers: headers)
    }
    
    // MARK: - PUT Methods
    
    /// Perform PUT request with body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - body: Request body object
    ///   - headers: Optional additional headers
    /// - Returns: Decoded response object
    func put<T: Codable, U: Codable>(_ endpoint: String, body: U, headers: [String: String]? = nil) async throws -> T {
        return try await requestWithBody(method: .PUT, endpoint: endpoint, body: body, headers: headers)
    }
    
    /// Perform PUT request without body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - headers: Optional additional headers
    /// - Returns: Decoded response object
    func put<T: Codable>(_ endpoint: String, headers: [String: String]? = nil) async throws -> T {
        return try await requestWithoutBody(method: .PUT, endpoint: endpoint, headers: headers)
    }
    
    /// Perform DELETE request
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - headers: Optional additional headers
    /// - Returns: Decoded response object
    func delete<T: Codable>(_ endpoint: String, headers: [String: String]? = nil) async throws -> T {
        return try await requestWithoutBody(method: .DELETE, endpoint: endpoint, headers: headers)
    }
    
    // MARK: - PATCH Methods
    
    /// Perform PATCH request with body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - body: Request body object
    ///   - headers: Optional additional headers
    /// - Returns: Decoded response object
    func patch<T: Codable, U: Codable>(_ endpoint: String, body: U, headers: [String: String]? = nil) async throws -> T {
        return try await requestWithBody(method: .PATCH, endpoint: endpoint, body: body, headers: headers)
    }
    
    /// Perform PATCH request without body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - headers: Optional additional headers
    /// - Returns: Decoded response object
    func patch<T: Codable>(_ endpoint: String, headers: [String: String]? = nil) async throws -> T {
        return try await requestWithoutBody(method: .PATCH, endpoint: endpoint, headers: headers)
    }
    
    // MARK: - Core Request Methods
    
    /// Core request method for requests with body
    private func requestWithBody<T: Codable, U: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: U,
        headers: [String: String]? = nil
    ) async throws -> T {
        
        // Validate base URL is configured
        guard !baseURL.isEmpty else {
            throw APIError.invalidURL
        }
        
        // Create full URL
        let fullURL = baseURL + endpoint
        guard let url = URL(string: fullURL) else {
            throw APIError.invalidURL
        }
        
        // Ensure HTTPS for security
        guard url.scheme == "https" else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add headers
        addHeaders(to: &request, additionalHeaders: headers)
        
        // Add body
        do {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            throw APIError.encodingError(error)
        }
        
        return try await performRequest(request)
    }
    
    /// Core request method for requests without body
    private func requestWithoutBody<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        headers: [String: String]? = nil
    ) async throws -> T {
        
        // Validate base URL is configured
        guard !baseURL.isEmpty else {
            throw APIError.invalidURL
        }
        
        // Create full URL
        let fullURL = baseURL + endpoint
        guard let url = URL(string: fullURL) else {
            throw APIError.invalidURL
        }
        
        // Ensure HTTPS for security
        guard url.scheme == "https" else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add headers
        addHeaders(to: &request, additionalHeaders: headers)
        
        return try await performRequest(request)
    }
    
    /// Performs the actual network request and handles response
    private func performRequest<T: Codable>(_ request: URLRequest) async throws -> T {
        
        // Log request if enabled
        if isLoggingEnabled {
            logRequest(request)
        }
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            // Log response if enabled
            if isLoggingEnabled {
                logResponse(data: data, response: response)
            }
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Handle HTTP status codes
            try handleHTTPStatusCode(httpResponse.statusCode)
            
            // Handle empty responses for certain status codes
            if httpResponse.statusCode == 204 || data.isEmpty {
                // For 204 No Content or empty data, return empty object if T allows it
                if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                }
            }
            
            // Decode response
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
            
        } catch {
            if error is APIError {
                throw error
            } else {
                throw APIError.networkError(error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addHeaders(to request: inout URLRequest, additionalHeaders: [String: String]?) {
        // Add common headers
        for (key, value) in commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add authentication headers
        if let bearerToken = bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let apiKey = apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        
        // Add additional headers
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("iOS", forHTTPHeaderField: "User-Agent")
    }
    
    private func handleHTTPStatusCode(_ statusCode: Int) throws {
        switch statusCode {
        case 200...299:
            break // Success
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError(statusCode)
        default:
            throw APIError.serverError(statusCode)
        }
    }
    
    private func logRequest(_ request: URLRequest) {
        print("🌐 API Request:")
        print("URL: \(request.url?.absoluteString ?? "Unknown")")
        print("Method: \(request.httpMethod ?? "Unknown")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        print("---")
    }
    
    private func logResponse(data: Data, response: URLResponse) {
        print("📡 API Response:")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("Body: \(responseString)")
        }
        print("---")
    }
}

// MARK: - Empty Response Helper
struct EmptyResponse: Codable {
    init() {}
}

