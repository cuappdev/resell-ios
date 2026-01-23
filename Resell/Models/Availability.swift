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
}

struct AvailabilitySlot: Codable {
    let startDate: Date
    let endDate: Date
}

struct UpdateAvailabilityBody: Codable {
    let schedule: [String: [AvailabilitySlot]]
}
