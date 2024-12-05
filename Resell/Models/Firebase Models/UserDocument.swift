//
//  UserDocument.swift
//  Resell
//
//  Created by Richie Sun on 11/30/24.
//

import Foundation

struct UserDocument: Codable, Identifiable {
    let id: String
    let avatar: URL
    let name: String
}

