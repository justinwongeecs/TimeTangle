//
//  UserQueueForRoomCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/25/22.
//

import UIKit

protocol UserQueueForRoomCellDelegate: AnyObject {
    func didTapDeleteCell(_ tableViewCell: UserQueueForRoomCell, for username: String)
}

class UserQueueForRoomCell: UITableViewCell {
    
    static let reuseID = "UserQueueForRoomCell"
    
    let avatarImageView = TTAvatarImageView(frame: .zero)
    let usernameLabel = TTTitleLabel(textAlignment: .left, fontSize: 20)
    let deleteButton = TTButton(frame: .zero)
    
    weak var delegate: UserQueueForRoomCellDelegate!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        configureDeleteButton()
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCell(for user: TTUser) {
        print("set cell")
        usernameLabel.text = user.username
    }
    
    private func configureCell() {
        addSubview(avatarImageView)
        addSubview(usernameLabel)
        addSubview(deleteButton)
        
        selectionStyle = . none
        
        let padding: CGFloat = 12 
        
        NSLayoutConstraint.activate([
            avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
            
            usernameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 24),
            usernameLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor),
            usernameLabel.heightAnchor.constraint(equalToConstant: 30),
            
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            deleteButton.heightAnchor.constraint(equalToConstant: 30),
            deleteButton.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func configureDeleteButton() {
        deleteButton.layer.cornerRadius = 15
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 30), forImageIn: .normal)
        
        deleteButton.addTarget(self, action: #selector(deleteCell), for: .touchUpInside)
    }
    
    @objc private func deleteCell() {
        print("delete cell")
        self.delegate.didTapDeleteCell(self, for: usernameLabel.text!)
    }
}
