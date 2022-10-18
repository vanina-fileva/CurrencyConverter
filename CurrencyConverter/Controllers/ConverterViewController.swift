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
    
    var balance: Balance = BalanceInLocalStorage()
    lazy var converter: Converter = APIConverter()
    private var lastConversionRequest: Cancellable?
    lazy var commissionApplier: CommissionApplying = PercentageCommissionApplier()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Currency converter"
        navigationController?.navigationBar.backgroundColor = .systemCyan
        updateBalanceView()
        setUpCurrencyExchangeViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sourceCurrencyView.textField.becomeFirstResponder()
    }
    
    private func updateBalanceView() {
        balanceView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for amountInCurrency in balance.amounts {
            let label = UILabel()
            label.text = "\(amountInCurrency.amount.amountStringValue) \(amountInCurrency.currency.rawValue)"
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
        
        sourceCurrency = balance.amounts[safe: 0]?.currency
        targetCurrency = balance.amounts[safe: 1]?.currency
    }
    
    @objc
    private
    func didTouchUpInsideSourceCurrency(_ button: UIButton) {
        presentAvailable(from: balance.amounts.map { $0.currency }, except: sourceCurrency)
        { [weak self] selected in
            self?.sourceCurrency = selected
            self?.updateTargetTextField()
        }
    }
    
    @objc
    private
    func didTouchUpInsideTargetCurrency(_ button: UIButton) {
        presentAvailable(from: balance.amounts.map { $0.currency }, except: targetCurrency)
        { [weak self] selected in
            self?.targetCurrency = selected
            self?.updateTargetTextField()
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
    
    private func updateTargetTextField() {
        guard let text = sourceCurrencyView.textField.text,
           let sourceAmount = Double(text),
           let sourceCurrencyValue = sourceCurrency?.rawValue,
           let targetCurrencyValue = targetCurrency?.rawValue else {
            return targetCurrencyView.textField.text = "0"
        }
        update(sourceAmount: sourceAmount, sourceCurrency: sourceCurrencyValue,
               targetCurrency: targetCurrencyValue, targetTextField: targetCurrencyView.textField)
    }
    
    private func update(sourceAmount: Double, sourceCurrency: String, targetCurrency: String, targetTextField: UITextField?) {
        DispatchQueue.main.async {
            targetTextField?.text = "..."
        }
        lastConversionRequest?.cancel()
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1)
        { [weak self] in
            self?.lastConversionRequest = self?.converter.convert(
                sourceAmount: sourceAmount,
                sourceCurrency: sourceCurrency,
                targetCurrency: targetCurrency
            ) { result in
                switch result {
                case .success(let targetAmount):
                    DispatchQueue.main.async {
                        targetTextField?.text = targetAmount.amountStringValue
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    @IBAction func didTouchUpInside(_ exchangeButton: UIButton) {
        guard let sourceAmountText = sourceCurrencyView.textField.text,
              let sourceAmount = Double(sourceAmountText), sourceAmount > 0,
              let sourceCurrency = sourceCurrency,
              let availableAmount = balance.amounts.first(where: { $0.currency == sourceCurrency })?.amount,
              sourceAmount <= availableAmount else {
            return presentAlert("Invalid source amount")
        }
        guard let targetAmountText = targetCurrencyView.textField.text,
              let targetAmount = Double(targetAmountText), targetAmount > 0 else {
            return presentAlert("Invalid target amount")
        }
        guard let targetCurrency = targetCurrency else {
            return
        }
        confirmExchange(sourceAmount: sourceAmount, sourceCurrency: sourceCurrency,
                        targetAmount: targetAmount, targetCurrency: targetCurrency)
        { [weak self] in
            guard let self = self else { return }
            let amounts = self.commissionApplier.afterApplication(
                sourceAmount: sourceAmount, sourceCurrency: sourceCurrency.rawValue,
                targetAmount: targetAmount, targetCurrency: targetCurrency.rawValue
            )
            self.updateBalance(sourceAmount: amounts.sourceAmount, sourceCurrency: sourceCurrency,
                                targetAmount: amounts.targetAmount, targetCurrency: targetCurrency)
        }
    }
    
    private func confirmExchange(sourceAmount: Double, sourceCurrency: Currency,
                                 targetAmount: Double, targetCurrency: Currency,
                                 completion: @escaping () -> Void) {
        let commissionDescription = commissionApplier.nextApplicationDescription(
            sourceAmount: sourceAmount, sourceCurrency: sourceCurrency.rawValue,
            targetAmount: targetAmount, targetCurrency: targetCurrency.rawValue
        )
        let message = """
        You will convert \(sourceAmount.amountStringValue) \(sourceCurrency) to \(targetAmount.amountStringValue) \(targetCurrency). Commission Fee - \(commissionDescription).
        """
        let alert = UIAlertController(title: "Currency conversion", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        let exchange = UIAlertAction(title: "Exchange", style: .destructive, handler: { action in
            completion()
        })
        alert.addAction(exchange)
        present(alert, animated: true)
    }
    
    private func presentAlert(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func updateBalance(sourceAmount: Double, sourceCurrency: Currency,
                               targetAmount: Double, targetCurrency: Currency) {
        for i in 0..<balance.amounts.count {
            if balance.amounts[i].currency == sourceCurrency {
                balance.amounts[i].amount -= sourceAmount
            } else if balance.amounts[i].currency == targetCurrency {
                balance.amounts[i].amount += targetAmount
            }
        }
        updateBalanceView()
    }
}

extension ConverterViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let typed = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            return true
        }
        
        if textField === sourceCurrencyView.textField {
            if let amount = Double(typed),
               let sourceCurrency = sourceCurrency?.rawValue,
               let targetCurrency = targetCurrency?.rawValue {
                update(sourceAmount: amount, sourceCurrency: sourceCurrency,
                       targetCurrency: targetCurrency, targetTextField: targetCurrencyView.textField)
            } else {
                targetCurrencyView.textField.text = ""
            }
        }
        else if textField === targetCurrencyView.textField {
            if let amount = Double(typed),
               let sourceCurrencyValue = targetCurrency?.rawValue,
               let targetCurrencyValue = sourceCurrency?.rawValue {
                update(sourceAmount: amount, sourceCurrency: sourceCurrencyValue,
                       targetCurrency: targetCurrencyValue, targetTextField: sourceCurrencyView.textField)
            } else {
                sourceCurrencyView.textField.text = ""
            }
        }
        return true
    }
}

