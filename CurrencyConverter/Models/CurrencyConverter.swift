//
//  CurrencyManager.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 13.10.22.
//

import Foundation

protocol CurrencyConverter {
    func exchange(sourceAmount: Double, sourceCurrency: String, targetCurrency: String,
                  completion: @escaping (Result<Double, Error>) -> ())
}

class CurrencyAPIConverter: CurrencyConverter {
    
    func exchange(sourceAmount: Double, sourceCurrency: String, targetCurrency: String,
                  completion: @escaping (Result<Double, Error>) -> ()) {
        let urlString = "http://api.evp.lt/currency/commercial/exchange/\(sourceAmount)-\(sourceCurrency)/\(targetCurrency)/latest"
        guard let endpoint = URL(string: urlString) else {
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: endpoint))
        { data, response, error in
            if let error = error {
                return completion(.failure(error))
            }
            if let data = data,
                let json = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any],
               let text = json["amount"] as? String, let exchanged = Double(text) {
                return completion(.success(exchanged))
            }
            return completion(.failure(URLError(.cannotLoadFromNetwork)))
        }
        task.resume()
    }
}
