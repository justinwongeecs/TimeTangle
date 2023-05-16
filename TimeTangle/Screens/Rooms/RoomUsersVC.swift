//
//  RoomUsersVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/2/23.
//

import UIKit

class RoomUsersVC: UIViewController {
    
    private let room: TTRoom!
    private var users: [TTUser]!
    private let usersTableView = UITableView()
    private var usersNotVisible = [String]()
    
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
        title = "\(room.users.count) \(room.users.count > 1 ? "Members" : "Member")"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = editButtonItem
  
        configureUsersTableView()
        getUsers()
        
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
    
    
    private func getUsers() {
        self.users = []
        for username in room.users {
            FirebaseManager.shared.fetchUserDocumentData(with: username) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let user):
                    self.users.append(user)
                    //Sort by those with admin status 
                    self.users.sort(by: { self.room.doesContainsAdmin(for: $0.username) && !self.room.doesContainsAdmin(for: $1.username)})
                    DispatchQueue.main.async {
                        self.usersTableView.reloadData()
                    }

                case .failure(let error):
                    self.presentTTAlert(title: "Error fetching users", message: error.rawValue, buttonTitle: "Ok")
                }
            }
        }
    }
}

extension RoomUsersVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersTableView.dequeueReusableCell(withIdentifier: RoomUserCell.reuseID) as! RoomUserCell
        let user = users[indexPath.section]
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
    }
}



