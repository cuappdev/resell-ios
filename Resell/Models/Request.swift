//
//  Request.swift
//  Resell
//
//  Created by Richie Sun on 11/7/24.
//

import Foundation

struct Request: Codable {
    let id: String
    let title: String
    let description: String
    let user: User
}

struct RequestsResponse: Codable {
    let requests: [Request]
}

struct RequestResponse: Codable {
    let request: Request
}

struct RequestBody: Codable {
    let title: String
    let description: String
    let userId: String
}
