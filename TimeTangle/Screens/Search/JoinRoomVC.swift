//
//  JoinRoomVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit

class JoinRoomVC: TTModalCardVC {
    
    private let containerViewHeader = UIStackView()
    private let codeTextField = JoinRoomCodeTextField(with: 6)
    private var headerLabel = TTTitleLabel(textAlignment: .center, fontSize: 18)
    
    private let padding: CGFloat = 30
    
    override init(closeButtonClosure: @escaping () -> Void) {
        super.init(closeButtonClosure: closeButtonClosure)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.text = "Enter Room Code:"
        configureContainerViewHeader()
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
    
    private func configureContainerViewHeader() {
        containerView.addSubview(containerViewHeader)
        containerViewHeader.translatesAutoresizingMaskIntoConstraints = false
        containerViewHeader.layer.cornerRadius = 16
        containerViewHeader.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerViewHeader.backgroundColor = .systemBackground
        containerViewHeader.axis = .horizontal
    
        headerLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        let closeButton = TTCloseButton()
        closeButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        
        containerViewHeader.addArrangedSubview(headerLabel)
        containerViewHeader.addArrangedSubview(closeButton)
        
        NSLayoutConstraint.activate([
            containerViewHeader.topAnchor.constraint(equalTo: containerView.topAnchor),
            containerViewHeader.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            containerViewHeader.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            containerViewHeader.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
