//
//  ErrorResponse.swift
//  Resell
//
//  Created by Richie Sun on 11/12/24.
//

import Foundation

struct ErrorResponse: Codable, Error, Equatable, LocalizedError {
    let error: String
    let httpCode: Int

    static let accountCreationNeeded = ErrorResponse(error: "User not found. Please create an account first.", httpCode: 403)
    static let noCornellEmail = ErrorResponse(error: "User not found. Please create an account first.", httpCode: 403)
    static let usernameAlreadyExists = ErrorResponse(error: "UserModel with same username already exists!", httpCode: 409)
    static let userNotFound = ErrorResponse(error: "User not found.", httpCode: 404)
    static let maxRetriesHit = ErrorResponse(error: "Max retries hit. Please try again later.", httpCode: 429)

    /// When the body isn’t standard JSON, still show something actionable in alerts.
    static func fallbackMessage(forHTTPStatus code: Int) -> String {
        switch code {
        case 400:
            return "The server couldn’t process this request. If you were submitting a review, you may have already submitted one for this transaction—only one review per sale is allowed."
        case 401:
            return "Your session expired. Sign in again, then try once more."
        case 403:
            return "You don’t have permission to do that."
        case 404:
            return "That wasn’t found. It may have been removed or the link is outdated."
        case 409:
            return "That conflicts with what’s already saved—for reviews, this usually means you’ve already submitted a review for this transaction."
        case 422:
            return "Some of the information wasn’t accepted. Check the form and try again."
        case 429:
            return "Too many requests. Wait a few seconds and try again."
        case 500...599:
            return "Something went wrong on the server. Try again in a few minutes."
        default:
            return "Something went wrong (HTTP \(code))."
        }
    }

    var errorDescription: String? {
        Self.userFacingMessage(serverMessage: error, httpCode: httpCode)
    }

    /// Turns raw API text into short, specific copy for common cases (duplicate reviews, conflicts).
    private static func userFacingMessage(serverMessage: String, httpCode: Int) -> String {
        let lower = serverMessage.lowercased()

        let duplicateHints = lower.contains("duplicate")
            || lower.contains("already exists")
            || lower.contains("already been")
            || lower.contains("unique constraint")
            || lower.contains("one review")
            || lower.contains("not unique")
            || lower.contains("already submitted")
        let reviewHints = lower.contains("review")
            || lower.contains("transaction")
            || lower.contains("feedback")
            || lower.contains("rating")

        if duplicateHints && reviewHints {
            return "You’ve already submitted a review for this transaction. Each sale can only be reviewed once."
        }

        if httpCode == 409 || duplicateHints {
            if reviewHints {
                return "You’ve already submitted a review for this transaction. Each sale can only be reviewed once."
            }
            if lower.contains("username") || lower.contains("usermodel") {
                return serverMessage
            }
            return "This conflicts with existing data: \(serverMessage)"
        }

        return serverMessage
    }
}

// MARK: - Alerts

extension Error {

    /// Use in SwiftUI alerts for API errors so duplicate-review and HTTP fallbacks read clearly.
    var resellUserFacingDescription: String {
        if let er = self as? ErrorResponse {
            return er.errorDescription ?? er.error
        }
        if self is DecodingError {
            return "We couldn’t read the server’s response. Check your connection, or refresh—your review may have gone through anyway."
        }
        return localizedDescription
    }
}
