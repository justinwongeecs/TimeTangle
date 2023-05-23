//
//  SettingIconView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/20/23.
//

import UIKit

class SettingIconView: UIView {
    
    private var settingIcon: SettingIcon!
    
    init(settingIcon: SettingIcon) {
        self.settingIcon = settingIcon
        super.init(frame: .zero)
        configureView()
    }
    
    convenience init() {
        self.init(settingIcon: SettingIcon(backgroundColor: .lightGray, foregroundColor: .white, iconName: "xmark"))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSettingIcon(settingIcon: SettingIcon) {
        self.settingIcon = settingIcon
    }
    
    private func configureView() {
        let iconContainerView = UIView()
        iconContainerView.backgroundColor = settingIcon.backgroundColor
        iconContainerView.layer.cornerRadius = 6.0
        iconContainerView.clipsToBounds = true
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconContainerView)
        
        let symbolImageView = UIImageView()
        symbolImageView.tintColor = settingIcon.foregroundColor
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let symbolImage = UIImage(systemName: settingIcon.iconName, withConfiguration: config)
        symbolImageView.image = symbolImage
        iconContainerView.addSubview(symbolImageView)
        
        NSLayoutConstraint.activate([
            iconContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 30),
            iconContainerView.heightAnchor.constraint(equalToConstant: 30),
            
            symbolImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            symbolImageView.heightAnchor.constraint(equalToConstant: 25),
            symbolImageView.widthAnchor.constraint(equalToConstant: 25)
        ])
    }
}


