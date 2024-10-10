//
//  MainView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import GoogleSignIn
import SwiftUI

struct MainView: View {

    // MARK: - Properties

    @State var selection = 0
    @StateObject private var mainViewModel = MainViewModel()

    // MARK: - UI

    var body: some View {
        ZStack {
            if mainViewModel.userDidLogin {
                CustomTabView(selection: $selection)
                    .transition(.opacity)
                    .animation(.easeInOut, value: mainViewModel.userDidLogin)
            } else {
                LoginView(userDidLogin: $mainViewModel.userDidLogin)
                    .transition(.opacity)
                    .animation(.easeInOut, value: mainViewModel.userDidLogin)
            }
        }
        .background(Constants.Colors.white)
        .environmentObject(mainViewModel)
        .onAppear {
            let signInConfig = GIDConfiguration.init(clientID: Keys.googleClientID)
            GIDSignIn.sharedInstance.configuration = signInConfig
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                //                if let user {
                //                    viewModel.userDidLogin = true
                //                }
                // Check if `user` exists; otherwise, do something with `error`
            }

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
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}
