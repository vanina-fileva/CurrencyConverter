//
//  ExchangeFee.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 18.10.22.
//

import Foundation

protocol ExchangeFee {
//    var description: String { get }
    
    init(sourceAmount: Double, sourceCurrency: Currency)
//    func fee(sourceAmount: Double, sourceCurrency: Currency,
//             targetAmount: Double, targetCurrency: Currency) -> Double
}

class PercentageFee: ExchangeFee {
    private let fee: Double
    private let sourceCurrency: Currency
    
//    var percentage: Double { 0.07 }
    
    var description: String {
        "\(fee.amountStringValue ?? "NA") \(sourceCurrency.rawValue)"
    }
    
    
    required init(sourceAmount: Double, sourceCurrency: Currency) {
        fee = sourceAmount * 0.07
        self.sourceCurrency = sourceCurrency
    }
    
//    func fee(sourceAmount: Double, sourceCurrency: Currency, targetAmount: Double, targetCurrency: Currency) -> Double {
//        sourceAmount * percentage
//    }
}
