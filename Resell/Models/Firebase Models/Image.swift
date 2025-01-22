//
//  Image.swift
//  Resell
//
//  Created by Richie Sun on 1/21/25.
//

import Foundation

struct ImageBody: Encodable {
    let imageBase64: String
}

struct ImageResponse: Decodable {
    let image: String
}

