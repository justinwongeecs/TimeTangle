//
//  RoomUsersVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/2/23.
//

import UIKit

class RoomUsersVC: UIViewController {
    
    private var users = [TTUser]()
    private let usersTableView = UITableView()
    private var usersNotVisible = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureUsersTableView()
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    func setVC(users: [String], usersNotVisible: [String]) {
        self.usersNotVisible = usersNotVisible
        
        self.users = []
        for username in users {
            FirebaseManager.shared.fetchUserDocumentData(with: username) { [weak self] result in
                switch result {
                case .success(let user):
                    self?.users.append(user)
                    
                case .failure(let error):
                    self?.presentTTAlert(title: "Error fetching users", message: error.rawValue, buttonTitle: "Ok")
                }
            }
        }
        title = "\(users.count) \(users.count > 1 ? "Members" : "Member")"
        DispatchQueue.main.async {
            self.usersTableView.reloadData()
        }
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
        cell.set(for: user)
        if let previousVC = previousViewController() as? RoomInfoVC {
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



