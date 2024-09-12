//
//  Array + Extensions.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import Foundation

extension Array {
    /// Splits the array into two arrays based on even and odd indices, sorted.
    ///
    /// - Returns: A tuple containing two arrays:
    ///   - The first array contains elements at even indices.
    ///   - The second array contains elements at odd indices.
    func splitIntoTwo() -> ([Element], [Element]) {
        var data1: [Element] = []
        var data2: [Element] = []

        for (index, element) in self.enumerated() {
            if index % 2 == 0 {
                data1.append(element)
            } else {
                data2.append(element)
            }
        }

        return (data1, data2)
    }
}
