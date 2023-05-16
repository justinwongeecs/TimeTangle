//
//  RoomUserCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/6/23.
//

import UIKit

protocol RoomUserCellDelegate: AnyObject {
    func changedUserVisibility(for username: String)
}

class RoomUserCell: ProfileUsernameCell {
    static let reuseId = "RoomUserCell"
    
    //Eventually save this setting for the session
    private var room: TTRoom!
    private var isUserVisible: Bool = true
    private let visibilityButton = UIButton(type: .custom)
    
    weak var delegate: RoomUserCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func set(for user: TTUser, usersNotVisible: [String], room: TTRoom) {
        super.set(for: user)
        self.room = room
        
        if usersNotVisible.contains(user.username) {
            isUserVisible = false
        } else {
            isUserVisible = true
        }
        
        configureVisibilityButton()
        displayCorrectVisibilityButton()
        configureAdminIndicator()
    }
    
    private func configureVisibilityButton() {
        //Visibility Button
        contentView.addSubview(visibilityButton)
        visibilityButton.tintColor = .systemGreen
        visibilityButton.addTarget(self, action: #selector(toggleVisibility), for: .touchUpInside)
        visibilityButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            visibilityButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            visibilityButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            visibilityButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            visibilityButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func configureAdminIndicator() {
        guard let user = user, room.doesContainsAdmin(for: user.username) else { return }
        //Admin Indicator
        let adminIndicatorView = UIImageView(image: UIImage(systemName: "person.2.badge.gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .medium)))
        adminIndicatorView.tintColor = .systemPurple
        adminIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adminIndicatorView)
        
        NSLayoutConstraint.activate([
            adminIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            adminIndicatorView.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 10)
        ])
    }
    
    private func displayCorrectVisibilityButton() {
        if isUserVisible {
            visibilityButton.tintColor = .systemGreen
            visibilityButton.setImage(UIImage(systemName: "eye"), for: .normal)
        } else {
            visibilityButton.tintColor = .systemRed
            visibilityButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        }
    }
    
    @objc private func toggleVisibility() {
        isUserVisible.toggle()
        displayCorrectVisibilityButton()
        guard let delegate = delegate, let username = user?.username else { return }
        delegate.changedUserVisibility(for: username)
    }
}
