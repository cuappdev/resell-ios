//
//  ErrorResponse.swift
//  Resell
//
//  Created by Richie Sun on 11/12/24.
//

import Foundation

struct ErrorResponse: Codable, Error {
    let error: String
    let httpCode: Int
}
