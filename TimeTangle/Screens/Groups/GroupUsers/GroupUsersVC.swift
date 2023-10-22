//
//  GroupUsersVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/2/23.
//

import UIKit
import FirebaseFirestore

class GroupUsersVC: UIViewController {
    
    private var group: TTGroup!
    private var groupUsers: [TTUser]!
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let usersTableView = UITableView()
    private var usersNotVisible = [String]()
    
    weak var delegate: GroupUpdateDelegate? 
    
    init(group: TTGroup, groupUsers: [TTUser], usersNotVisible: [String]) {
        self.group = group
        self.groupUsers = groupUsers
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
        usersTableView.register(GroupUserCell.self, forCellReuseIdentifier: GroupUserCell.reuseID)
        
        NSLayoutConstraint.activate([
            usersTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            usersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            usersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            usersTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func sortUsersByAdminAndName() {
        //Need to create a copy to avoid "simultaneous access error"
        var users = groupUsers
        users?.sort(by: {
            self.group.doesContainsAdmin(for: $0.username) && !self.group.doesContainsAdmin(for: $1.username)
        })
        groupUsers = users
    }
    
    private func updateVCTitle() {
        title = "\(groupUsers.count) \(groupUsers.count > 1 ? "Members" : "Member")"
    }
}

extension GroupUsersVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return groupUsers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersTableView.dequeueReusableCell(withIdentifier: GroupUserCell.reuseID) as! GroupUserCell
        let user = groupUsers[indexPath.section]
        cell.set(for: user, usersNotVisible: usersNotVisible, group: group)
        cell.delegate = self
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
        return TTConstants.defaultCellHeight
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        
        //toggle table view editing
        usersTableView.setEditing(editing, animated: true)
    }
    
    private func removeUser(for username: String, completion: @escaping((Bool) -> Void)) {
        let alertController = UIAlertController(title: "Delete User?", message: "Are you sure you want to remove \(username)", preferredStyle: .alert)
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            let newGroupData = [
                TTConstants.groupUsers:
                    FieldValue.arrayRemove([username])
            ]
            
            if let removeIndex = group.users.firstIndex(of: username), let delegate = delegate {
                group.users.remove(at: removeIndex)
                delegate.groupDidUpdate(for: group)
            }
            
            FirebaseManager.shared.updateGroup(for: self.group.code, with: newGroupData) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.presentTTAlert(title: "Cannot update group", message: error.rawValue, buttonTitle: "OK")
                } else {
                    FirebaseManager.shared.updateUserData(for: username, with: [
                        TTConstants.groupCodes: FieldValue.arrayRemove([self.group.code])
                    ]) { [weak self] error in
                        if let error = error {
                            self?.presentTTAlert(title: "Cannot update user", message: error.rawValue, buttonTitle: "OK")
                        } else {
                            completion(true)
                        }
                    }
                }
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
    
    private func toggleUserAdminAccess(for username: String, completion: @escaping((Bool) -> Void)) {
        //Show Confirmation Alert
        
        let isUserAdmin = group.doesContainsAdmin(for: username)
        let alertController: UIAlertController!
        
        if !isUserAdmin {
            alertController = UIAlertController(title: "Grant Admin Access?", message: "Do you want to grant access to \(username)", preferredStyle: .alert)
        } else {
            alertController =  UIAlertController(title: "Revoke Admin Access?", message: "Do you want to revoke access to \(username)", preferredStyle: .alert)
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let newGroupData = isUserAdmin ? [
                TTConstants.groupAdmins: FieldValue.arrayRemove([username])
            ] : [
                TTConstants.groupAdmins: FieldValue.arrayUnion([username])
            ]
            
            if isUserAdmin {
                if let removeIndex = group.admins.firstIndex(of: username) {
                    group.admins.remove(at: removeIndex)
                }
                
            } else {
                group.admins.append(username)
            }
            
            //GroupUpdateDelegate to update GroupDetailVC's group
            if let delegate = delegate {
                delegate.groupDidUpdate(for: group)
            }
            
            FirebaseManager.shared.updateGroup(for: self.group.code, with: newGroupData) { [weak self] error in
                guard error == nil else { return }
                self?.sortUsersByAdminAndName()
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

//MARK: - GroupUserCellDelegate
extension GroupUsersVC: GroupUserCellDelegate {
    func groupUserCellVisibilityDidChange(for user: TTUser) {
        delegate?.groupUserVisibilityDidUpdate(for: user.username)
    }
    
    func groupUserCellDidToggleAdmin(for user: TTUser) {
        toggleUserAdminAccess(for: user.username) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.usersTableView.reloadData()
            }
        }
    }
    
    func groupUserCellDidRemoveUser(for user: TTUser) {
        removeUser(for: user.username) { [weak self] _ in
            guard let self = self else { return }
            if let groupUsersIndex = self.groupUsers.firstIndex(of: user) {
                self.groupUsers.remove(at: groupUsersIndex)
                DispatchQueue.main.async {
                    self.updateVCTitle()
                    self.usersTableView.reloadData()
                }
            }
        }
    }
}
