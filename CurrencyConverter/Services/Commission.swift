//
//  ExchangeFee.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 18.10.22.
//

import Foundation

protocol CommissionApplying {
    func nextApplicationDescription(sourceAmount: Double, sourceCurrency: String,
                                    targetAmount: Double, targetCurrency: String) -> String
    func afterApplication(sourceAmount: Double, sourceCurrency: String,
                          targetAmount: Double, targetCurrency: String) -> (sourceAmount: Double, targetAmount: Double)
    
}

class PercentageCommissionApplier: CommissionApplying {
    private let percentage = 0.07
    private var applicationsCount = 0
    
    func nextApplicationDescription(sourceAmount: Double, sourceCurrency: String,
                                    targetAmount: Double, targetCurrency: String) -> String {
        "\((sourceAmount * percentage).amountStringValue) \(sourceCurrency)"
    }
    
    func afterApplication(sourceAmount: Double, sourceCurrency: String,
                          targetAmount: Double, targetCurrency: String) -> (sourceAmount: Double, targetAmount: Double) {
        applicationsCount += 1
        return (sourceAmount * (1 + percentage), targetAmount)
    }
}
