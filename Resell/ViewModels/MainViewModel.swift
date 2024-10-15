//
//  MainViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import SwiftUI

@MainActor
class MainViewModel: ObservableObject {

    // MARK: - Properties

    @Published var hidesTabBar: Bool = false
    @Published var userDidLogin: Bool = false

    // MARK: - Persistent Storage

    @AppStorage("chatNotificationsEnabled") var chatNotificationsEnabled: Bool = true
    @AppStorage("newListingsEnabled") var newListingsEnabled: Bool = true

    // MARK: - Functions

    func toggleAllNotifications(paused: Bool) {
        chatNotificationsEnabled = !paused
        newListingsEnabled = !paused
    }

    func setupNavBar() {
        let backButtonImage = UIImage(named: "chevron.left")?
            .resized(to: CGSize(width: 38, height: 24))
            .withRenderingMode(.alwaysOriginal)
            .withTintColor(.black)
        let appearance = UINavigationBarAppearance()
        appearance.backButtonAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: -100, vertical: 0)
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)
        UINavigationBar.appearance().standardAppearance = appearance
    }

}
