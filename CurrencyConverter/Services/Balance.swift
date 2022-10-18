//
//  CurrencyData.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 14.10.22.
//

import Foundation

protocol Balance {
    var amounts: [Amount] { get set }
}

class BalanceInLocalStorage: Balance {
    
    init() {
        amounts = type(of: self).saved() ?? type(of: self).initial
    }
    
    private static func save(currencies: [Amount]) throws {
        let json = try JSONEncoder().encode(currencies)
        UserDefaults.standard.set(json, forKey: "all")
    }
    
    private static func saved() -> [Amount]? {
        guard let json = UserDefaults.standard.value(forKey: "all") as? Data else {
            return nil
        }
        return try? JSONDecoder().decode([Amount].self, from: json)
    }
    
    private static var initial: [Amount] {
        [
            .init(currency: .eur, amount: 100),
            .init(currency: .usd, amount: 0),
            .init(currency: .jpy, amount: 0)
        ]
    }

    // CurrencyVault
    var amounts: [Amount] {
        didSet {
            try? type(of: self).save(currencies: amounts)
        }
    }
}
