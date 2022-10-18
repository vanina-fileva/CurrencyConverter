//
//  AmountInCurrency.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 18.10.22.
//

import Foundation

struct Amount {
    let currency: Currency
    var amount: Double
}

extension Amount: Codable {
    enum CodingKeys: String, CodingKey {
        case amount
        case currency
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(currency.rawValue, forKey: .currency)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decode(Double.self, forKey: .amount)
        let rawValue = try values.decode(String.self, forKey: .currency)
        if let currency = Currency(rawValue: rawValue) {
            self.currency = currency
        } else {
            throw CocoaError(.coderValueNotFound)
        }
    }
}
