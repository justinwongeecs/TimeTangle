//
//  RoomUsersVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/2/23.
//

import UIKit
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
        title = ""
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
    
//    private func sortUsersByAdminAndName() {
//        //Need to create a copy to avoid "simultaneous access error"
//        var users = ttUsers
//        users.sort(by: {
//            self.room.doesContainsAdmin(for: $0.username) && !self.room.doesContainsAdmin(for: $1.username)
//        })
//        ttUsers = users
//    }
    
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
        print("\(user.profilePictureData) for \(user.username)")
        cell.set(for: user, usersNotVisible: usersNotVisible, room: room)
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
        return 60.0
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
            let newRoomData = [
                TTConstants.roomUsers:
                    FieldValue.arrayRemove([username])
            ]
            
            if let removeIndex = room.users.firstIndex(of: username), let delegate = delegate {
                room.users.remove(at: removeIndex)
                delegate.roomDidUpdate(for: room)
            }
            
            FirebaseManager.shared.updateRoom(for: self.room.code, with: newRoomData) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.presentTTAlert(title: "Cannot update room", message: error.rawValue, buttonTitle: "OK")
                } else {
                    FirebaseManager.shared.updateUserData(for: username, with: [
                        TTConstants.roomCodes: FieldValue.arrayRemove([self.room.code])
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

//MARK: - RoomUserCellDelegate
extension RoomUsersVC: RoomUserCellDelegate {
    func roomUserCellVisibilityDidChange(for user: TTUser) {
        delegate?.roomUserVisibilityDidUpdate(for: user.username)
    }
    
    func roomUserCellDidToggleAdmin(for user: TTUser) {
        toggleUserAdminAccess(for: user.username) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.usersTableView.reloadData()
            }
        }
    }
    
    func roomUserCellDidRemoveUser(for user: TTUser) {
        removeUser(for: user.username) { [weak self] _ in
            guard let self = self else { return }
            if let ttUsersIndex = self.ttUsers.firstIndex(of: user) {
                self.ttUsers.remove(at: ttUsersIndex)
                DispatchQueue.main.async {
                    self.updateVCTitle()
                    self.usersTableView.reloadData()
                }
            }
        }
    }
}
