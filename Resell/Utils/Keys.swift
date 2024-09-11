//
//  Keys.swift
//  Resell
//
//  Created by Richie Sun on 9/10/24.
//

import Foundation

struct Keys {
    static let googleClientID = Keys.keyDict["CLIENT_ID"] as? String ?? ""
    static let resellServer = Keys.keyDict["RESELL_SERVER_URL"] as? String ?? ""
    static let googlePlacesKey = Keys.keyDict["GOOGLE_API_KEY"] as? String ?? ""

    private static let keyDict: NSDictionary = {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) else { return [:] }
        return dict
    }()
}
