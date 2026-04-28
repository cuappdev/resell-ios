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

        #if DEBUG
        print("[AppVersion] check starting — installed=\(installed.isEmpty ? "(empty)" : installed)")
        #endif

        do {
            let response = try await NetworkManager.shared.getRequiredAppVersion()
            let required = response.version
            self.requiredVersion = required
            let needsUpdate = SemanticVersion(installed) < SemanticVersion(required)
            self.isUpdateRequired = needsUpdate
            #if DEBUG
            print("[AppVersion] server required=\(required)")
            print("[AppVersion] comparison installed < required → \(needsUpdate) (isUpdateRequired=\(needsUpdate))")
            #endif
        } catch {
            // If we can't verify (offline/server down), don't hard-block.
            self.isUpdateRequired = false
            #if DEBUG
            print("[AppVersion] check failed — not blocking. error: \(error)")
            if let urlError = error as? URLError {
                print("[AppVersion] URLError code=\(urlError.code.rawValue) \(urlError.localizedDescription)")
            }
            #endif
        }
    }
}

