//
//  Keys.swift
//  Resell
//
//  Created by Richie Sun on 9/10/24.
//

import Foundation

struct Keys {

    static let devServerURL = Keys.mainKeyDict(key: "RESELL_DEV_URL")
    static let prodServerURL = Keys.mainKeyDict(key: "RESELL_PROD_URL")

    static let googleClientID = Keys.googleKeyDict["CLIENT_ID"] as? String ?? ""
    static let googlePlacesKey = Keys.googleKeyDict["GOOGLE_API_KEY"] as? String ?? ""

    private static let googleKeyDict: NSDictionary = {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) else { return [:] }
        return dict
    }()

    private static func mainKeyDict(key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) else { return "" }
        return dict[key] as? String ?? ""
    }
}
