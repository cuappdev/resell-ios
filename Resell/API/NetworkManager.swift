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

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: #file)

    // MARK: - Properties

    private let hostURL: String = Keys.devServerURL
    private let maxAttempts = 2

    // MARK: - Init
    
    private init() { }
    
    // MARK: - Template Helper Functions
    
    /// Centralized network error handling that determines whether to retry or force logout
    private func handleNetworkError<T>(_ error: Error, attempt: Int, retryOperation: () async throws -> T) async throws -> T {
        // If we've hit max attempts, force logout and throw max retries error
        if attempt >= maxAttempts {
            logger.error("Max retry attempts (\(self.maxAttempts)) reached. Forcing user logout.")
            GoogleAuthManager.shared.forceLogout(reason: "Max authentication retry attempts exceeded")
            throw ErrorResponse.maxRetriesHit
        }
        
        // Check if this is a 401 unauthorized error that we can potentially recover from
        if let errorResponse = error as? ErrorResponse, errorResponse.httpCode == 401 {
            logger.info("Received 401 error on attempt \(attempt). Attempting to refresh auth token.")
            
            do {
                // Try to refresh the authentication
                try await GoogleAuthManager.shared.refreshSignInIfNeeded()
                logger.info("Auth token refreshed successfully. Retrying network request.")
                
                // Retry the operation
                return try await retryOperation()
            } catch {
                logger.error("Failed to refresh auth token: \(error.localizedDescription)")
                GoogleAuthManager.shared.forceLogout(reason: "Failed to refresh authentication token")
                throw error
            }
        }
        
        // For non-401 errors, don't retry and just throw the original error
        throw error
    }

    /// Template function to FETCH data from URL and decodes it into a specified type `T`,
    ///
    /// The function fetches data from the network, verifies the
    /// HTTP status code, caches the response, decodes the data, and then returns it as a decoded model.
    ///
    /// - Parameter url: The URL from which data should be fetched.
    /// - Returns: A publisher that emits a decoded instance of type `T` or an error if the decoding or network request fails.
    ///
    func get<T: Decodable>(url: URL, attempt: Int = 1) async throws -> T {
        let request = try createRequest(url: url, method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)

        do {
            try handleResponse(data: data, response: response)
        } catch {
            return try await handleNetworkError(error, attempt: attempt) {
                try await get(url: url, attempt: attempt + 1)
            }
        }

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
    func post<T: Decodable, U: Encodable>(url: URL, body: U, attempt: Int = 1) async throws -> T {
        let requestData = try JSONEncoder().encode(body)
        let request = try createRequest(url: url, method: "POST", body: requestData)
        
        let (data, response) = try await URLSession.shared.data(for: request)

        do {
            try handleResponse(data: data, response: response)
        } catch {
            return try await handleNetworkError(error, attempt: attempt) {
                try await post(url: url, body: body, attempt: attempt + 1)
            }
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Overloaded post function for requests without a return
    func post<U: Encodable>(url: URL, body: U, attempt: Int = 1) async throws {
        let requestData = try JSONEncoder().encode(body)
        let request = try createRequest(url: url, method: "POST", body: requestData)
        
        let (data, response) = try await URLSession.shared.data(for: request)

        do {
            try handleResponse(data: data, response: response)
        } catch {
            try await handleNetworkError(error, attempt: attempt) {
                try await post(url: url, body: body, attempt: attempt + 1)
            }
        }
    }
    
    /// Overloaded post function for requests without a body
    func post<T: Decodable>(url: URL, attempt: Int = 1) async throws -> T {
        let request = try createRequest(url: url, method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        do {
            try handleResponse(data: data, response: response)
        } catch {
            return try await handleNetworkError(error, attempt: attempt) {
                try await post(url: url, attempt: attempt + 1)
            }
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Template function to DELETE data to a specified URL with an encodable body and decodes the response into a specified type `T`.
    func delete(url: URL, attempt: Int = 1) async throws {
        let request = try createRequest(url: url, method: "DELETE")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        do {
            try handleResponse(data: data, response: response)
        } catch {
            try await handleNetworkError(error, attempt: attempt) {
                try await delete(url: url, attempt: attempt + 1)
            }
        }
    }

    private func createRequest(url: URL, method: String, body: Data? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let accessToken = GoogleAuthManager.shared.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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

    func authorize(authorizeBody: AuthorizeBody) async throws -> User? {
        let url = try constructURL(endpoint: "/auth/")

        return try await post(url: url, body: authorizeBody)
    }

    func getUser() async throws -> UserResponse {
        let url = try constructURL(endpoint: "/auth/")
        
        return try await get(url: url)
    }

    func createUser(user: CreateUserBody) async throws {
        let url = try constructURL(endpoint: "/user/create")

        try await post(url: url, body: user)
    }
    
    func logout() async throws -> LogoutResponse {
        let url = try constructURL(endpoint: "/auth/logout/")
        
        return try await post(url: url)
    }
    
    func deleteAccount(userID: String) async throws {
        let url = try constructURL(endpoint: "/auth/id/\(userID)/")
        
        try await delete(url: url)
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

//    func getUserByEmail(email: String) async throws -> UserResponse {
//        let url = try constructURL(endpoint: "/user/email/")
//        let emailBody = UserEmailBody(email: email)
//
//        return try await post(url: url, body: emailBody)
//    }

    func updateUserProfile(edit: EditUserBody) async throws -> UserResponse {
        let url = try constructURL(endpoint: "/user/")
        
        return try await post(url: url, body: edit)
    }
    
    func getBlockedUsers(id: String) async throws -> UsersResponse {
        let url = try constructURL(endpoint: "/user/blocked/id/\(id)")
        
        return try await get(url: url)
    }
    
    func blockUser(blocked: BlockUserBody) async throws {
        let url = try constructURL(endpoint: "/user/block/")
        
        try await post(url: url, body: blocked)
    }
    
    func unblockUser(unblocked: UnblockUserBody) async throws {
        let url = try constructURL(endpoint: "/user/unblock/")
        
        try await post(url: url, body: unblocked)
    }
    
    // MARK: - Post Networking Functions

    func getAllPosts(page: Int = 1) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post?page=\(page)")

        return try await get(url: url)
    
    }
    
    func getSavedPosts() async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/save/")
        
        return try await get(url: url)
    }
    
    func getFilteredPosts(by filter: [String]) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/filterByCategories/")

        return try await post(url: url, body: FilterRequest(categories: filter))
    }
    
    func getFilteredPostsByCategory(for filters: [String]) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/filterByCategories")

        return try await post(url: url, body: FilterRequest(categories: filters))
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
    
    func getSimilarPostsByID(id: String) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/similar/postId/\(id)/")
        
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
    
    func filterByPrice(prices: PriceBody) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/filterByPrice/")
        
        return try await post(url: url, body: prices)
    }
    
    // MARK: This endpoint doesn't exist currently...
    func filterByCategory(category: CategoryBody) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/filterByCategory/")
        
        return try await post(url: url, body: category)
    }
    
    func filterByCondition(condition: ConditionBody) async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/filterByCondition/")
        
        return try await post(url: url, body: condition)
    }
    
    func filterPriceLowtoHigh() async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/priceLowtoHigh/")
        
        return try await get(url: url)
    }
    
    func filterPriceHightoLow() async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/priceHightoLow/")
        
        return try await get(url: url)
    }
    
    func filterNewlyListed() async throws -> PostsResponse {
        let url = try constructURL(endpoint: "/post/filterNewlyListed/")
        
        return try await get(url: url)
    }
    
    func createPost(postBody: PostBody) async throws -> ListingResponse {

    func createPost(postBody: PostBody) async throws -> PostResponse {
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
    
    // MARK: - Reporting Networking Functions
    
    func reportPost(reportBody: ReportPostBody) async throws {
        let url = try constructURL(endpoint: "/report/post/")
        
        try await post(url: url, body: reportBody)
    }
    
    func reportUser(reportBody: ReportUserBody) async throws {
        let url = try constructURL(endpoint: "/report/user/")
        
        try await post(url: url, body: reportBody)
    }
    
    func reportMessage(reportBody: ReportMessageBody) async throws {
        let url = try constructURL(endpoint: "/report/message/")
        
        try await post(url: url, body: reportBody)
    }

    // MARK: - Chat Networking Functions

    func sendChatMessage(chatId: String, messageBody: MessageBody) async throws {
        let url = try constructURL(endpoint: "/chat/message/\(chatId)/")

        return try await post(url: url, body: messageBody)
    }

    func sendChatAvailability(chatId: String, messageBody: MessageBody) async throws {
        let url = try constructURL(endpoint: "/chat/availability/\(chatId)/")

        return try await post(url: url, body: messageBody)
    }

    func markMessageRead(chatId: String, messageId: String) async throws -> ReadMessageRepsonse {
        let url = try constructURL(endpoint: "/chat/\(chatId)/message/\(messageId)/")

        return try await post(url: url)
    }

    // MARK: - Other Networking Functions
    
    func uploadImage(image: ImageBody) async throws -> ImageResponse {
        let url = try constructURL(endpoint: "/image/")
        
        return try await post(url: url, body: image)
    }
        // MARK: - Notifications Networking Functions
        
//    func createNotif(notifBody: Notification) async throws -> ListingResponse {
//        let url = try constructURL(endpoint: "/notif/")
//            
//        return try await post(url: url, body: notifBody)
//        }
    }

