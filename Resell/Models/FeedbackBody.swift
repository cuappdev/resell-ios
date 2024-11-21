//
//  FeedbackBody.swift
//  Resell
//
//  Created by Richie Sun on 11/17/24.
//

import Foundation

struct FeedbackBody: Codable {
    let description: String
    let images: [String]
    let userId: String
}
