//
//  FriendCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 10/15/23.
//

import UIKit
import MessageUI
import FirebaseFirestore

class FriendCell: ProfileUsernameCell {
    static let friendCellReuseID = "FriendCell"
    
    private var friend: TTUser?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func set(for user: TTUser, backgroundColor: UIColor? = TTConstants.defaultCellColor) {
        super.set(for: user, backgroundColor: backgroundColor)
        self.friend = user
        configureCell()
    }
    
    private func configureCell() {
        guard let friend = friend else { return }
        
        var moreButtonActions = [UIAction]()
        
        if MFMailComposeViewController.canSendMail() && friend.email != "" {
            moreButtonActions.append(UIAction(title: "Email \(friend.firstname)", image: UIImage(systemName: "envelope")) { _ in
                self.emailFriend()
            })
        }
        
        if friend.phoneNumber != "" {
            moreButtonActions.append(UIAction(title: "Call \(friend.firstname)", image: UIImage(systemName: "phone")) { _ in
                self.callFriend()
            })
        }
        
        if MFMessageComposeViewController.canSendText() && friend.phoneNumber != "" {
            moreButtonActions.append(UIAction(title: "Message \(friend.firstname)", image: UIImage(systemName: "message")) { action in
                self.messageFriend()
            })
        }
                
        moreButtonActions.insert(UIAction(title: "Remove \(friend.firstname)", image: UIImage(systemName: "person.crop.circle.badge.xmark"), attributes: .destructive) { _ in
            self.removeFriend()
        }, at: moreButtonActions.count)
    
        let moreButton = UIButton(type: .custom)
        moreButton.setImage(UIImage(systemName: "ellipsis.circle.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large)), for: .normal)
        moreButton.tintColor = .systemGreen.withAlphaComponent(0.8)
        moreButton.menu = UIMenu(children: moreButtonActions)
        moreButton.showsMenuAsPrimaryAction = true
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(moreButton)
        
        NSLayoutConstraint.activate([
            moreButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            moreButton.widthAnchor.constraint(equalToConstant: 30),
            moreButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func removeFriend() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
            TTConstants.friends: FieldValue.arrayRemove([friend!.username])
        ]) { [weak self] error in
            if let error = error, let parentVC = self?.parentViewController as? FriendsAndRequestsVC {
                parentVC.presentTTAlert(title: "Cannot Remove Friend", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    private func callFriend() {
        guard let friend = friend else { return }
        if let url = URL(string: "tel://\(friend.phoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func messageFriend() {
        guard let friend = friend else { return }
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        messageComposeVC.recipients = [friend.phoneNumber]
        messageComposeVC.body = "Hi \(friend.firstname) 👋!"
        
        if let parentVC = parentViewController as? FriendsAndRequestsVC {
            parentVC.present(messageComposeVC, animated: true)
        }
    }
    
    private func emailFriend() {
        guard let friend = friend else { return }
        let emailComposeVC = MFMailComposeViewController()
        emailComposeVC.mailComposeDelegate = self
        emailComposeVC.setToRecipients([friend.email])
        emailComposeVC.setSubject("Hello 👋!")
        
        if parentViewController is FriendsAndRequestsVC {
            emailComposeVC.present(emailComposeVC, animated: true)
        }
    }
}

extension FriendCell: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

extension FriendCell: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

