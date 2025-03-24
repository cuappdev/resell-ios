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

    var errorDescription: String? {
        return error
    }
}
