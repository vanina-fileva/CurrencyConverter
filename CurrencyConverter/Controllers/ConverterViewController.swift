//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 13.10.22.
//

import UIKit

class ConverterViewController: UIViewController {
    
    @IBOutlet weak var balanceView: UIStackView!
    @IBOutlet weak var sourceCurrencyView: CurrencyExchangeView!
    @IBOutlet weak var targetCurrencyView: CurrencyExchangeView!
    @IBOutlet weak var submitButton: UIButton!
    
    var converter: CurrencyConverter = CurrencyAPIConverter()
    var balance: CurrencyBalance = CurrencyBalanceLocalStorage()
    
    private var sourceCurrency: Currency? {
        didSet {
            sourceCurrencyView.button.setTitle(sourceCurrency?.rawValue, for: .normal)
            if sourceCurrency == targetCurrency {
                targetCurrency = oldValue
            }
        }
    }
    private var targetCurrency: Currency? {
        didSet {
            targetCurrencyView.button.setTitle(targetCurrency?.rawValue, for: .normal)
            if targetCurrency == sourceCurrency {
                sourceCurrency = oldValue
            }
        }
    }
    
    private var commission: Double {
        let percentage = 0.7
        guard let value = sourceCurrencyView.textField.text?.toDouble() else { return 0}
        let newValue = (percentage / 100) * value
        return newValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateBalance()
        setUpCurrencyExchangeViews()
        navigationItem.title = "Currency converter"
        self.navigationController?.navigationBar.backgroundColor = .blue
        submitButton.buttonCorner()
        sourceCurrencyView.textField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged);
    }
    
    private func updateBalance() {
        balanceView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for amountInCurrency in balance.inCurrencies {
            let label = UILabel()
            label.text = "\(amountInCurrency.amount.amountStringValue ?? "NA") \(amountInCurrency.currency.rawValue)"
            balanceView.addArrangedSubview(label)
        }
    }
    
    private func setUpCurrencyExchangeViews() {
        sourceCurrencyView.textField.delegate = self
        sourceCurrencyView.button.addTarget(
            self,
            action: #selector(didTouchUpInsideSourceCurrency(_:)),
            for: .touchUpInside
        )
        targetCurrencyView.textField.delegate = self
        targetCurrencyView.button.addTarget(
            self,
            action: #selector(didTouchUpInsideTargetCurrency(_:)),
            for: .touchUpInside
        )
        
        sourceCurrency = balance.inCurrencies[safe: 0]?.currency
        targetCurrency = balance.inCurrencies[safe: 1]?.currency
    }
    
    @objc
    private
    func didTouchUpInsideSourceCurrency(_ button: UIButton) {
        presentAvailable(from: balance.inCurrencies.map { $0.currency }, except: sourceCurrency)
        { [weak self] selected in
            self?.sourceCurrency = selected
            if let text = self?.sourceCurrencyView.textField.text,
               let sourceAmount = Double(text) {
                self?.from(sourceAmount: sourceAmount, updateTarget: self?.targetCurrencyView.textField)
            }
        }
    }
    
    @objc
    private
    func didTouchUpInsideTargetCurrency(_ button: UIButton) {
        presentAvailable(from: balance.inCurrencies.map { $0.currency }, except: targetCurrency)
        { [weak self] selected in
            self?.targetCurrency = selected
            if let text = self?.targetCurrencyView.textField.text,
               let sourceAmount = Double(text) {
                self?.from(sourceAmount: sourceAmount, updateTarget: self?.sourceCurrencyView.textField)
            }
        }
    }
    
    @objc
    private
    func textFieldChanged(_ textField: UITextField) {
        if let text = sourceCurrencyView.textField.text, text.isEmpty {
            targetCurrencyView.textField.text = ""
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
    
    private static func present(amount: Double, on textField: UITextField?) {
        guard let textField = textField else {
            return
        }
        DispatchQueue.main.async {
            textField.text = amount.amountStringValue
        }
    }
    
    private func from(sourceAmount: Double, updateTarget textField: UITextField?) {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1)
        { [weak self] in
            self?.exchange(sourceAmount: sourceAmount,
                           sourceCurrency: self?.sourceCurrency,
                           targetCurrency: self?.targetCurrency)
            { result in
                switch result {
                case .success(let targetAmount):
                    ConverterViewController.present(amount: targetAmount, on: textField)
                case .failure(let error):
                    // TODO: Handle echange errors
                    print(error)
                }
            }
        }
    }
    
    @IBAction func didTouchUpInside(_ updateBalanceButton: UIButton) {
        exchangeFromBalance()
        showAlertMessage()
    }
    
    private func exchange(sourceAmount: Double,
                          sourceCurrency: Currency?,
                          targetCurrency: Currency?,
                          completion: @escaping (Result<Double, Error>) -> ()) {
        guard let sourceCurrencyString = sourceCurrency?.rawValue,
        let targetCurrencyString = targetCurrency?.rawValue else {
            return
        }

        converter.exchange(sourceAmount: sourceAmount,
                           sourceCurrency: sourceCurrencyString,
                           targetCurrency: targetCurrencyString)
        { result in
            switch result {
            case .success(let targetAmount):
                completion(.success(targetAmount))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func exchangeFromBalance() {
        guard let sourceCurrency = sourceCurrency,
            let sourceAmountText = sourceCurrencyView.textField.text,
            let sourceAmount = Double(sourceAmountText),
            let targetCurrency = targetCurrency,
            let targetAmountText = targetCurrencyView.textField.text,
            let targetAmount = Double(targetAmountText) else {
            return
        }
        for i in 0..<balance.inCurrencies.count {
            if balance.inCurrencies[i].currency == sourceCurrency {
                balance.inCurrencies[i].amount -= sourceAmount
            } else if balance.inCurrencies[i].currency == targetCurrency {
                balance.inCurrencies[i].amount += targetAmount
            }
        }
        updateBalance()
    }
    
    func showAlertMessage() {
        let alert = UIAlertController(title: "Currency converted", message: "You have converted \(String(describing: sourceCurrencyView.textField.text ?? "")) \(String(describing: sourceCurrency?.rawValue ?? "")) to \(String(describing: targetCurrencyView.textField.text ?? "")) \(String(describing: targetCurrency?.rawValue ?? "")). Commission Fee - \(String(describing: commission.amountStringValue ?? "")) \(String(describing: sourceCurrency?.rawValue ?? "")).", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default))
        present(alert, animated: true)
    }
}

extension ConverterViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let typed = (textField.text as NSString?)?.replacingCharacters(in: range, with: string),
           let amount = Double(typed) else {
            return true
        }
        
        let isNumeric = typed.isEmpty || (Double(typed) != nil)
        let numberOfDots = typed.components(separatedBy: ".").count - 1
    
        let numberOfDecimalDigits: Int
    if let dotIndex = typed.firstIndex(of: ".") {
            numberOfDecimalDigits = typed.distance(from: dotIndex, to: typed.endIndex) - 1
        } else {
            numberOfDecimalDigits = 0
        }
        
        if textField === sourceCurrencyView.textField {
            from(sourceAmount: amount, updateTarget: targetCurrencyView.textField)
        }
        else if textField === targetCurrencyView.textField {
            from(sourceAmount: amount, updateTarget: sourceCurrencyView.textField)
        }
        return isNumeric && numberOfDots <= 1 && numberOfDecimalDigits <= 2
    }
}

