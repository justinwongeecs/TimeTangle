//
//  TTGroupCodeView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/27/23.
//

import UIKit

class TTGroupCodeView: UIView {
    private let groupCodeLabel = TTBodyLabel(textAlignment: .center)
    private let codeText: String!
    
    required init(codeText: String) {
        self.codeText = codeText
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemGray5
        layer.masksToBounds = true
        layer.cornerRadius = 16
        
        groupCodeLabel.font = UIFont.boldSystemFont(ofSize: 50)
        groupCodeLabel.text = codeText
        addSubview(groupCodeLabel)
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            groupCodeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            groupCodeLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            groupCodeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            groupCodeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
        ])
    }
}
