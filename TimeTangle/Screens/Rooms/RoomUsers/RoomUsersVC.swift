//
//  RoomUsersVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/2/23.
//

import UIKit
import SwiftUI
import FirebaseFirestore

class RoomUsersVC: UIViewController {
    
    private var room: TTRoom!
    private var ttUsers = [TTUser]()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let usersTableView = UITableView()
    private var usersNotVisible = [String]()
    
    weak var delegate: RoomUpdateDelegate? 
    
    init(room: TTRoom, usersNotVisible: [String]) {
        self.room = room
        self.usersNotVisible = usersNotVisible
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateVCTitle()
        view.backgroundColor = .systemBackground
        configureActivityIndicator()
        configureUsersTableView()
        fetchRoomTTUsers()
    }
    
    //Is this the best place to put this?
    private func fetchRoomTTUsers() {
        activityIndicator.startAnimating()
        FirebaseManager.shared.fetchMultipleUsersDocumentData(with: room.users) { [weak self] result in
            self?.activityIndicator.stopAnimating()
            switch result {
            case .success(let ttUsers):
                self?.ttUsers = ttUsers
            case .failure(let error):
                self?.ttUsers = []
                self?.presentTTAlert(title: "Fetch Error", message: error.rawValue, buttonTitle: "OK")
            }
            DispatchQueue.main.async {
                self?.usersTableView.reloadData()
                self?.updateVCTitle()
            }
        }
    }
    
    private func configureActivityIndicator() {
        activityIndicator.color = .lightGray
        activityIndicator.center = CGPoint(x: usersTableView.bounds.width / 2, y: usersTableView.bounds.height / 2)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false 
        usersTableView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: usersTableView.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: usersTableView.centerXAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 20),
            activityIndicator.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func configureUsersTableView() {
        view.addSubview(usersTableView)
        usersTableView.translatesAutoresizingMaskIntoConstraints = false
        usersTableView.separatorStyle = .none
        usersTableView.delegate = self
        usersTableView.dataSource = self
        usersTableView.register(RoomUserCell.self, forCellReuseIdentifier: RoomUserCell.reuseID)
        
        NSLayoutConstraint.activate([
            usersTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            usersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            usersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            usersTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func sortUsersByAdminAndName() {
        //Need to create a copy to avoid "simultaneous access error" 
        var users = ttUsers
        users.sort(by: {
            self.room.doesContainsAdmin(for: $0.username) && !self.room.doesContainsAdmin(for: $1.username)
        })
        ttUsers = users
    }
    
    private func updateVCTitle() {
        title = "\(ttUsers.count) \(ttUsers.count > 1 ? "Members" : "Member")"
    }
}

extension RoomUsersVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return ttUsers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersTableView.dequeueReusableCell(withIdentifier: RoomUserCell.reuseID) as! RoomUserCell
        let user = ttUsers[indexPath.section]
        cell.set(for: user, usersNotVisible: usersNotVisible, room: room)
        if let previousVC = previousViewController() as? RoomDetailVC {
            cell.delegate = previousVC.self
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 5))
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 7.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 7.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        
        //toggle table view editing
        usersTableView.setEditing(editing, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let username = room.users[indexPath.section]
        var actions = [UIContextualAction]()
        
        let deleteAction = UIContextualAction(style: .normal, title: nil) { [weak self] (contextualAction, view, completion) in
            guard let self = self else { return }
            // Delete something
            removeUser(for: username) { didDeleteUser in
                completion(true)
                if didDeleteUser {
                    DispatchQueue.main.async {
                        let indexSet = IndexSet(arrayLiteral: indexPath.section)
                        tableView.beginUpdates()
                        tableView.deleteSections(indexSet, with: .right)
                        tableView.endUpdates()
                        tableView.reloadData()
                        self.updateVCTitle()
                    }
                }
            }
        }
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 17.0, weight: .bold, scale: .large)
        
        let deleteActionImage = UIImage(systemName: "xmark", withConfiguration: largeConfig)
        deleteAction.image = deleteActionImage?.withTintColor(.white, renderingMode: .alwaysTemplate).addBackgroundCircle(.systemRed)
        deleteAction.backgroundColor = .systemBackground
        
        
        let grantAdminAction = UIContextualAction(style: .normal, title: nil) { [weak self] (contextualAction, view, completion) in
            guard let self = self else { return }
            self.grantUserAdminAccess(for: username) { changeAdmin in
                completion(true)
                if changeAdmin {
                    self.sortUsersByAdminAndName()
                    DispatchQueue.main.async {
                        tableView.reloadData(with: .automatic)
                    }
                }
            }
        }
        
        if room.doesContainsAdmin(for: username) {
            let symbolConfig = UIImage.SymbolConfiguration.preferringMulticolor()
            let grantAdminImage = UIImage(named: "remove.admin.icon")?.applyingSymbolConfiguration(symbolConfig)
            grantAdminAction.image = grantAdminImage?.withRenderingMode(.alwaysOriginal).addBackgroundCircle(.systemPurple)
        } else {
            let symbolConfig = UIImage.SymbolConfiguration.preferringMulticolor()
            let grantAdminImage = UIImage(named: "add.admin.icon")?.applyingSymbolConfiguration(symbolConfig)
            grantAdminAction.image = grantAdminImage?.withRenderingMode(.alwaysOriginal).addBackgroundCircle(.systemPurple)
        }
        
        grantAdminAction.backgroundColor = .systemBackground
        
        if let currentUser = FirebaseManager.shared.currentUser, username != currentUser.username {
            actions.append(deleteAction)
        }
        
        actions.append(grantAdminAction)
        
        let config = UISwipeActionsConfiguration(actions: actions)
        config.performsFirstActionWithFullSwipe = false
        
        return config
    }
    
