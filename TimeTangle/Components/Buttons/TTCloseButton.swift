//
//  TTCloseButton.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/4/23.
//

import UIKit

//protocol CloseButtonDelegate: AnyObject {
//    func didDismissPresentedView()
//}

class TTCloseButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .bold, scale: .large)), for: .normal)
        tintColor = .lightGray
    }
}
