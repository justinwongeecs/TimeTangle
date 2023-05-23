//
//  SettingsButtonCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/22/23.
//

import UIKit

class SettingsButtonCell: UITableViewCell {
    
    static let reuseID = "SettingsButtonCell"
    
    private var setting: Setting? = nil
    private let button = UIButton(type: .custom)
    
    func setCell(with setting: Setting) {
        self.setting = setting
        configureCell()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureCell() {
        guard let setting = setting else { return }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(setting.title, for: .normal)
        button.contentHorizontalAlignment = .left 
        
        if let titleColor = setting.titleColor {
            button.setTitleColor(titleColor, for: .normal)
        }
        
        button.addTarget(self, action: #selector(onButtonClicked), for: .touchUpInside)
        contentView.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func onButtonClicked() {
        guard let setting = setting, let actionClosure = setting.actionClosure else { return }
        actionClosure()
    }
}
