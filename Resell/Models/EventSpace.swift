//
//  EventSpace.swift
//  Resell
//
//  Created by Andrew Gao on 10/11/26.
//

import SwiftUI

/// A seasonal event listings can be tagged with. `tag` is the backend
/// event-tag name and must match it exactly.
struct EventSpace: Hashable, Identifiable {
    let tag: String
    let title: String

    var id: String { tag }

    /// Square photo behind the event's Explore card, named `<tag>-card` in the asset catalog.
    var cardImageName: String { "\(tag)-card" }
    /// Wide photo heading the event's feed, named `<tag>-banner` in the asset catalog.
    var bannerImageName: String { "\(tag)-banner" }
}

struct FilterEventTagsRequest: Codable {
    let eventTags: [String]
}

/// One page of an event's listings.
struct EventPostsResponse: Codable {
    let posts: [Post]
    /// How many listings the event has across every page. `nil` from a backend
    /// that predates the count.
    let total: Int?
}
