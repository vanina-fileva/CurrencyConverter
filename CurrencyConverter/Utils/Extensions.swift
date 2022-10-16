//
//  Extensions.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 16.10.22.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Double {
    var amountStringValue: String? {
        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self))
    }
}
