//
//  UIApplication + Extensions.swift
//  Resell
//
//  Created by Richie Sun on 9/20/24.
//

import UIKit

extension UIApplication {

    /// Dismisses the keyboard and ends any text field editing when called
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}
