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
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(for user: TTUser) {
        self.user = user
        usernameLabel.text = user.username
    
        if let imageData = user.profilePictureData, let image = UIImage(data: imageData) {
            avatarImageView.setImage(to: image)
        } else {
            avatarImageView.setToDefaultImage()
        }
    }
    
    private func configureCell() {
        backgroundColor = .secondarySystemBackground
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
        
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth),
            avatarImageView.heightAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth),
            
            hStackView.topAnchor.constraint(equalTo: topAnchor),
            hStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            hStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    internal func getUsername() -> String {
        return user?.username ?? ""
    }
}
