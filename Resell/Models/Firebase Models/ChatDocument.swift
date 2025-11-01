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

struct AvailabilityDocument: Codable {
    let availabilities: [AvailabilityBlock]

    func toFirebaseArray() -> [String: Any] {
        let sortedAvailabilities = availabilities.sorted { $0.startDate.dateValue() < $1.startDate.dateValue() }
        let availabilityArray = sortedAvailabilities.map { $0.toDictionary() }
        return ["availabilities": availabilityArray]
    }
}

struct AvailabilityBlock: Codable, Identifiable {
    let startDate: Timestamp
    let color: String
    let id: Int

    var endDate: Timestamp {
        let startDateTime = startDate.dateValue()
        let endDateTime = Calendar.current.date(byAdding: .minute, value: 30, to: startDateTime) ?? startDateTime
        return Timestamp(date: endDateTime)
    }

    init(startDate: Timestamp, color: String = AvailabilityBlock.defaultColor, id: Int) {
        self.startDate = startDate
        self.color = color
        self.id = id
    }

    static var defaultColor: String {
        let color = UIColor.systemPurple
        let hexString = String(format: "#%06X", (Int(color.cgColor.components?[0] ?? 0) << 16) | (Int(color.cgColor.components?[1] ?? 0) << 8) | Int(color.cgColor.components?[2] ?? 0))
        return hexString
    }

    func toDictionary() -> [String: Any] {
        return [
            "startDate": startDate,
            "color": color,
            "id": id,
            "endDate": endDate
        ]
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




