//
//  Extensions.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 16.10.22.
//

import Foundation
import UIKit

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Double {
    var amountStringValue: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self))
     }
}

extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}

extension UIButton {
    func buttonCorner() {
        layer.cornerRadius = 10
        clipsToBounds = true
        backgroundColor = .blue
        widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
}

extension UIViewController {
    
    internal func hideKeyboardOnTap(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap);
        
    }
    
    @objc private func hideKeyboard(){
        self.view.endEditing(true);
    }
}
