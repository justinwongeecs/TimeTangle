//
//  TTActivityIndicatorView.swift
//  TimeTangle
//
//  Created by Justin Wong on 6/2/23.
//

import UIKit

class TTActivityIndicatorView: UIActivityIndicatorView {
    
    private let containerView: UIView!
    
    required init(containerView: UIView) {
        self.containerView = containerView
        super.init(frame: .zero)
        configure()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        style = .medium
        color = .lightGray
        center = CGPoint(x: containerView.bounds.width / 2, y: bounds.height / 2)
        hidesWhenStopped = true
        translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(self)
        
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            widthAnchor.constraint(equalToConstant: 20),
            heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
