//
//  SettingsProfileHeaderCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/22/23.
//

import UIKit

class SettingsProfileHeaderCell: UITableViewCell {
    
    static let reuseID = "SettingsProfileHeaderCell"
    private var profileHeaderStackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureCell() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        selectionStyle = .none
        accessoryType = .disclosureIndicator
    
        profileHeaderStackView.axis = .horizontal
        profileHeaderStackView.alignment = .center
        profileHeaderStackView.distribution = .fillProportionally
        profileHeaderStackView.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderStackView.backgroundColor = .lightGray.withAlphaComponent(0.35)
        profileHeaderStackView.layer.cornerRadius = 10.0
        addSubview(profileHeaderStackView)
        
        let profileImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 50)
        let profileImage = UIImage(systemName: "person.crop.circle", withConfiguration: config)
        profileImageView.tintColor = .white
        profileImageView.image = profileImage
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderStackView.addArrangedSubview(profileImageView)
        
        let userInfoStackView = UIStackView()
        userInfoStackView.alignment = .leading
        userInfoStackView.axis = .vertical
        userInfoStackView.distribution = .fill
        userInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderStackView.addArrangedSubview(userInfoStackView)
        
        let nameLabel = UILabel()
        nameLabel.text = currentUser.firstname + " " + currentUser.lastname
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
            profileHeaderStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            profileHeaderStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            profileHeaderStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
