//
//  ProfileUsernameCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import UIKit

class ProfileUsernameCell: UITableViewCell {
    
    static let reuseID = "AddFriendSearchResultCell"
    
    private var user: TTUser?
    
    private var hStackView = UIStackView()
    internal var avatarImageView = TTProfileImageView(widthHeight: TTConstants.profileImageViewInCellHeightAndWidth)
    internal let usernameLabel = TTTitleLabel(textAlignment: .left, fontSize: 15)
    
    private var hStackViewLeadingConstraint: NSLayoutConstraint!
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        update()
    }
    
    func set(for user: TTUser, backgroundColor: UIColor? = .systemGreen) {
        self.user = user
        self.backgroundColor = backgroundColor?.withAlphaComponent(0.3)
        self.layer.borderColor = backgroundColor?.cgColor
        self.layer.borderWidth = 1
        
        usernameLabel.text = user.getFullName()
    
        if let imageData = user.profilePictureData, let image = UIImage(data: imageData) {
            avatarImageView.setImage(to: image)
        } else {
            avatarImageView.setToDefaultImage()
        }
    }
    
    private func configureCell() {
        layer.cornerRadius = 10
        selectionStyle = .none
        clipsToBounds = true
        
        hStackView.axis = .horizontal
        hStackView.alignment = .center
        hStackView.distribution = .fillProportionally
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        hStackView.spacing = 10
        addSubview(hStackView)
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        hStackView.addArrangedSubview(avatarImageView)
        hStackView.addArrangedSubview(usernameLabel)
        
        hStackViewLeadingConstraint = hStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10)
        hStackViewLeadingConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth),
            avatarImageView.heightAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth),
            
            hStackView.topAnchor.constraint(equalTo: topAnchor),
            hStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            hStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func update() {
        if self.isEditing {
            self.hStackViewLeadingConstraint.isActive = false
            self.hStackViewLeadingConstraint = self.hStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 60)
            self.hStackViewLeadingConstraint.isActive = true
        } else {
            self.hStackViewLeadingConstraint.isActive = false
            self.hStackViewLeadingConstraint = self.hStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
            self.hStackViewLeadingConstraint.isActive = true
        }
    }
    
    internal func getUsername() -> String {
        return user?.username ?? ""
    }
}
