//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 13.10.22.
//

import UIKit

class ConverterViewController: UIViewController {
    
    @IBOutlet weak var allCurrenciesView: UIStackView!
    @IBOutlet weak var sourceCurrencyView: CurrencyExchangeView!
    @IBOutlet weak var targetCurrencyView: CurrencyExchangeView!
    
    var converter: CurrencyConverter = CurrencyAPIConverter()
    var vault: CurrencyVault = CurrencyLocalStorage()
    
    private var source: AmountInCurrency? {
        didSet {
            sourceCurrencyView.button.setTitle(source?.currency.rawValue, for: .normal)
            sourceCurrencyView.textField.text = source?.amount.description
            if source?.currency == target?.currency {
                target = vault.all.first(where: { $0.currency != source?.currency })
            }
        }
    }
    private var target: AmountInCurrency? {
        didSet {
            targetCurrencyView.button.setTitle(target?.currency.rawValue, for: .normal)
            targetCurrencyView.textField.text = target?.amount.description
            if target?.currency == source?.currency {
                source = vault.all.first(where: { $0.currency != target?.currency })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showAllCurrencies()
        setUpCurrencyExchangeViews()
    }
    
    private func showAllCurrencies() {
        for amountInCurrency in vault.all {
            let label = UILabel()
            label.text = "\(amountInCurrency.amount) \(amountInCurrency.currency.rawValue)"
            allCurrenciesView.addArrangedSubview(label)
        }
    }
    
    private func setUpCurrencyExchangeViews() {
        sourceCurrencyView.textField.delegate = self
        sourceCurrencyView.button.addTarget(self,
                                          action: #selector(didTouchUpInsideSourceCurrency(_:)),
                                          for: .touchUpInside)
        source = vault.all.first
        targetCurrencyView.textField.delegate = self
        targetCurrencyView.button.addTarget(self,
                                          action: #selector(didTouchUpInsideTargetCurrency(_:)),
                                          for: .touchUpInside)
        target = vault.all.last
    }
    
    @objc
    private
    func didTouchUpInsideSourceCurrency(_ button: UIButton) {
        select(for: source) { [weak self] new in
            self?.source = new
        }
    }
    
    @objc
    private
    func didTouchUpInsideTargetCurrency(_ button: UIButton) {
        select(for: target) { [weak self] new in
            self?.target = new
        }
    }
    
    private
    func select(for current: AmountInCurrency?,
                completion: @escaping (AmountInCurrency) -> ()) {
        presentAvailable(from: vault.all.map { $0.currency }, except: current?.currency) { [weak self] selected in
            if let selectedAmountInCurrency = self?.vault.all.first(where: { $0.currency == selected }) {
                completion(selectedAmountInCurrency)
            }
        }
    }
    
    private
    func presentAvailable(from currencies: [Currency], except selected: Currency?, completion: @escaping (Currency) -> ()) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        currencies.filter { $0 != selected }.forEach { currency in
            let action = UIAlertAction(title: currency.rawValue, style: .default) { _ in
                completion(currency)
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private
    func handle(from amount: Double) {
        
    }
    
    private
    func handle(to amount: Double) {
        
    }
    
    @IBAction func didTouchUpInside(_ submitButton: UIButton) {
        guard let sourceCurrency = source?.currency,
              let text = sourceCurrencyView.textField.text,
              let amount = Double(text),
              let targetCurrency = target?.currency else {
                  return
              }
        converter.exchange(from: sourceCurrency.rawValue, amount: amount, to: targetCurrency.rawValue, completion: { [weak self] result in
                switch result {
                case .success(let exchangedAmount):
                    self?.handleExchange(source: sourceCurrency, target: targetCurrency, amount: exchangedAmount)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            })
    }
    
    private func handleExchange(source: Currency, target: Currency, amount: Double) {
        // TODO
    }
}

extension ConverterViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let typed = (textField.text as NSString?)?.replacingCharacters(in: range, with: string),
              let amount = Double(typed) else {
            return false
        }
        if textField === sourceCurrencyView.textField {
            handle(from: amount)
        }
        else if textField === targetCurrencyView.textField {
            handle(to: amount)
        }
        return true
    }
}

