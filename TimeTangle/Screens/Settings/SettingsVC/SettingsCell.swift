//
//  SettingsCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/20/23.
//

import UIKit

class SettingsCell: UITableViewCell {
    static let reuseID = "SettingsCell"
    
    private var settingIconView: SettingIconView? = nil
    private var titleLabel = UILabel()
    private var setting: Setting?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setCell(for setting: Setting) {
        self.setting = setting
        configureCell()
    }
    
    private func configureCell() {
        guard let setting = setting else { return }
        
        settingIconView?.removeFromSuperview()
        titleLabel.removeFromSuperview()
        
        selectionStyle = .none
        accessoryType = getAccessoryType()
        
        if let settingIcon = setting.icon {
            settingIconView = SettingIconView(settingIcon: settingIcon)
            
            guard let settingIconView = settingIconView else { return }
            
            settingIconView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(settingIconView)
            
            NSLayoutConstraint.activate([
                settingIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
                settingIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                settingIconView.heightAnchor.constraint(equalToConstant: 30),
                settingIconView.widthAnchor.constraint(equalToConstant: 30)
            ])
        }
 
        titleLabel.textAlignment = .left
        titleLabel.text = setting.title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: settingIconView == nil ? leadingAnchor : settingIconView!.trailingAnchor, constant: 10),
            titleLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func getAccessoryType() -> UITableViewCell.AccessoryType {
        guard let setting = setting else { return .none }
        
        switch setting.actionType {
        case .disclosure:
            return .disclosureIndicator
        default:
            return .none
        }
    }
}

