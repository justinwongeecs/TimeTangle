//
//  JoinRoomVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit

class JoinRoomVC: TTModalCardVC {
    
    let codeTextField = JoinRoomCodeTextField(with: 6)
    
    let padding: CGFloat = 30

    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.text = "Enter Room Code:"
        configureCodeTextField()
    }
    
    private func configureCodeTextField() {
        containerView.addSubview(codeTextField)
        codeTextField.translatesAutoresizingMaskIntoConstraints = false
        codeTextField.becomeFirstResponder()
        
        NSLayoutConstraint.activate([
            codeTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            codeTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            codeTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            codeTextField.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
}
