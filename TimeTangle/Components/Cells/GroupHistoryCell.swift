//
//  GroupHistoryCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/15/23.
//

import UIKit
import SwiftUI

class GroupHistoryCell: UITableViewCell {
    static let reuseID = "GroupHistoryCell"
    private var groupHistory: TTGroupEdit!
    private var authorUser: TTUser!
    
    private let authorNameLabel = UILabel()
    private let historyDateLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let authorImageView = TTProfileImageView(widthHeight: TTConstants.profileImageViewInCellHeightAndWidth * 1.3)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setCell(for groupHistory: TTGroupEdit, authorUser: TTUser) {
        self.groupHistory = groupHistory
        self.authorUser = authorUser
        
        configureCell()
        
        authorUser.getProfilePictureUIImage { [weak self] image in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let hostingController = UIHostingController(rootView: TTSwiftUIProfileImageView(user: authorUser, image: image, size: TTConstants.profileImageViewInCellHeightAndWidth * 1.3))
                hostingController.view.backgroundColor = .clear
                let profilePictureView = hostingController.view!
                profilePictureView.translatesAutoresizingMaskIntoConstraints = false
                self.authorImageView.subviews.forEach({ $0.removeFromSuperview() })
                self.authorImageView.addSubview(profilePictureView)
                
                NSLayoutConstraint.activate([
                    profilePictureView.topAnchor.constraint(equalTo: self.authorImageView.topAnchor),
                    profilePictureView.leadingAnchor.constraint(equalTo: self.authorImageView.leadingAnchor),
                    profilePictureView.trailingAnchor.constraint(equalTo: self.authorImageView.trailingAnchor),
                    profilePictureView.bottomAnchor.constraint(equalTo: self.authorImageView.bottomAnchor)
                ])
            }
        }
    }
    
    private func configureCell() {
        authorUser.getProfilePictureUIImage { [weak self] image in
            if let image = image {
                self?.authorImageView.setImage(to: image)
            } else {
                self?.authorImageView.setToDefaultImage()
            }
        }
        
        authorImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(authorImageView)
        
        //HeaderStackView with authorNameLabel and historyDateLabel
        let headerStackView = UIStackView()
        headerStackView.axis = .vertical
        headerStackView.distribution = .fill
        headerStackView.spacing = 3
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        authorNameLabel.text = groupHistory.author
        authorNameLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        authorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.addArrangedSubview(authorNameLabel)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/y h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        historyDateLabel.text = dateFormatter.string(from: groupHistory.createdDate)
        historyDateLabel.font = UIFont.systemFont(ofSize: 14)
        historyDateLabel.textColor = .lightGray
        historyDateLabel.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.addArrangedSubview(historyDateLabel)
        
        let vMainContentStackView = UIStackView()
        vMainContentStackView.axis = .vertical
        vMainContentStackView.distribution = .fill
        vMainContentStackView.spacing = 10
        vMainContentStackView.translatesAutoresizingMaskIntoConstraints = false
        vMainContentStackView.addArrangedSubview(headerStackView)
        
        descriptionLabel.textColor = .systemGray
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        vMainContentStackView.addArrangedSubview(descriptionLabel)
        addSubview(vMainContentStackView)
        
        switch groupHistory.editType {
        case .changedStartingDate:
            descriptionLabel.text = "Changed starting time from \(groupHistory.editDifference.before ?? "") to \(groupHistory.editDifference.after ?? "")"
        case .changedEndingDate:
            descriptionLabel.text = "Changed ending time from \(groupHistory.editDifference.before ?? "") to \(groupHistory.editDifference.after ?? "")"
        case .addedUserToGroup:
            descriptionLabel.text = "Added \(groupHistory.editDifference.after ?? "") to group"
        case .removedUserFromGroup:
            descriptionLabel.text = "Removed \(groupHistory.editDifference.after ?? "") from group"
        case .userSynced:
            descriptionLabel.text = "Synced their calendar"
        default:
            descriptionLabel.text = "No Description"
        }
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            vMainContentStackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            vMainContentStackView.leadingAnchor.constraint(equalTo: authorImageView.trailingAnchor, constant: padding),
            vMainContentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            vMainContentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            
            //TODO: - Check to see if these lines are neccessary or not? 
//            authorImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
//            authorImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            authorImageView.widthAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth * 1.3),
            authorImageView.heightAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth * 1.3)
        ])
    }
}

