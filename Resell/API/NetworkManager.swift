//
//  NetworkManager.swift
//  Resell
//
//  Created by Richie Sun on 11/2/24.
//

import Combine
import Foundation

class NetworkManager: APIClient {

    // MARK: - Shared Instance

    static let shared = NetworkManager()

    // MARK: - Properties

    private let hostURL: String = Keys.prodServerURL
    private let urlCache: URLCache

    // MARK: - Initializer

    init(urlCache: URLCache = .shared) {
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
        if let cachedResponse = urlCache.cachedResponse(for: URLRequest(url: url)) {
            return try JSONDecoder().decode(T.self, from: cachedResponse.data)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let cachedResponse = CachedURLResponse(response: response, data: data)
        urlCache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))

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
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func post<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Auth Networking Functions

    func createUser(user: User) async throws -> UserResponse {
        guard let url = URL(string: "https://api.example.com/users") else {
            throw URLError(.badURL)
        }

        return try await post(url: url, body: user)
    }

    func getUser() async throws -> UserResponse {
        guard let url = URL(string: "\(hostURL)/auth/") else {
            throw URLError(.badURL)
        }

        return try await get(url: url)
    }

    func getUserByGoogleID(googleID: String) async throws -> UserResponse {
        guard let url = URL(string: "\(hostURL)/user/googleId/\(googleID)/") else {
            throw URLError(.badURL)
        }

        return try await get(url: url)
    }

}
