//
//  AppVersionService.swift
//  Resell
//
//  Created by Andrew Gao on 4/28/26.
//

import Foundation

@MainActor
final class AppVersionService: ObservableObject {
    @Published private(set) var isUpdateRequired: Bool = false
    @Published private(set) var installedVersion: String = ""
    @Published private(set) var requiredVersion: String = ""

    func checkIfUpdateRequired() async {
        let installed = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        self.installedVersion = installed

        do {
            let response = try await NetworkManager.shared.getRequiredAppVersion()
            let required = response.version
            self.requiredVersion = required
            self.isUpdateRequired = SemanticVersion(installed) < SemanticVersion(required)
        } catch {
            // If we can't verify (offline/server down), don't hard-block.
            self.isUpdateRequired = false
        }
    }
}

