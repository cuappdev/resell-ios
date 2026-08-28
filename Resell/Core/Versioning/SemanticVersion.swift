//
//  SemanticVersion.swift
//  Resell
//
//  Created by Andrew Gao on 4/28/26.
//

import Foundation

struct SemanticVersion: Comparable {
    private let components: [Int]

    init(_ raw: String) {
        // Defensive parsing:
        // - Split by "." (standard semver)
        // - For each component, take the leading integer prefix (so "7-beta" -> 7)
        // - Missing / invalid components default to 0
        let parts = raw.split(separator: ".")
        self.components = parts.map { part in
            let prefixDigits = part.prefix { $0.isNumber }
            return Int(prefixDigits) ?? 0
        }
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for i in 0..<maxCount {
            let l = i < lhs.components.count ? lhs.components[i] : 0
            let r = i < rhs.components.count ? rhs.components[i] : 0
            if l != r { return l < r }
        }
        return false
    }
}

