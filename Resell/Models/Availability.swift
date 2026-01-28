//
//  Availability.swift
//  Resell
//
//  Created by Charles Liggins on 1/22/26.
//

import SwiftUI

struct AvailabilityResponse: Codable {
    let availability: UserAvailability  // Not optional!
}

struct UserAvailability: Codable {
    let id: String
    let userId: String
    let schedule: [String: [AvailabilitySlot]]
    let updatedAt: Date
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        schedule = try container.decode([String: [AvailabilitySlot]].self, forKey: .schedule)
        
        // Flexible date decoding for updatedAt
        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = AvailabilitySlot.parseDate(dateString) ?? Date()
        } else if let timestamp = try? container.decode(Double.self, forKey: .updatedAt) {
            // Check if milliseconds or seconds
            if timestamp > 1_000_000_000_000 {
                updatedAt = Date(timeIntervalSince1970: timestamp / 1000)
            } else {
                updatedAt = Date(timeIntervalSince1970: timestamp)
            }
        } else {
            updatedAt = Date()
        }
    }
}

struct AvailabilitySlot: Codable, Hashable {
    let startDate: Date
    let endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Flexible decoding for startDate
        if let dateString = try? container.decode(String.self, forKey: .startDate) {
            startDate = AvailabilitySlot.parseDate(dateString) ?? Date()
        } else if let timestamp = try? container.decode(Double.self, forKey: .startDate) {
            // Check if milliseconds or seconds
            if timestamp > 1_000_000_000_000 {
                startDate = Date(timeIntervalSince1970: timestamp / 1000)
            } else {
                startDate = Date(timeIntervalSince1970: timestamp)
            }
        } else {
            startDate = Date()
        }
        
        // Flexible decoding for endDate
        if let dateString = try? container.decode(String.self, forKey: .endDate) {
            endDate = AvailabilitySlot.parseDate(dateString) ?? Date()
        } else if let timestamp = try? container.decode(Double.self, forKey: .endDate) {
            // Check if milliseconds or seconds
            if timestamp > 1_000_000_000_000 {
                endDate = Date(timeIntervalSince1970: timestamp / 1000)
            } else {
                endDate = Date(timeIntervalSince1970: timestamp)
            }
        } else {
            endDate = Date()
        }
    }
    
    /// Parse ISO8601 date string with or without fractional seconds
    static func parseDate(_ dateString: String) -> Date? {
        // Try with fractional seconds first
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFractional.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds
        let formatterWithoutFractional = ISO8601DateFormatter()
        formatterWithoutFractional.formatOptions = [.withInternetDateTime]
        if let date = formatterWithoutFractional.date(from: dateString) {
            return date
        }
        
        return nil
    }
}

struct UpdateAvailabilityBody: Codable {
    let schedule: [String: [AvailabilitySlot]]
}
