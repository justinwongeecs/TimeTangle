//
//  GroupUserCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/6/23.
//

import UIKit

protocol GroupUserCellDelegate: AnyObject {
    func groupUserCellDidToggleAdmin(for user: TTUser)
    func groupUserCellDidRemoveUser(for user: TTUser)
    func groupUserCellVisibilityDidChange(for user: TTUser)
}

class GroupUserCell: ProfileAndNameCell {
    static let reuseId = "GroupUserCell"
    
    //Eventually save this setting for the session
    private var group: TTGroup?
    private var user: TTUser?
    private var isUserVisible: Bool = true
    private let adminIndicatorView = UIImageView()
    private let visibilityButton = UIButton(type: .custom)
    private let menuButton = UIButton(type: .custom)
    
    weak var delegate: GroupUserCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureAdminIndicator()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func set(for user: TTUser, usersNotVisible: [String], group: TTGroup) {
        super.set(for: user)
        self.group = group
        self.user = user
        
        if usersNotVisible.contains(user.id) {
            isUserVisible = false
        } else {
            isUserVisible = true
        }
        
        updateAdminIndicator(for: user)
        configureVisibilityButton()
        displayCorrectVisibilityButton()
        
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        if group.admins.contains(currentUser.id) {
            configureMenuButton()
        }
    }
    
    func updateAdminIndicator(for user: TTUser) {
        guard let group = group else { return }
        
        if group.doesContainsAdmin(for: user.id) {
            adminIndicatorView.tintColor = .systemPurple
        } else {
            adminIndicatorView.tintColor = .clear
        }
    }

    private func configureAdminIndicator() {
        adminIndicatorView.image = UIImage(systemName: "person.2.badge.gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
        adminIndicatorView.tintColor = .systemPurple
        adminIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adminIndicatorView)
        
        NSLayoutConstraint.activate([
            adminIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            adminIndicatorView.leadingAnchor.constraint(equalTo: idLabel.trailingAnchor, constant: 10),
            adminIndicatorView.widthAnchor.constraint(equalToConstant: 20),
            adminIndicatorView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    //MARK: - Visibility Button 
    private func configureVisibilityButton() {
        guard let group = group, let currentUser = FirebaseManager.shared.currentUser else { return }
        
        contentView.addSubview(visibilityButton)
        visibilityButton.tintColor = .systemGreen
        visibilityButton.addTarget(self, action: #selector(toggleVisibility), for: .touchUpInside)
        visibilityButton.translatesAutoresizingMaskIntoConstraints = false
        
        if group.doesContainsAdmin(for: currentUser.id) {
            visibilityButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40).isActive = true
        } else {
            visibilityButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        }
        
        NSLayoutConstraint.activate([
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
            delegate.groupUserCellVisibilityDidChange(for: user)
        }
    }
    
    //MARK: - Menu Button
    private func configureMenuButton() {
        guard let group = group, let user = user, let currentUser = FirebaseManager.shared.currentUser else { return }
        
        menuButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        menuButton.tintColor = .systemGreen
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(menuButton)
        
        let menu: UIMenu!
        var uiActions = [UIAction]()
        let symbolConfig = UIImage.SymbolConfiguration(scale: .large)
        
        let grantAdminUIAction = UIAction(title: "Grant Admin", image: UIImage(systemName: "person.crop.circle.badge.checkmark", withConfiguration: symbolConfig)) { [weak self] action in
                guard let user = self?.user else { return }
              
                self?.delegate?.groupUserCellDidToggleAdmin(for: user)
        }
        
        let revokeAdminUIAction = UIAction(title: "Revoke Admin", image: UIImage(systemName: "person.crop.circle.badge.xmark", withConfiguration: symbolConfig), attributes: .destructive) { [weak self] action in
            guard let user = self?.user else { return }
            self?.delegate?.groupUserCellDidToggleAdmin(for: user)
        }
        
        let removeUserUIAction = UIAction(title: "Remove User", image: UIImage(systemName: "person.badge.minus", withConfiguration: symbolConfig), attributes: .destructive) { [weak self] action in
            guard let user = self?.user else { return }
            self?.delegate?.groupUserCellDidRemoveUser(for: user)
        }
        
        if user.id == currentUser.id && group.doesContainsAdmin(for: currentUser.id) {
            uiActions.append(revokeAdminUIAction)
        } else {
            if group.doesContainsAdmin(for: user.id) {
                uiActions.append(contentsOf: [revokeAdminUIAction, removeUserUIAction])
            } else {
                uiActions.append(contentsOf: [grantAdminUIAction, removeUserUIAction])
            }
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