    private func removeUser(for username: String, completion: @escaping((Bool) -> Void)) {
        let alertController = UIAlertController(title: "Delete User?", message: "Are you sure you want to remove \(username)", preferredStyle: .alert)
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            let newRoomData = [
                TTConstants.roomUsers:
                    FieldValue.arrayRemove([username])
            ]
            
            if let removeIndex = room.users.firstIndex(of: username), let delegate = delegate {
                room.users.remove(at: removeIndex)
                delegate.roomDidUpdate(for: room)
            }
            
            FirebaseManager.shared.updateRoom(for: self.room.code, with: newRoomData) { error in
                guard error == nil else { return }
                completion(true)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: true)
            completion(false)
        }
        
        alertController.addAction(removeAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func grantUserAdminAccess(for username: String, completion: @escaping((Bool) -> Void)) {
        //Show Confirmation Alert
        
        let isUserAdmin = room.doesContainsAdmin(for: username)
        let alertController: UIAlertController!
        
        if !isUserAdmin {
            alertController = UIAlertController(title: "Grant Admin Access?", message: "Do you want to grant access to \(username)", preferredStyle: .alert)
        } else {
            alertController =  UIAlertController(title: "Revoke Admin Access?", message: "Do you want to revoke access to \(username)", preferredStyle: .alert)
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let newRoomData = isUserAdmin ? [
                TTConstants.roomAdmins: FieldValue.arrayRemove([username])
            ] : [
                TTConstants.roomAdmins: FieldValue.arrayUnion([username])
            ]
            
            if isUserAdmin {
                if let removeIndex = room.admins.firstIndex(of: username) {
                    room.admins.remove(at: removeIndex)
                }
                
            } else {
                room.admins.append(username)
            }
            
            //RoomUpdateDelegate to update RoomDetailVC's room
            if let delegate = delegate {
                delegate.roomDidUpdate(for: room)
            }
            
            FirebaseManager.shared.updateRoom(for: self.room.code, with: newRoomData) { error in
                guard error == nil else { return }
                completion(true)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: true)
            completion(false)
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
}
