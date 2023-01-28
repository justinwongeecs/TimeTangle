//
//  TTTextField.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class TTTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        
        layer.cornerRadius = 10
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemGray4.cgColor
        
        //black on light mode and white on dark mode
        textColor = .label
        tintColor = .label
        textAlignment = .center
        font = UIFont.preferredFont(forTextStyle: .title2)
        
        //font will shrink appropriately for long text
        adjustsFontSizeToFitWidth = true
        minimumFontSize = 12
        autocapitalizationType = .none
        
        backgroundColor = .tertiarySystemBackground
        autocorrectionType = .no
        returnKeyType = .go
    }
}
