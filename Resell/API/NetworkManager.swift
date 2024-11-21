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

    // MARK: - Init

    private init() { }

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

        let (data, response) = try await URLSession.shared.data(for: request)

        try handleResponse(data: data, response: response)

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

        try handleResponse(data: data, response: response)

        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Overloaded post function for requests without a return
    func post<U: Encodable>(url: URL, body: U) async throws{
        let requestData = try JSONEncoder().encode(body)
        let request = try createRequest(url: url, method: "POST", body: requestData)

        let (data, response) = try await URLSession.shared.data(for: request)

        try handleResponse(data: data, response: response)
    }

    /// Overloaded post function for requests without a body
    func post<T: Decodable>(url: URL) async throws -> T {
        let request = try createRequest(url: url, method: "POST")

        let (data, response) = try await URLSession.shared.data(for: request)

        try handleResponse(data: data, response: response)

        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Template function to DELETE data to a specified URL with an encodable body and decodes the response into a specified type `T`.
    func delete(url: URL) async throws {
        let request = try createRequest(url: url, method: "DELETE")

        let (data, response) = try await URLSession.shared.data(for: request)

        try handleResponse(data: data, response: response)
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

    private func handleResponse(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw errorResponse
            } else {
                throw URLError(.init(rawValue: httpResponse.statusCode))
            }
        }
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

    func getUserByID(id: String) async throws -> UserResponse {
        let url = try constructURL(endpoint: "/user/id/\(id)/")

        return try await get(url: url)
    }

    func updateUserProfile(edit: EditUser) async throws -> UserResponse {
        let url = try constructURL(endpoint: "/user/")

        return try await post(url: url, body: edit)
    }

    func getBlockedUsers(id: String) async throws -> UsersResponse {
        let url = try constructURL(endpoint: "/user/blocked/id/\(id)")

        return try await get(url: url)
    }

    func blockUser(blocked: BlockUser) async throws {
        let url = try constructURL(endpoint: "/user/block/")

        try await post(url: url, body: blocked)
    }

    func unblockUser(unblocked: UnblockUser) async throws {
        let url = try constructURL(endpoint: "/user/unblock/")

        try await post(url: url, body: unblocked)
    }

    // MARK: - Post Networking Functions

    func getAllPosts() async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/")

        return try await get(url: url)
    }

    func getSavedPosts() async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/save/")

        return try await get(url: url)
    }

    func getFilteredPosts(by filter: String) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/filter/")

        return try await post(url: url, body: FilterRequest(category: filter))
    }

    func getSearchedPosts(with keywords: String) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/search/")

        return try await post(url: url, body: SearchRequest(keywords: keywords))
    }

    func getPostsByUserID(id: String) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/userId/\(id)/")

        return try await get(url: url)
    }

    func getArchivedPostsByUserID(id: String) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/archive/userId/\(id)/")

        return try await get(url: url)
    }

    func getPostByID(id: String) async throws -> PostResponse {
        let url = try constructURL(endpoint: "/post/id/\(id)/")

        return try await get(url: url)
    }

    func savePostByID(id: String) async throws -> PostResponse {
        let url = try constructURL(endpoint: "/post/save/postId/\(id)/")

        return try await post(url: url)
    }

    func unsavePostByID(id: String) async throws -> PostResponse {
        let url = try constructURL(endpoint: "/post/unsave/postId/\(id)/")

        return try await post(url: url)
    }

    func postIsSaved(id: String) async throws -> SavedResponse {
        let url = try constructURL(endpoint: "/post/isSaved/postId/\(id)/")

        return try await get(url: url)
    }

    func createPost(postBody: PostBody) async throws -> ListingResponse {
        let url = try constructURL(endpoint: "/post/")

        return try await post(url: url, body: postBody)
    }

    func archivePost(id: String) async throws -> PostResponse {
        let url = try constructURL(endpoint: "/post/archive/postId/\(id)/")

        return try await post(url: url)
    }

    func deletePost(id: String) async throws {
        let url = try constructURL(endpoint: "/post/id/\(id)/")

        try await delete(url: url)
    }

    // MARK: - Request Networking Functions

    func getRequestsByUserID(id: String) async throws -> RequestsResponse {
        let url = try constructURL(endpoint: "/request/userId/\(id)/")

        return try await get(url: url)
    }

    func postRequest(request: RequestBody) async throws -> RequestResponse {
        let url = try constructURL(endpoint: "/request/")

        return try await post(url: url, body: request)
    }

    func deleteRequest(id: String) async throws {
        let url = try constructURL(endpoint: "/request/id/\(id)/")

        try await delete(url: url)
    }

    // MARK: - Feedback Networking Functions

    func postFeedback(feedback: FeedbackBody) async throws {
        let url = try constructURL(endpoint: "/feedback/")

        try await post(url: url, body: feedback)
    }
}
