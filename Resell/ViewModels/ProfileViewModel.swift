//
//  ProfileViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/23/24.
//

import SwiftUI


// TODO: Replace with backend model
struct DummyUser {
    let name: String
    let username: String
    let profile: String
    let bio: String
}


@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: - Properties

    @Published var selectedTab: Tab = .listing
    @Published var user: DummyUser? = DummyUser(name: "Justin", username: "DJBustin", profile: "justin", bio: "Follow me at @thiscooking_g")

    enum Tab: String {
        case listing, archive, wishlist
    }

    // MARK: - Functions

    func updateItemsGallery() {
        // TODO: Implement Filtering for Profile Tabs
        switch selectedTab {
        case .listing:
            print("List")
            return
        case .archive:
            print("Arch")
            return
        case .wishlist:
            print("Wish")
            return
        }
    }

}
