//
//  CurrencyData.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 14.10.22.
//

import Foundation

enum Currency: String, Codable {
    case eur = "EUR"
    case usd = "USD"
    case jpy = "JPY"
}

struct AmountInCurrency {
    var amount: Double
    let currency: Currency
}
extension AmountInCurrency: Codable {
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

protocol CurrencyBalance {
    var inCurrencies: [AmountInCurrency] { get set }
}

class CurrencyBalanceLocalStorage: CurrencyBalance {
    
    init() {
        inCurrencies = type(of: self).saved() ?? type(of: self).initial
        try? type(of: self).save(currencies: inCurrencies)
    }
    
    private static func save(currencies: [AmountInCurrency]) throws {
        let json = try JSONEncoder().encode(currencies)
        UserDefaults.standard.set(json, forKey: "all")
    }
    
    private static func saved() -> [AmountInCurrency]? {
        guard let json = UserDefaults.standard.value(forKey: "all") as? Data else {
            return nil
        }
        return try? JSONDecoder().decode([AmountInCurrency].self, from: json)
    }
    
    private static var initial: [AmountInCurrency] {
        [
            .init(amount: 100, currency: .eur),
            .init(amount: 0, currency: .usd),
            .init(amount: 0, currency: .jpy)
        ]
    }

    // CurrencyVault
    var inCurrencies: [AmountInCurrency] {
        didSet {
            try? type(of: self).save(currencies: inCurrencies)
        }
    }
}
