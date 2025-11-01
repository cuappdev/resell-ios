//
//  ChatDocument.swift
//  Resell
//
//  Created by Richie Sun on 11/30/24.
//

import Foundation
import FirebaseFirestore

struct ChatDocument: Codable, Identifiable {
    var id: String { _id }
    var _id: String
    var createdAt: Timestamp
    var user: UserDocument
    var availability: AvailabilityDocument?
    var product: Post?
    var image: String
    var text: String
    var meetingInfo: MeetingInfo?
}

struct ChatDocumentSendable: Codable, Identifiable {
    var id: String { _id }
    var _id: String
    var createdAt: Timestamp
    var user: UserDocument
    var availability: [AvailabilityBlock]?
    var product: [String : String]
    var image: String
    var text: String
    var meetingInfo: MeetingInfo?
}

struct AvailabilityDocument: Codable {
    let availabilities: [AvailabilityBlock]
}

struct AvailabilityBlock: Codable, Identifiable {
    let startDate: Timestamp
    let color: String
    var id: Int
    var endDate: Timestamp

    init(startDate: Timestamp, color: String = AvailabilityBlock.defaultColor, id: Int? = nil) {
        self.startDate = startDate
        self.color = color
        self.id = id ?? Int.random(in: 0...9999)
        
        let startDateTime = startDate.dateValue()
        let endDateTime = Calendar.current.date(byAdding: .minute, value: 30, to: startDateTime) ?? startDateTime
        self.endDate = Timestamp(date: endDateTime)
    }

    static var defaultColor: String {
        let color = Constants.Colors.resellPurple
        guard let components = color.cgColor?.components, components.count >= 3 else {
            return "#000000"
        }

        let red = components[0]
        let green = components[1]
        let blue = components[2]

        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}

struct MeetingInfo: Codable {
    var state: String
    var proposeTime: String
    var proposer: String?
    var canceler: String?
    var mostRecent: Bool

    func toFirebaseMap() -> [String: Any] {
        return [
            "state": state,
            "proposeTime": proposeTime,
            "proposer": proposer ?? "",
            "canceler": canceler ?? "",
            "mostRecent": mostRecent
        ]
    }
}
