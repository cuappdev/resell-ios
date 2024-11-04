//
//  ResellApp.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import GoogleSignIn
import SwiftUI

class UserSession: ObservableObject {
    @Published var currentUserId: String? = "Test"
}

@main
struct ResellApp: App {

    @StateObject private var userSession = UserSession()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(userSession)
//            SetupProfileView()
        }
    }
}
