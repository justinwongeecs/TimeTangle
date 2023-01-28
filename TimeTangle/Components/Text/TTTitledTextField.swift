//
//  TTTitledTextField.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class TTTitledTextField: UIView {
    
    let textFieldLabel = TTTitleLabel(textAlignment: .left, fontSize: 15)
    let textField = TTTextField()
    
    init(textFieldLabelText: String, textFieldPlaceholder: String) {
        super.init(frame: .zero)
        self.textFieldLabel.text = textFieldLabelText
        self.textField.placeholder = textFieldPlaceholder
        self.isUserInteractionEnabled = true 

        backgroundColor = .systemBackground
        configureTextFieldLabel()
        configureTextField()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureTextFieldLabel() {
        addSubview(textFieldLabel)
        
        NSLayoutConstraint.activate([
            textFieldLabel.topAnchor.constraint(equalTo: topAnchor),
            textFieldLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            textFieldLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            textFieldLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func configureTextField() {
        addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: textFieldLabel.bottomAnchor, constant: 5),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
