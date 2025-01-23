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

struct MessageBody: Codable {
    let id: String
}
