//
//  URL + Extensions.swift
//  Resell
//
//  Created by Charles Liggins on 10/13/25.
//
import Foundation

extension URL {
    var cacheKey: String {
        return absoluteString
    }
}
