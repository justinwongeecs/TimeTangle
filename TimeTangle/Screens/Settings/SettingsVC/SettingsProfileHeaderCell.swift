//
//  SettingsProfileHeaderCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/22/23.
//

import UIKit

class SettingsProfileHeaderCell: UITableViewCell {
    
    static let reuseID = "SettingsProfileHeaderCell"
    private let profileImageView = TTProfileImageView(widthHeight: 80)
    private var nameLabel = UILabel()
    private var profileHeaderStackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCell() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        profileImageView.setImageForUser(for: currentUser)
        nameLabel.text = currentUser.getFullName()
    }
    
    private func configureCell() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        backgroundColor = .lightGray.withAlphaComponent(0.35)
        
        selectionStyle = .none
        accessoryType = .disclosureIndicator
    
        profileHeaderStackView.axis = .horizontal
        profileHeaderStackView.alignment = .center
        profileHeaderStackView.distribution = .fillProportionally
        profileHeaderStackView.spacing = 20
        profileHeaderStackView.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderStackView.layer.cornerRadius = 10
        addSubview(profileHeaderStackView)
        
        profileImageView.showBorder = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderStackView.addArrangedSubview(profileImageView)
        
        let userInfoStackView = UIStackView()
        userInfoStackView.alignment = .leading
        userInfoStackView.axis = .vertical
        userInfoStackView.distribution = .fill
        userInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        userInfoStackView.spacing = 5
        profileHeaderStackView.addArrangedSubview(userInfoStackView)
        
        nameLabel.text = "\(currentUser.firstname)\(currentUser.lastname)"
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        userInfoStackView.addArrangedSubview(nameLabel)
        
        let secondaryFont = UIFont.systemFont(ofSize: 13)
        
        let usernameLabel = UILabel()
        usernameLabel.text = currentUser.username
        usernameLabel.font = secondaryFont
        usernameLabel.textColor = .secondaryLabel
        userInfoStackView.addArrangedSubview(usernameLabel)
        
        let subscriptionPlanLabel = UILabel()
        subscriptionPlanLabel.text = "Free Plan"
        subscriptionPlanLabel.font = secondaryFont
        subscriptionPlanLabel.textColor = .secondaryLabel
        userInfoStackView.addArrangedSubview(subscriptionPlanLabel)
        
        NSLayoutConstraint.activate([
            profileHeaderStackView.topAnchor.constraint(equalTo: topAnchor),
            profileHeaderStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            profileHeaderStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            profileHeaderStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
