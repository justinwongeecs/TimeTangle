//
//  ProfileAndNameCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import UIKit
import SwiftUI

class ProfileAndNameCell: UITableViewCell {
    
    static let reuseID = "AddFriendSearchResultCell"
    
    private var user: TTUser?
    
    private var hStackView = UIStackView()
    internal var avatarImageView = UIView()

    internal let idLabel = TTTitleLabel(textAlignment: .left, fontSize: 15)
    
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
        
        idLabel.text = user.getFullName()
            
        user.getProfilePictureUIImage { [weak self] image in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let hostingController = UIHostingController(rootView: TTSwiftUIProfileImageView(user: user, image: image, size: TTConstants.profileImageViewInCellHeightAndWidth * 1.3))
                hostingController.view.backgroundColor = .clear
                let profilePictureView = hostingController.view!
                profilePictureView.translatesAutoresizingMaskIntoConstraints = false
                self.avatarImageView.subviews.forEach({ $0.removeFromSuperview() })
                self.avatarImageView.addSubview(profilePictureView)
                
                NSLayoutConstraint.activate([
                    profilePictureView.topAnchor.constraint(equalTo: self.avatarImageView.topAnchor),
                    profilePictureView.leadingAnchor.constraint(equalTo: self.avatarImageView.leadingAnchor),
                    profilePictureView.trailingAnchor.constraint(equalTo: self.avatarImageView.trailingAnchor),
                    profilePictureView.bottomAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor)
                ])
            }
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
        
        hStackView.addArrangedSubview(avatarImageView)
        hStackView.addArrangedSubview(idLabel)
        
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
    
    internal func getID() -> String {
        return user?.id ?? ""
    }
}
