//
//  CreateGroupUserQueueCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/29/23.
//

import UIKit

class CreateGroupUserQueueCell: ProfileUsernameCell {
    
    private let deleteButton = UIButton(type: .custom)
    private var deleteCompletionHandler: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: CreateGroupUserQueueCell.getReuseID())
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(for user: TTUser, deleteCompletionHandler: @escaping () -> Void) {
        self.deleteCompletionHandler = deleteCompletionHandler
        super.set(for: user)
        
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        if user.username == currentUser.username {
            deleteButton.removeFromSuperview()
        }
    }
    
    static func getReuseID() -> String {
        return "CreateGroupUserQueueCell"
    }
    
    private func configureCell() {
        let deleteButtonWidthAndHeight: CGFloat = 30
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 30)
        let deleteIcon = UIImage(systemName: "xmark.circle.fill", withConfiguration: symbolConfig)
        deleteButton.setImage(deleteIcon, for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(didPressDeleteButton), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            deleteButton.widthAnchor.constraint(equalToConstant: deleteButtonWidthAndHeight),
            deleteButton.heightAnchor.constraint(equalToConstant: deleteButtonWidthAndHeight)
        ])
    }
    
    @objc private func didPressDeleteButton() {
        if let deleteCompletionHandler = deleteCompletionHandler {
            deleteCompletionHandler()
        }
    }
}
