//
//  APIClient.swift
//  Resell
//
//  Created by Richie Sun on 11/2/24.
//

import Combine
import SwiftUI

protocol APIClient {

    func get<T: Decodable>(url: URL) async throws -> T

    func post<T: Decodable, U: Encodable>(url: URL, body: U) async throws -> T
    
}

