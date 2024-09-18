//
//  String + Extensions.swift
//  Resell
//
//  Created by Richie Sun on 9/17/24.
//

extension String {

    /// Removes leading and trailing whitespace and reduces consecutive spaces between words.
    func cleaned() -> String {
        let trimmedString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedString = trimmedString.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return cleanedString
    }
}
