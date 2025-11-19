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

    var errorDescription: String? {
        return error
    }
}
