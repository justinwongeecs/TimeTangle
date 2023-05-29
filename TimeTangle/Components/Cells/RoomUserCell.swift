//
//  RoomUserCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/6/23.
//

import UIKit

protocol RoomUserCellDelegate: AnyObject {
    func roomUserCellDidToggleAdmin(for user: TTUser)
    func roomUserCellDidRemoveUser(for user: TTUser)
    func roomUserCellVisibilityDidChange(for user: TTUser)
}

class RoomUserCell: ProfileUsernameCell {
    static let reuseId = "RoomUserCell"
    
    //Eventually save this setting for the session
    private var room: TTRoom?
    private var user: TTUser?
    private var isUserVisible: Bool = true
    private let adminIndicatorView = UIImageView()
    private let visibilityButton = UIButton(type: .custom)
    private let menuButton = UIButton(type: .custom)
    
    weak var delegate: RoomUserCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureAdminIndicator()
        configureVisibilityButton()
       
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func set(for user: TTUser, usersNotVisible: [String], room: TTRoom) {
        super.set(for: user)
        self.room = room
        self.user = user
        
        if usersNotVisible.contains(user.username) {
            isUserVisible = false
        } else {
            isUserVisible = true
        }
        
        updateAdminIndicator(for: user)
        displayCorrectVisibilityButton()
        
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        print("Room: \(room), current user username: \(currentUser.username)")
        print("room")
        if room.admins.contains(currentUser.username) {
            configureMenuButton()
        }
    }
    
    func updateAdminIndicator(for user: TTUser) {
        guard let room = room else { return }
        
        if room.doesContainsAdmin(for: user.username) {
            adminIndicatorView.tintColor = .systemPurple
        } else {
            adminIndicatorView.tintColor = .clear
        }
    }

    private func configureAdminIndicator() {
        adminIndicatorView.image = UIImage(systemName: "person.2.badge.gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .regular, scale: .medium))
        adminIndicatorView.tintColor = .systemPurple
        adminIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adminIndicatorView)
        
        NSLayoutConstraint.activate([
            adminIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            adminIndicatorView.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 10),
            adminIndicatorView.widthAnchor.constraint(equalToConstant: 20),
            adminIndicatorView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    //MARK: - Visibility Button 
    private func configureVisibilityButton() {
        //Visibility Button
        contentView.addSubview(visibilityButton)
        visibilityButton.tintColor = .systemGreen
        visibilityButton.addTarget(self, action: #selector(toggleVisibility), for: .touchUpInside)
        visibilityButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            visibilityButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            visibilityButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            visibilityButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            visibilityButton.heightAnchor.constraint(equalToConstant: 70)
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
        if let delegate = delegate, let user = user {
            delegate.roomUserCellVisibilityDidChange(for: user)
        }
    }
    
    //MARK: - Menu Button
    private func configureMenuButton() {
        guard let room = room, let user = user, let currentUser = FirebaseManager.shared.currentUser else { return }
        
        menuButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        menuButton.tintColor = .lightGray
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(menuButton)
        
        
        let menu: UIMenu!
        var uiActions = [UIAction]()
        let symbolConfig = UIImage.SymbolConfiguration(scale: .large)
        
        let grantAdminUIAction = UIAction(title: "Grant Admin", image: UIImage(systemName: "person.crop.circle.badge.checkmark", withConfiguration: symbolConfig)) { [weak self] action in
                guard let user = self?.user else { return }
              
                self?.delegate?.roomUserCellDidToggleAdmin(for: user)
        }
        
        let removeAdminUIAction = UIAction(title: "Remove Admin", image: UIImage(systemName: "person.crop.circle.badge.xmark", withConfiguration: symbolConfig)) { [weak self] action in
            guard let user = self?.user else { return }
            self?.delegate?.roomUserCellDidToggleAdmin(for: user)
        }
        
        let removeUserUIAction = UIAction(title: "Remove User", image: UIImage(systemName: "person.badge.minus", withConfiguration: symbolConfig)) { [weak self] action in
            guard let user = self?.user else { return }
            self?.delegate?.roomUserCellDidRemoveUser(for: user)
        }
        
        if user.username == currentUser.username && room.doesContainsAdmin(for: currentUser.username) {
            uiActions.append(removeAdminUIAction)
        } else {
            uiActions.append(contentsOf: [grantAdminUIAction, removeUserUIAction, removeUserUIAction])
        }
        
        menu = UIMenu(title: "", children: uiActions)
      
        menuButton.menu = menu
        menuButton.showsMenuAsPrimaryAction = true
        
        NSLayoutConstraint.activate([
            menuButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            menuButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            menuButton.heightAnchor.constraint(equalToConstant: 20),
            menuButton.widthAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    
}
