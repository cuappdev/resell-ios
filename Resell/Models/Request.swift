//
//  Request.swift
//  Resell
//
//  Created by Richie Sun on 11/7/24.
//

import Foundation

struct RequestsResponse: Codable {
    let requests: [Request]
}

struct Request: Codable {
    let id: String
    let title: String
    let description: String
    let user: User
}
