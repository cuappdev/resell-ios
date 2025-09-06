//
//  Report.swift
//  Resell
//
//  Created by Richie Sun on 11/20/24.
//

import Foundation

struct ReportPostBody: Codable {
    let reported: String
    let post: String
    let reason: String
}

struct ReportUserBody: Codable {
    let reported: String
    let reason: String
}

struct ReportMessageBody: Codable {
    let reported: String
    let message: MessageBody
    let reason: String
}

struct Report: Codable, Identifiable {
    let id: String
    let reporter: User
    let reported: User
    let post: Post?
    let message: ReportMessage?
    let reason: String
    let type: ReportType
    let resolved: Bool
    let created: Date

    enum ReportType: String, Codable {
        case post
    }

    enum CodingKeys: String, CodingKey {
        case id
        case reporter
        case reported
        case post
        case message
        case reason
        case type
        case resolved
        case created
    }
}

struct ReportMessage: Codable {
    let id: String
    let content: String
    let sender: User
    let receiver: User
    let created: Date
    let read: Bool
}
