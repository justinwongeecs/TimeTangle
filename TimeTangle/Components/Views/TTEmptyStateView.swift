//
//  TTEmptyStateView.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import UIKit

class TTEmptyStateView: UIView {
    
    private let messageLabel: TTTitleLabel!
    
    required init(message: String, fontSize: CGFloat = 28) {
        messageLabel = TTTitleLabel(textAlignment: .center, fontSize: fontSize)
        super.init(frame: .zero)
        
        messageLabel.text = message
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        addSubview(messageLabel)
        
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 3
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageLabel.heightAnchor.constraint(equalToConstant: 200),
        ])
    }
}
