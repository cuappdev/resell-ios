//
//  File.swift
//  Resell
//
//  Created by Richie Sun on 11/12/24.
//

import Foundation

struct FeedbackResponse: Codable {
    let feedbacks: [Feedback]
}

struct Feedback: Codable {
    let id: String
    let description: String
    let images: [String]
    let user: User?
}
