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
    // SWITCH
        private let hostURL: String = Keys.prodServerURL
    #else
        private let hostURL: String = Keys.devServerURL
    #endif
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

    /// Shared JSON decoder with a flexible date-decoding strategy that mirrors the
    /// backend's behavior (ISO8601 strings, with or without fractional seconds) and
    /// also gracefully falls back to numeric timestamps. This must match
    /// `jsonEncoder` so request/response round-trips work correctly.
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()

            if let dateString = try? container.decode(String.self) {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            if let timestamp = try? container.decode(Double.self) {
                // Heuristic: values larger than ~year 33658 are clearly milliseconds.
                if timestamp > 1_000_000_000_000 {
                    return Date(timeIntervalSince1970: timestamp / 1000)
                }
                return Date(timeIntervalSince1970: timestamp)
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Could not decode Date from any supported format"
            )
        }
        return decoder
    }()
    
    
    // MARK: - Init
    
    
    private init() { }
    
    
    // MARK: - Template Helper Functions
    
        private var authEstablishingPathSuffixes: [String] { ["/auth"] }
        
        private func shouldRetryOn401(_ request: URLRequest) -> Bool {
            guard let path = request.url?.path else { return true }
            return !authEstablishingPathSuffixes.contains { path.hasSuffix($0) }
        }
        
        /// Central request execution with 401 interceptor: refreshes token and retries when eligible.
        private func perform(requestBuilder: () async throws -> URLRequest, attempt: Int = 1) async throws -> (Data, URLResponse) {
            let request = try await requestBuilder()
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                let error = (try? JSONDecoder().decode(ErrorResponse.self, from: data)) ?? ErrorResponse(error: "Unauthorized", httpCode: 401)
                
                if attempt >= maxAttempts {
                    logger.error("Max retry attempts (\(self.maxAttempts)) reached. Forcing user logout.")
                    GoogleAuthManager.shared.forceLogout(reason: "Max authentication retry attempts exceeded")
                    throw ErrorResponse.maxRetriesHit
                }
                if !shouldRetryOn401(request) {
                    throw error
                }
                
                logger.info("Received 401 on attempt \(attempt). Refreshing auth token and retrying.")
                do {
                    try await GoogleAuthManager.shared.refreshSignInIfNeeded()
                    logger.info("Auth token refreshed. Retrying request.")
                    return try await perform(requestBuilder: requestBuilder, attempt: attempt + 1)
                } catch {
                    logger.error("Failed to refresh auth token: \(error.localizedDescription)")
                    GoogleAuthManager.shared.forceLogout(reason: "Failed to refresh authentication token")
                    throw error
                }
            }
            
            try handleResponse(data: data, response: response)
            return (data, response)
        }
        
        /// Template function to FETCH data from URL and decodes it into a specified type `T`,
        ///
        /// The function fetches data from the network, verifies the
        /// HTTP status code, caches the response, decodes the data, and then returns it as a decoded model.
        ///
        /// - Parameter url: The URL from which data should be fetched.
        /// - Returns: A publisher that emits a decoded instance of type `T` or an error if the decoding or network request fails.
        ///
        func get<T: Decodable>(url: URL) async throws -> T {
            let (data, _) = try await perform { try await createRequest(url: url, method: "GET") }
            return try jsonDecoder.decode(T.self, from: data)
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
            let requestData = try jsonEncoder.encode(body)
            let (data, _) = try await perform { try await createRequest(url: url, method: "POST", body: requestData) }
            return try jsonDecoder.decode(T.self, from: data)
        }
        
        /// Overloaded post function for requests without a return
        func post<U: Encodable>(url: URL, body: U) async throws {
            let requestData = try jsonEncoder.encode(body)
            _ = try await perform { try await createRequest(url: url, method: "POST", body: requestData) }
        }
            
        /// Overloaded post function for requests without a body
        func post<T: Decodable>(url: URL) async throws -> T {
            let (data, _) = try await perform { try await createRequest(url: url, method: "POST") }
            return try jsonDecoder.decode(T.self, from: data)
        }
            
        /// Template function to DELETE data to a specified URL
        func delete(url: URL) async throws {
            _ = try await perform { try await createRequest(url: url, method: "DELETE") }
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

        func getAvailability() async throws -> AvailabilityResponse {
            let url = try constructURL(endpoint: "/availability/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try jsonDecoder.decode(AvailabilityResponse.self, from: data)
        }
        
        func getAvailabilityByUserID(id: String) async throws -> AvailabilityResponse {
            let url = try constructURL(endpoint: "/availability/user/\(id)")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try jsonDecoder.decode(AvailabilityResponse.self, from: data)
        }
        
        func updateAvailability(schedule: [String: [AvailabilitySlot]]) async throws -> AvailabilityResponse {
            let url = try constructURL(endpoint: "/availability/update/")
            let requestData = try jsonEncoder.encode(UpdateAvailabilityBody(schedule: schedule))
            
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
            return try jsonDecoder.decode(AvailabilityResponse.self, from: data)
        }
        
        // MARK: - Transaction Networking Functions
        
        func getTransactionsByBuyerId(userId: String) async throws -> TransactionsResponse {
            let url = try constructURL(endpoint: "/transaction/buyerId/\(userId)/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try jsonDecoder.decode(TransactionsResponse.self, from: data)
        }
        
        func getTransactionsBySellerId(userId: String) async throws -> TransactionsResponse {
            let url = try constructURL(endpoint: "/transaction/sellerId/\(userId)/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try jsonDecoder.decode(TransactionsResponse.self, from: data)
        }
        
        func getTransactionById(transactionId: String) async throws -> TransactionResponse {
            let url = try constructURL(endpoint: "/transaction/id/\(transactionId)/")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            return try jsonDecoder.decode(TransactionResponse.self, from: data)
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
                return try jsonDecoder.decode(TransactionResponse.self, from: data)
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
                return try jsonDecoder.decode(TransactionReviewResponse.self, from: data)
            } catch {
                print("❌ Review decoding error (wrapped): \(error)")
                
                // Try direct format: {...}
                do {
                    let review = try jsonDecoder.decode(TransactionReview.self, from: data)
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
            return try jsonDecoder.decode(TransactionReviewResponse.self, from: data)
        }
        
        /// Get all transaction reviews for a seller. Filtering is handled server-side.
        func getReviewsForSeller(sellerId: String) async throws -> [TransactionReview] {
            let url = try constructURL(endpoint: "/transactionReview/?sellerId=\(sellerId)")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            
            do {
                return try jsonDecoder.decode(TransactionReviewsResponse.self, from: data).reviews
            } catch {
                return try jsonDecoder.decode([TransactionReview].self, from: data)
            }
        }
        
        // MARK: - User Review Functions
        
        func createUserReview(review: CreateUserReviewBody) async throws -> UserReviewResponse {
            // Refuse to create a user review without both participants.
            // Prevents seller-less or buyer-less reviews from being persisted,
            // which would later be unfilterable by seller on the client.
            let trimmedBuyer = review.buyerId.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedSeller = review.sellerId.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedBuyer.isEmpty, !trimmedSeller.isEmpty else {
                logger.error("createUserReview rejected: missing buyerId or sellerId (buyer='\(trimmedBuyer)', seller='\(trimmedSeller)')")
                throw ReviewValidationError.missingParticipants
            }
            guard trimmedBuyer != trimmedSeller else {
                logger.error("createUserReview rejected: buyer and seller are the same user (\(trimmedBuyer))")
                throw ReviewValidationError.sameBuyerAndSeller
            }
            
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
        
        /// Get all user reviews for a seller. Filtering is handled server-side.
        func getUserReviewsBySeller(sellerId: String) async throws -> [UserReview] {
            let url = try constructURL(endpoint: "/userReview/?sellerId=\(sellerId)")
            let request = try await createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(data: data, response: response)
            
            do {
                return try jsonDecoder.decode(UserReviewsResponse.self, from: data).reviews
            } catch {
                return try jsonDecoder.decode([UserReview].self, from: data)
            }
        }
        
        // MARK: - Other Networking Functions
        
        func uploadImage(image: ImageBody) async throws -> ImageResponse {
            let url = try constructURL(endpoint: "/image/")
            
            return try await post(url: url, body: image)
        }
        
        // MARK: - Notifications Networking Functions
        
        /// Custom GET for notifications with ISO8601 date decoding
        private func getNotifications(url: URL) async throws -> [Notifications] {
            let (data, _) = try await perform { try await createRequest(url: url, method: "GET") }
            
            // Debug: Print raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📬 Notifications raw response: \(jsonString.prefix(1000))")
            }
            
            // Try decoding as array first (direct response)
            if let notifications = try? jsonDecoder.decode([Notifications].self, from: data) {
                return notifications
            }
            
            // Try decoding as wrapped response { "notifications": [...] }
            if let wrapped = try? jsonDecoder.decode(NotificationsResponse.self, from: data) {
                return wrapped.notifications
            }
            
            // If both fail, print detailed error and throw
            do {
                return try jsonDecoder.decode([Notifications].self, from: data)
            } catch let decodingError as DecodingError {
                print("❌ Notification decoding error: \(decodingError)")
                throw decodingError
            }
        }
        
        /// Custom POST for notifications with ISO8601 date decoding
        private func postNotification<T: Decodable>(url: URL, body: some Encodable) async throws -> T {
            let (data, _) = try await perform {
                var request = try await createRequest(url: url, method: "POST")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try jsonEncoder.encode(body)
                return request
            }
            return try jsonDecoder.decode(T.self, from: data)
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
            if let wrapped = try? jsonDecoder.decode(MarkReadResponse.self, from: data) {
                return wrapped.notification
            }
            
            if let wrapped = try? jsonDecoder.decode(SingleNotificationResponse.self, from: data) {
                return wrapped.notification
            }
            
            // Try direct notification
            return try jsonDecoder.decode(Notifications.self, from: data)
        }
        
        /// Delete a notification
        func deleteNotification(notificationId: String) async throws {
            let url = try constructURL(endpoint: "/notif/id/\(notificationId)")
            try await delete(url: url)
        }
    }
