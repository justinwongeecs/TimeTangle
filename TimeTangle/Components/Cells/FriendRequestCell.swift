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
    
    let avatarImageView = TTAvatarImageView(frame: .zero)
    let usernameLabel = TTTitleLabel(textAlignment: .left, fontSize: 20)
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
        print("Set friendRequest: \(friendRequest)")
        self.friendRequest = friendRequest
        
        friendRequestTypeLabel.text = friendRequest.requestType.description
         
        switch friendRequest.requestType {
        case .outgoing:
            usernameLabel.text = friendRequest.recipientUsername
            friendRequestTypeLabel.textColor = .secondaryLabel
            buttonsStackView.isHidden = true
        case .receiving:
            usernameLabel.text = friendRequest.senderUsername
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
        addSubview(usernameLabel)
        addSubview(friendRequestTypeLabel)
        
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        selectionStyle = .none 
        
        let padding: CGFloat = 12
        
        NSLayoutConstraint.activate([
            avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
            
            usernameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 24),
            usernameLabel.trailingAnchor.constraint(equalTo: friendRequestTypeLabel.leadingAnchor),
            usernameLabel.heightAnchor.constraint(equalToConstant: 30),
            
            friendRequestTypeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            friendRequestTypeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            friendRequestTypeLabel.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor),
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
            acceptButton.heightAnchor.constraint(equalToConstant: 30),
            acceptButton.widthAnchor.constraint(equalToConstant: 30),

            declineButton.heightAnchor.constraint(equalToConstant: 30),
            declineButton.widthAnchor.constraint(equalToConstant: 30)
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
            TTConstants.friends: FieldValue.arrayUnion([friendRequest.senderUsername]),
            TTConstants.friendRequests: FieldValue.arrayRemove([friendRequest.dictionary])
        ]
        
        var senderFriendRequestDict = friendRequest
        senderFriendRequestDict.requestType = .outgoing
        print(senderFriendRequestDict)
        
        let newSenderData = [
            TTConstants.friends: FieldValue.arrayUnion([friendRequest.recipientUsername]),
            TTConstants.friendRequests: FieldValue.arrayRemove([senderFriendRequestDict.dictionary])
        ]
        
        //update friendRequests and friends field for both sender and recipient
        for (username, newData) in [(friendRequest.recipientUsername, newRecipientData), (friendRequest.senderUsername, newSenderData)] {
            FirebaseManager.shared.updateUserData(for: username, with: newData) { [weak self] error in
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
        for username in [friendRequest.senderUsername, friendRequest.recipientUsername] {
            FirebaseManager.shared.updateUserData(for: username, with: newRecipientData) { [weak self] error in
                guard let error = error else {
                    self?.delegate.clickedFriendRequestActionButton(result: .success(()))
                    return
                }
                self?.delegate.clickedFriendRequestActionButton(result: .failure(error))
            }
        }
    }
}
