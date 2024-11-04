//
//  NetworkManager.swift
//  Resell
//
//  Created by Richie Sun on 11/2/24.
//

import Combine
import Foundation
import os

class NetworkManager: APIClient {

    // MARK: - Singleton Instance

    static let shared = NetworkManager()

    // MARK: - Error Logger for Networking

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: "Network")

    // MARK: - Properties

    private let hostURL: String = Keys.prodServerURL
    private let urlCache: URLCache

    // MARK: - Initializer

    private init(urlCache: URLCache = .shared) {
        self.urlCache = urlCache
    }

    // MARK: - Template Helper Functions

    /// Template function to FETCH data from URL and decodes it into a specified type `T`, with caching support.
    ///
    /// This function first checks if a cached response for the given URL is available in `URLCache`.
    /// If cached data exists, it decodes and returns it immediately, bypassing the network request.
    /// If there is no cached response, the function fetches data from the network, verifies the
    /// HTTP status code, caches the response, decodes the data, and then returns it as a decoded model.
    ///
    /// - Parameter url: The URL from which data should be fetched.
    /// - Returns: A publisher that emits a decoded instance of type `T` or an error if the decoding or network request fails.
    ///
    func get<T: Decodable>(url: URL) async throws -> T {
        let request = try createRequest(url: url, method: "GET")

        if let cachedResponse = urlCache.cachedResponse(for: request) {
            return try JSONDecoder().decode(T.self, from: cachedResponse.data)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let cachedResponse = CachedURLResponse(response: response, data: data)
        urlCache.storeCachedResponse(cachedResponse, for: request)

        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Template function to POST data to a specified URL with an encodable body and decodes the response into a specified type `T`.
    ///
    /// This function takes a URL and a request body, encodes the body as JSON, and sends it as part of
    /// a POST request to the given URL. It then receives the response, checks the HTTP status code, and
    /// decodes the response data into a specified type. This function is useful for sending data to a server
    /// and processing the server's JSON response.
    ///
    /// - Parameters:
    ///   - url: The URL to which the POST request will be sent.
    ///   - body: The data to be sent in the request body, which must conform to `Encodable`.
    /// - Returns: A publisher that emits a decoded instance of type `T` or an error if the decoding or network request fails.
    ///
    func post<T: Decodable, U: Encodable>(url: URL, body: U) async throws -> T {
        let requestData = try JSONEncoder().encode(body)
        let request = try createRequest(url: url, method: "POST", body: requestData)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // Overloaded post function for requests without a body
    func post<T: Decodable>(url: URL) async throws -> T {
        let request = try createRequest(url: url, method: "POST")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func createRequest(url: URL, method: String, body: Data? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let accessToken = UserSessionManager.shared.accessToken {
            request.setValue("\(accessToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        return request
    }

    private func constructURL(endpoint: String) throws -> URL {
        guard let url = URL(string: "\(hostURL)\(endpoint)") else {
            logger.error("Failed to construct URL for endpoint: \(endpoint)")
            throw URLError(.badURL)
        }

        return url
    }

    // MARK: - Auth Networking Functions

    func getUser() async throws -> UserResponse {
        let url = try constructURL(endpoint: "/auth/")

        return try await get(url: url)
    }

    func getUserSession(id: String) async throws -> UserSessionData {
        let url = try constructURL(endpoint: "/auth/sessions/\(id)/")

        return try await get(url: url)
    }

    // MARK: - User Networking Functions

    func getUserByGoogleID(googleID: String) async throws -> UserResponse {
        let url = try constructURL(endpoint: "/user/googleId/\(googleID)/")

        return try await get(url: url)
    }

    // MARK: - Post Networking Functions

    func getAllPosts() async throws -> PostResponse {
        let url = try constructURL(endpoint: "/post/")

        return try await get(url: url)
    }

    func getSavedPosts() async throws -> PostResponse {
        let url = try constructURL(endpoint: "/post/save/")

        return try await get(url: url)
    }

    func getFilteredPosts(by filter: String) async throws -> PostResponse {
        let url = try constructURL(endpoint: "/post/filter/")

        return try await post(url: url, body: FilterRequest(category: filter))
    }

}
