//
//  NetworkManager.swift
//  Resell
//
//  Created by Richie Sun on 11/2/24.
//

import Combine
import Foundation
import os

class NetworkManager {
    
    // MARK: - Singleton Instance
    
    static let shared = NetworkManager()
    
    // MARK: - Error Logger for Networking
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: "#file")
    
    // MARK: - Properties

    #if DEBUG
        private let hostURL: String = Keys.devServerURL
    #else
        private let hostURL: String = Keys.localServerURL
    private let maxAttempts = 2
    
    /// Shared JSON encoder configured for backend compatibility (sends dates as ISO8601 strings)
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        // Backend expects ISO8601 strings like "2026-01-28T03:12:55.810Z"
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: date))
        }
        return encoder
    }()
    
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
            let request = try await createRequest(url: url, method: "GET")
            
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
            let requestData = try jsonEncoder.encode(body)
            let request = try await createRequest(url: url, method: "POST", body: requestData)
            
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
            let requestData = try jsonEncoder.encode(body)
            let request = try await createRequest(url: url, method: "POST", body: requestData)
            
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
            let request = try await createRequest(url: url, method: "POST")
            
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
            let request = try await createRequest(url: url, method: "DELETE")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            do {
                try handleResponse(data: data, response: response)
            } catch {
                try await handleNetworkError(error, attempt: attempt) {
                    try await delete(url: url, attempt: attempt + 1)
                }
            }
        }
            
        private func createRequest(url: URL, method: String, body: Data? = nil) async throws -> URLRequest {
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // refactor to use cached token if valid...
            let accessToken = try await GoogleAuthManager.shared.getValidToken()
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
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
            let url = try constructURL(endpoint: "/auth")
            
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
        
        func followUser(follow: FollowUserBody) async throws -> UserResponse {
            let url = try constructURL(endpoint: "/user/follow/")
            
            return try await post(url: url, body: follow)
        }
        
        func unfollowUser(unfollow: UnfollowUserBody) async throws -> UserResponse {
            let url = try constructURL(endpoint: "/user/unfollow/")
            
            return try await post(url: url, body: unfollow)
        }
        
        func getFollowers(id: String) async throws -> UsersResponse {
            let url = try constructURL(endpoint: "/user/followers/id/\(id)/")
            
            return try await get(url: url)
        }
        
        func getFollowing(id: String) async throws -> UsersResponse {
            let url = try constructURL(endpoint: "/user/following/id/\(id)/")
            
            return try await get(url: url)
        }
        
        // MARK: - Post Networking Functions
        
        func getAllPosts(page: Int = 1) async throws -> PostsResponse {
            let url = try constructURL(endpoint: "/post?page=\(page)")
            
            return try await get(url: url)
        }
        
        func getUnifiedFilteredPosts(filters: FilterPostsUnifiedRequest) async throws -> PostsResponse {
            let url = try constructURL(endpoint: "/post/filter/")
            
            return try await post(url: url, body: filters)
        }
        
        func getSavedPosts() async throws -> PostsResponse {
            let url = try constructURL(endpoint: "/post/save/")
            
            
            return try await get(url: url)
        }
        
        func getFilteredPostsByCategory(for filters: [String]) async throws -> PostsResponse {
            let url = try constructURL(endpoint: "/post/filterByCategories")
            
            return try await post(url: url, body: FilterRequest(categories: filters))
        }
        
        // this can prob go bye bye
        func getFilteredPosts(by filter: String) async throws -> PostsResponse {
            let url = try constructURL(endpoint: "/post/filter/")
            
            return try await post(url: url, body: FilterRequest(categories: [filter]))
        }
        
        func getSearchedPosts(with keywords: String) async throws -> SearchedPostResponse {
            let url = try constructURL(endpoint: "/post/search/")
            
            
            return try await post(url: url, body: SearchRequest(keywords: keywords))
        }
        
        func getSearchSuggestions(searchIndex: String) async throws -> SuggestionsWrapper {
            let url = try constructURL(endpoint: "/post/searchSuggestions/\(searchIndex)")
            
            return try await get(url: url)
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
        
        func filterByCondition(conditions: [String]) async throws -> PostsResponse {
            let url = try constructURL(endpoint: "/post/filterByCondition/")
            
            return try await post(url: url, body: ConditionBody(conditions: conditions))
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
        
        /// Send initial proposal (buyer proposes a meeting time)
        func sendInitialProposal(chatId: String, messageBody: MessageBody) async throws {
            let url = try constructURL(endpoint: "/chat/proposal/initial/\(chatId)/")
            
            // Debug: Log what dates we're sending
            if let start = messageBody.startDate, let end = messageBody.endDate {
                print("📅 Sending initial proposal with dates:")
                print("   startDate: \(start) (ms: \(Int64(start.timeIntervalSince1970 * 1000)))")
                print("   endDate: \(end) (ms: \(Int64(end.timeIntervalSince1970 * 1000)))")
            }
            
            let encoded = try jsonEncoder.encode(messageBody)
            if let jsonString = String(data: encoded, encoding: .utf8) {
                print("📤 Encoded initial proposal body: \(jsonString)")
            }
            
            return try await post(url: url, body: messageBody)
        }
        
        /// Respond to a proposal (seller accepts or declines)
        func respondToProposal(chatId: String, messageBody: ProposalResponseBody) async throws -> ProposalResponseResult {
            let url = try constructURL(endpoint: "/chat/proposal/\(chatId)/")
            
            // Debug: Log what dates we're sending
            print("📅 Responding to proposal with dates:")
            print("   startDate: \(messageBody.startDate) (ms: \(Int64(messageBody.startDate.timeIntervalSince1970 * 1000)))")
            print("   endDate: \(messageBody.endDate) (ms: \(Int64(messageBody.endDate.timeIntervalSince1970 * 1000)))")
            
            let encoded = try jsonEncoder.encode(messageBody)
            if let jsonString = String(data: encoded, encoding: .utf8) {
                print("📤 Encoded proposal body: \(jsonString)")
            }
            
            return try await post(url: url, body: messageBody)
        }
        
        /// Cancel a proposal
        func cancelProposal(chatId: String, messageBody: MessageBody) async throws {
            let url = try constructURL(endpoint: "/chat/proposal/cancel/\(chatId)/")
            return try await post(url: url, body: messageBody)
        }
        
        func markMessageRead(chatId: String, messageId: String) async throws -> ReadMessageRepsonse {
            let url = try constructURL(endpoint: "/chat/\(chatId)/message/\(messageId)/")
            
            return try await post(url: url)
        }
        
        // MARK: - Availability Networking Functions
        
        /// ISO8601 decoder for availability endpoints (dates come as strings like "2026-01-23T16:00:00Z")
        private var iso8601Decoder: JSONDecoder {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }
        
        /// ISO8601 encoder for availability endpoints (sends dates as ISO8601 strings)
        private var iso8601Encoder: JSONEncoder {
            let encoder = JSONEncoder()
            // Backend expects ISO8601 strings like "2026-01-28T03:12:55.810Z"
            encoder.dateEncodingStrategy = .custom { date, encoder in
                var container = encoder.singleValueContainer()
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                try container.encode(formatter.string(from: date))
            }
            return encoder
        }
        
        func getAvailability() async throws -> AvailabilityResponse {
            let url = try constructURL(endpoint: "/availability/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try iso8601Decoder.decode(AvailabilityResponse.self, from: data)
        }
        
        func getAvailabilityByUserID(id: String) async throws -> AvailabilityResponse {
            let url = try constructURL(endpoint: "/availability/user/\(id)")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try iso8601Decoder.decode(AvailabilityResponse.self, from: data)
        }
        
        func updateAvailability(schedule: [String: [AvailabilitySlot]]) async throws -> AvailabilityResponse {
            let url = try constructURL(endpoint: "/availability/update/")
            let requestData = try iso8601Encoder.encode(UpdateAvailabilityBody(schedule: schedule))
            
            // Debug: Log full URL and request body
            print("📅 Update availability URL: \(url.absoluteString)")
            if let jsonString = String(data: requestData, encoding: .utf8) {
                print("📅 Update availability body: \(jsonString)")
            }
            
            let request = try await createRequest(url: url, method: "POST", body: requestData)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug: Log response
            if let httpResponse = response as? HTTPURLResponse {
                print("📅 Update availability status: \(httpResponse.statusCode)")
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("📅 Update availability response: \(responseString)")
            }
            
            try handleResponse(data: data, response: response)
            return try iso8601Decoder.decode(AvailabilityResponse.self, from: data)
        }
        
        // MARK: - Transaction Networking Functions
        
        func getTransactionsByBuyerId(userId: String) async throws -> TransactionsResponse {
            let url = try constructURL(endpoint: "/transaction/buyerId/\(userId)/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try iso8601Decoder.decode(TransactionsResponse.self, from: data)
        }
        
        func getTransactionsBySellerId(userId: String) async throws -> TransactionsResponse {
            let url = try constructURL(endpoint: "/transaction/sellerId/\(userId)/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try iso8601Decoder.decode(TransactionsResponse.self, from: data)
        }
        
        func getTransactionById(transactionId: String) async throws -> TransactionResponse {
            let url = try constructURL(endpoint: "/transaction/id/\(transactionId)/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try iso8601Decoder.decode(TransactionResponse.self, from: data)
        }
        
        func completeTransaction(transactionId: String) async throws -> TransactionResponse {
            let url = try constructURL(endpoint: "/transaction/complete/id/\(transactionId)/")
            let requestData = try jsonEncoder.encode(CompleteTransactionBody(completed: true))
            let request = try await createRequest(url: url, method: "POST", body: requestData)
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            
            // Debug: Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Complete transaction raw response: \(jsonString)")
            }
            
            do {
                return try iso8601Decoder.decode(TransactionResponse.self, from: data)
            } catch let decodingError as DecodingError {
                print("❌ Transaction decoding error: \(decodingError)")
                throw decodingError
            }
        }
        
        // MARK: - Transaction Review Functions
        
        func createTransactionReview(review: CreateTransactionReviewBody) async throws -> TransactionReviewResponse {
            let url = try constructURL(endpoint: "/transactionReview/")
            let requestData = try jsonEncoder.encode(review)
            
            // Debug: Print what we're sending
            if let jsonString = String(data: requestData, encoding: .utf8) {
                print("⭐ Sending review body: \(jsonString)")
            }
            
            let request = try await createRequest(url: url, method: "POST", body: requestData)
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            
            // Debug: Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("⭐ Create review raw response: \(jsonString)")
            }
            
            // Try different response formats
            do {
                // Try wrapped format first: { "review": {...} }
                return try iso8601Decoder.decode(TransactionReviewResponse.self, from: data)
            } catch {
                print("❌ Review decoding error (wrapped): \(error)")
                
                // Try direct format: {...}
                do {
                    let review = try iso8601Decoder.decode(TransactionReview.self, from: data)
                    return TransactionReviewResponse(review: review)
                } catch {
                    print("❌ Review decoding error (direct): \(error)")
                    throw error
                }
            }
        }
        
        func getTransactionReview(transactionId: String) async throws -> TransactionReviewResponse {
            let url = try constructURL(endpoint: "/transactionReview/transactionId/\(transactionId)/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try iso8601Decoder.decode(TransactionReviewResponse.self, from: data)
        }
        
        /// Get all transaction reviews for a seller
        func getReviewsForSeller(sellerId: String) async throws -> [TransactionReview] {
            let url = try constructURL(endpoint: "/transactionReview/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            
            // Debug: print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("⭐ Transaction reviews raw response: \(jsonString.prefix(1000))")
            }
            
            var allReviews: [TransactionReview] = []
            
            // Try wrapped format first: { "reviews": [...] }
            do {
                let wrapped = try iso8601Decoder.decode(TransactionReviewsResponse.self, from: data)
                allReviews = wrapped.reviews
            } catch {
                print("❌ Wrapped decode failed: \(error)")
                // Try direct array
                do {
                    allReviews = try iso8601Decoder.decode([TransactionReview].self, from: data)
                } catch {
                    print("❌ Array decode failed: \(error)")
                    throw error
                }
            }
            
            print("⭐ Found \(allReviews.count) total transaction reviews")
            
            // NOTE: Backend doesn't include seller in transaction review response
            // For now, return all reviews. Backend should be updated to include seller info for proper filtering.
            // TODO: Filter by seller once backend includes seller in transaction object
            return allReviews
        }
        
        // MARK: - User Review Functions
        
        func createUserReview(review: CreateUserReviewBody) async throws -> UserReviewResponse {
            let url = try constructURL(endpoint: "/userReview/")
            let requestData = try jsonEncoder.encode(review)
            
            // Debug: Print what we're sending
            if let jsonString = String(data: requestData, encoding: .utf8) {
                print("👤 Sending user review body: \(jsonString)")
            }
            
            let request = try await createRequest(url: url, method: "POST", body: requestData)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug: Print HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                print("👤 User review HTTP status: \(httpResponse.statusCode)")
            }
            
            // Debug: Print raw response regardless of status
            if let jsonString = String(data: data, encoding: .utf8) {
                print("👤 Create user review raw response: \(jsonString)")
            }
            
            try handleResponse(data: data, response: response)
            
            // Try different response formats
            do {
                // Try wrapped format first: { "review": {...} }
                return try JSONDecoder().decode(UserReviewResponse.self, from: data)
            } catch {
                print("❌ User review decoding error (wrapped): \(error)")
                
                // Try direct format: {...}
                do {
                    let review = try JSONDecoder().decode(UserReview.self, from: data)
                    return UserReviewResponse(review: review)
                } catch {
                    print("❌ User review decoding error (direct): \(error)")
                    throw error
                }
            }
        }
        
        func getUserReviewsBySeller(sellerId: String) async throws -> [UserReview] {
            // Try with query parameter first
            let endpoint = "/userReview/?sellerId=\(sellerId)"
            let url = try constructURL(endpoint: endpoint)
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check if 404 - try without query parameter (fetch all)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                print("⚠️ Query parameter endpoint returned 404, trying base endpoint...")
                return try await getUserReviewsBySellerFallback(sellerId: sellerId)
            }
            
            // Handle other errors
            do {
                try handleResponse(data: data, response: response)
            } catch {
                // If handleResponse throws, try fallback
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                    return try await getUserReviewsBySellerFallback(sellerId: sellerId)
                }
                throw error
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("👤 User reviews raw response (with query): \(jsonString.prefix(1000))")
            }
            
            var allReviews: [UserReview] = []
            
            // Try wrapped format first: { "reviews": [...] }
            do {
                let wrapped = try JSONDecoder().decode(UserReviewsResponse.self, from: data)
                allReviews = wrapped.reviews
            } catch {
                // Try direct array
                do {
                    allReviews = try JSONDecoder().decode([UserReview].self, from: data)
                } catch {
                    print("❌ User reviews decode failed: \(error)")
                    throw error
                }
            }
            
            print("✅ Found \(allReviews.count) user reviews for seller \(sellerId) (query parameter worked)")
            return allReviews
        }
        
        private func getUserReviewsBySellerFallback(sellerId: String) async throws -> [UserReview] {
            // Fallback: fetch all and filter client-side (if seller info is available)
            let url = try constructURL(endpoint: "/userReview/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                print("⚠️ User reviews endpoint returned 404 - no reviews exist yet")
                return []
            }
            
            try handleResponse(data: data, response: response)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("👤 User reviews raw response (fallback): \(jsonString.prefix(1000))")
            }
            
            var allReviews: [UserReview] = []
            
            // Try wrapped format first: { "reviews": [...] }
            do {
                let wrapped = try JSONDecoder().decode(UserReviewsResponse.self, from: data)
                allReviews = wrapped.reviews
            } catch {
                // Try direct array
                do {
                    allReviews = try JSONDecoder().decode([UserReview].self, from: data)
                } catch {
                    print("❌ User reviews decode failed: \(error)")
                    throw error
                }
            }
            
            // Debug: Check what seller info we have
            print("🔍 Debugging reviews for sellerId: \(sellerId)")
            var reviewsWithSeller = 0
            for review in allReviews {
                if review.seller != nil {
                    reviewsWithSeller += 1
                }
            }
            print("  Total reviews: \(allReviews.count), Reviews with seller info: \(reviewsWithSeller)")
            
            // Filter by sellerId (only works if backend returns seller info)
            let filteredReviews = allReviews.filter { review in
                guard let sellerUid = review.seller?.firebaseUid else {
                    return false
                }
                return sellerUid == sellerId
            }
            
            if filteredReviews.isEmpty && !allReviews.isEmpty {
                print("⚠️ WARNING: Backend is not returning 'seller' field in UserReview response. Cannot filter reviews by seller.")
                print("⚠️ This is a backend issue - the response should include seller info for each review.")
            }
            
            print("✅ Found \(filteredReviews.count) user reviews for seller \(sellerId) out of \(allReviews.count) total")
            return filteredReviews
        }
        
        // MARK: - Other Networking Functions
        
        func uploadImage(image: ImageBody) async throws -> ImageResponse {
            let url = try constructURL(endpoint: "/image/")
            
            return try await post(url: url, body: image)
        }
        
        // MARK: - Notifications Networking Functions
        
        /// Custom GET for notifications with ISO8601 date decoding
        private func getNotifications(url: URL, attempt: Int = 1) async throws -> [Notifications] {
            let request = try await createRequest(url: url, method: "GET")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            do {
                try handleResponse(data: data, response: response)
            } catch {
                return try await handleNetworkError(error, attempt: attempt) {
                    try await getNotifications(url: url, attempt: attempt + 1)
                }
            }
            
            // Debug: Print raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📬 Notifications raw response: \(jsonString.prefix(1000))")
            }
            
            // Try decoding as array first (direct response)
            if let notifications = try? iso8601Decoder.decode([Notifications].self, from: data) {
                return notifications
            }
            
            // Try decoding as wrapped response { "notifications": [...] }
            if let wrapped = try? iso8601Decoder.decode(NotificationsResponse.self, from: data) {
                return wrapped.notifications
            }
            
            // If both fail, print detailed error and throw
            do {
                return try iso8601Decoder.decode([Notifications].self, from: data)
            } catch let decodingError as DecodingError {
                print("❌ Notification decoding error: \(decodingError)")
                throw decodingError
            }
        }
        
        /// Custom POST for notifications with ISO8601 date decoding
        private func postNotification<T: Decodable>(url: URL, body: some Encodable, attempt: Int = 1) async throws -> T {
            var request = try await createRequest(url: url, method: "POST")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try iso8601Encoder.encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            do {
                try handleResponse(data: data, response: response)
            } catch {
                return try await handleNetworkError(error, attempt: attempt) {
                    try await postNotification(url: url, body: body, attempt: attempt + 1)
                }
            }
            
            
            return try iso8601Decoder.decode(T.self, from: data)
        }
        
        /// Get unread notifications
        func getNewNotifications() async throws -> [Notifications] {
            let url = try constructURL(endpoint: "/notif/new")
            return try await getNotifications(url: url)
        }
        
        /// Get recent notifications (last 10)
        func getRecentNotifications() async throws -> [Notifications] {
            let url = try constructURL(endpoint: "/notif/recent")
            return try await getNotifications(url: url)
        }
        
        /// Get notifications from last 7 days
        func getLast7DaysNotifications() async throws -> [Notifications] {
            let url = try constructURL(endpoint: "/notif/last7days")
            return try await getNotifications(url: url)
        }
        
        /// Get notifications from last 30 days
        func getLast30DaysNotifications() async throws -> [Notifications] {
            let url = try constructURL(endpoint: "/notif/last30days")
            return try await getNotifications(url: url)
        }
        
        /// Mark a notification as read
        func markNotificationAsRead(notificationId: String) async throws -> Notifications {
            let url = try constructURL(endpoint: "/notif/read/\(notificationId)")
            
            var request = try await createRequest(url: url, method: "POST")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            do {
                try handleResponse(data: data, response: response)
            } catch {
                throw error
            }
            
            // Try different response formats
            if let wrapped = try? iso8601Decoder.decode(MarkReadResponse.self, from: data) {
                return wrapped.notification
            }
            
            if let wrapped = try? iso8601Decoder.decode(SingleNotificationResponse.self, from: data) {
                return wrapped.notification
            }
            
            // Try direct notification
            return try iso8601Decoder.decode(Notifications.self, from: data)
        }
        
        /// Delete a notification
        func deleteNotification(notificationId: String) async throws {
            let url = try constructURL(endpoint: "/notif/id/\(notificationId)")
            try await delete(url: url)
        }
    }
