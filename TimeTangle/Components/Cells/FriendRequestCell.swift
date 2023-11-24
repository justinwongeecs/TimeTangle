//
//  FriendRequestCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import UIKit
import FirebaseFirestore

protocol FriendRequestCellDelegate: AnyObject {
    func clickedFriendRequestActionButton(result: Result<Void, TTError>)
}

class FriendRequestCell: UITableViewCell {

    static let reuseID = "FriendRequestCell"
    
    let avatarImageView = TTProfileImageView(widthHeight: TTConstants.profileImageViewInCellHeightAndWidth)
    let idLabel = TTTitleLabel(textAlignment: .left, fontSize: 20)
    let friendRequestTypeLabel = TTBodyLabel(textAlignment: .right)
    
    var buttonsStackView = UIStackView()
    var acceptButton = UIButton(type: .custom)
    var declineButton = UIButton(type: .custom)
    
    var friendRequest: TTFriendRequest?
    weak var delegate: FriendRequestCellDelegate!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
        configureAcceptAndDeclineButtons()
        configureButtonsStackView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let margins = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        contentView.frame = contentView.frame.inset(by: margins)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(for friendRequest: TTFriendRequest) {
        self.friendRequest = friendRequest
    
        friendRequestTypeLabel.text = friendRequest.requestType.description
         
        switch friendRequest.requestType {
        case .outgoing:
            if let recipientUserImageData = friendRequest.recipientProfilePictureData, let image = UIImage(data: recipientUserImageData) {
                avatarImageView.setImage(to: image)
            } else {
                avatarImageView.setToDefaultImage()
            }
            idLabel.text = friendRequest.recipientName
            friendRequestTypeLabel.textColor = .secondaryLabel
            buttonsStackView.isHidden = true
        case .receiving:
            if let senderUserImageData = friendRequest.senderProfilePictureData, let image = UIImage(data: senderUserImageData) {
                avatarImageView.setImage(to: image)
            } else {
                avatarImageView.setToDefaultImage()
            }
            idLabel.text = friendRequest.senderName
            //remove friendReqeustTypeLabel because we will show accept or decline buttons instead
            friendRequestTypeLabel.removeFromSuperview()
        case .accepted:
            friendRequestTypeLabel.textColor = .systemGreen
        case .declined:
            friendRequestTypeLabel.textColor = .systemRed
        }
    }
    
    private func configureCell() {
        addSubview(avatarImageView)
        addSubview(idLabel)
        addSubview(friendRequestTypeLabel)
        
        backgroundColor = TTConstants.defaultCellColor.withAlphaComponent(0.3)
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGreen.cgColor
        selectionStyle = .none
        
        let padding: CGFloat = 12
        
        NSLayoutConstraint.activate([
            avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            avatarImageView.heightAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth),
            avatarImageView.widthAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth),
            
            idLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            idLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 24),
            idLabel.trailingAnchor.constraint(equalTo: friendRequestTypeLabel.leadingAnchor),
            idLabel.heightAnchor.constraint(equalToConstant: 30),
            
            friendRequestTypeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            friendRequestTypeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            friendRequestTypeLabel.leadingAnchor.constraint(equalTo: idLabel.trailingAnchor),
            friendRequestTypeLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func configureAcceptAndDeclineButtons() {
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        
        acceptButton.setImage(UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)), for: .normal)
        acceptButton.tintColor = .systemGreen
        acceptButton.addTarget(self, action: #selector(acceptFriendRequest), for: .touchUpInside)
        
        declineButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)), for: .normal)
        declineButton.tintColor = .systemRed
        declineButton.addTarget(self, action: #selector(declineFriendRequest), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            acceptButton.heightAnchor.constraint(equalToConstant: 40),
            acceptButton.widthAnchor.constraint(equalToConstant: 40),

            declineButton.heightAnchor.constraint(equalToConstant: 40),
            declineButton.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func configureButtonsStackView() {
        //we add buttons to contentView instead of the cell directly because any subviews added to UITableViewCell was behind contentView
        
        contentView.addSubview(buttonsStackView)
        buttonsStackView.addArrangedSubview(acceptButton)
        buttonsStackView.addArrangedSubview(declineButton)
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fillProportionally
        buttonsStackView.alignment = .center
        buttonsStackView.spacing = 10.0
        
        NSLayoutConstraint.activate([
            buttonsStackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            buttonsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            buttonsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            buttonsStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    @objc private func acceptFriendRequest() {
        guard let friendRequest = friendRequest else { return }
        
        //add appropriate friends to both the sender and recipient, remove friend requests from both
        let newRecipientData = [
            TTConstants.friends: FieldValue.arrayUnion([friendRequest.senderName]),
            TTConstants.friendRequests: FieldValue.arrayRemove([friendRequest.dictionary])
        ]
        
        var senderFriendRequestDict = friendRequest
        senderFriendRequestDict.requestType = .outgoing
        
        let newSenderData = [
            TTConstants.friends: FieldValue.arrayUnion([friendRequest.recipientID]),
            TTConstants.friendRequests: FieldValue.arrayRemove([senderFriendRequestDict.dictionary])
        ]
        
        //update friendRequests and friends field for both sender and recipient
        for (id, newData) in [(friendRequest.recipientID, newRecipientData), (friendRequest.senderID, newSenderData)] {
            FirebaseManager.shared.updateUserData(for: id, with: newData) { [weak self] error in
                guard let error = error else {  self?.delegate.clickedFriendRequestActionButton(result: .success(()))
                    return
                }
                //present error
                self?.delegate.clickedFriendRequestActionButton(result: .failure(error))
            }
        }
    }
    
    @objc private func declineFriendRequest() {
        guard let friendRequest = friendRequest else { return }
        
        //delete friend requests from both
        let newRecipientData = [
            TTConstants.friendRequests: FieldValue.arrayRemove([friendRequest.dictionary])
        ]
        
        //update friendRequests field for both sender and recipient
        for id in [friendRequest.senderID, friendRequest.recipientID] {
            FirebaseManager.shared.updateUserData(for: id, with: newRecipientData) { [weak self] error in
                guard let error = error else {
                    self?.delegate.clickedFriendRequestActionButton(result: .success(()))
                    return
                }
                self?.delegate.clickedFriendRequestActionButton(result: .failure(error))
            }
        }
    }
}
