//
//  TTRoomCodeView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/27/23.
//

import UIKit

class TTRoomCodeView: UIView {
    private let roomCodeLabel = TTBodyLabel(textAlignment: .center)
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
        
        roomCodeLabel.font = UIFont.boldSystemFont(ofSize: 50)
        roomCodeLabel.text = codeText
        addSubview(roomCodeLabel)
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            roomCodeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            roomCodeLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            roomCodeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            roomCodeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
        ])
    }
}
