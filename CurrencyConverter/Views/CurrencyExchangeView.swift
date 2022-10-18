//
//  CurrencyExchangeView.swift
//  CurrencyConverter
//
//  Created by Vanina Fileva on 15.10.22.
//

import UIKit

class XibView: UIView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromNib()
    }
    
    func loadFromNib() {
        let name = String(describing: CurrencyExchangeView.self)
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: name, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }
        view.frame = self.bounds
        addSubview(view)
    }
}

@IBDesignable
class CurrencyExchangeView: XibView {
    @IBOutlet weak var imageView: UIImageView!
    @IBInspectable
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var button: UIButton!
}
