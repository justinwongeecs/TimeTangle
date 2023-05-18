//
//  ProfileUsernameCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import UIKit

class ProfileUsernameCell: UITableViewCell {
    
    static let reuseID = "AddFriendSearchResultCell"
    
    private var username: String = ""
    internal let avatarImageView = UIImageView()
    internal let usernameLabel = TTTitleLabel(textAlignment: .left, fontSize: 15)
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(for username: String) {
        self.username = username
        usernameLabel.text = username
    }
    
    private func configureCell() {
        addSubview(avatarImageView)
        addSubview(usernameLabel)
        
        let avatarImage = UIImage(systemName: "person.crop.circle")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        avatarImageView.image = avatarImage
        avatarImageView.image?.withTintColor(.secondaryLabel)
        avatarImageView.frame = CGRect(x: 10, y: 10, width: 40, height: 40)
        
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        selectionStyle = .none
        clipsToBounds = true 
        
        NSLayoutConstraint.activate([
            avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            usernameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            usernameLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
    
    internal func getUsername() -> String {
        return username 
    }
}
