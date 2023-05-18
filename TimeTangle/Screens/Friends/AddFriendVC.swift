//
//  AddFriendVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import UIKit

protocol AddFriendVCDelegate: AnyObject {
    func selectedUserToAddFriend(for user: TTUser)
}

class AddFriendVC: UIViewController {
    
    var friendSearchResults: [TTUser] = []
    
    let searchTextField = TTTextField()
    let friendSearchResultsTable = UITableView()
    
    weak var delegate: AddFriendVCDelegate!
    var friendsAndRequestsVCRef: FriendsAndRequestsVC?


    override func viewDidLoad() {
        super.viewDidLoad()
        configureVC()
        configureSearchTextField()
        configureFriendResultsTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //check to see if friendSearchResults is empty, if so display empty view
        if friendSearchResults.isEmpty {
            self.showEmptyStateView(with: "No Search Results", in: self.view)
            //search field will be covered by the empty state view so we need to bring it forwards
            view.bringSubviewToFront(searchTextField)
        }
    }
    
    private func configureVC() {
        view.backgroundColor = .systemBackground
        title = "Add Friend"
        
        let backButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissModal))
        backButton.tintColor = .systemGreen
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func dismissModal() {
        dismiss(animated: true)
    }
    
    private func configureSearchTextField() {
        view.addSubview(searchTextField)
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.placeholder = "Enter a username"
        searchTextField.autocorrectionType = .no
        searchTextField.delegate = self
        
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            searchTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureFriendResultsTable() {
        view.addSubview(friendSearchResultsTable)
        friendSearchResultsTable.translatesAutoresizingMaskIntoConstraints = false
        friendSearchResultsTable.separatorStyle = .none
        friendSearchResultsTable.dataSource = self
        friendSearchResultsTable.delegate = self
        
        friendSearchResultsTable.register(ProfileUsernameCell.self, forCellReuseIdentifier: ProfileUsernameCell.reuseID)
        
        NSLayoutConstraint.activate([
            friendSearchResultsTable.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 10),
            friendSearchResultsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            friendSearchResultsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            friendSearchResultsTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func updateTableData() {
        if friendSearchResults.isEmpty {
            removeEmptyStateView()
            //display empty state view instead
            showEmptyStateView(with: "No Search Results", in: self.view)
        } else {
            //remove empty state view
            removeEmptyStateView()
            view.bringSubviewToFront(friendSearchResultsTable)
        }
        
        DispatchQueue.main.async {
            self.friendSearchResultsTable.reloadData()
        }
    }
    
    private func removeEmptyStateView() {
        if let viewWithTag = view.viewWithTag(TTConstants.emptyStateViewTag) {
            viewWithTag.removeFromSuperview()
        }
    }
}

//MARK: - Delegates
extension AddFriendVC: UITextFieldDelegate {
    //when user presses enter
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //remove empty state view if there is one and search is successful
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        showLoadingView()
        guard let filter = searchTextField.text, !filter.isEmpty else {
            friendSearchResults = []
            updateTableData()
            dismissLoadingView()
            return
        }
        
        guard let currentUser = FirebaseManager.shared.currentUser, let friendsAndRequestsVCRef = friendsAndRequestsVCRef else { return }
        
        FirebaseManager.shared.fetchUsers { [unowned self] result in
            switch result {
            case .success(let allUsers):
                var usersToBeRemoved: [String] = []
                usersToBeRemoved.append(contentsOf: friendsAndRequestsVCRef.friends.map{ $0 })
                usersToBeRemoved.append(contentsOf: friendsAndRequestsVCRef.friendRequests.map{$0.recipientUsername})
                usersToBeRemoved.append(currentUser.username)
                
                let allUsersWithoutFriendsAndFriendRequestsAndCurrentUser = allUsers.filter { !usersToBeRemoved.contains($0.username) }
                friendSearchResults = allUsersWithoutFriendsAndFriendRequestsAndCurrentUser.filter { $0.username.lowercased().contains(filter) }
                updateTableData()
            case .failure(let error):
                self.presentTTAlert(title: "Unable to fetch users", message: error.rawValue, buttonTitle: "Ok")
            }
        }
        dismissLoadingView()
    }
}

extension AddFriendVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendSearchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = friendSearchResultsTable.dequeueReusableCell(withIdentifier: ProfileUsernameCell.reuseID) as! ProfileUsernameCell
        let suggestedUser = friendSearchResults[indexPath.section]
        cell.set(for: suggestedUser.username)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = friendSearchResults[indexPath.section]
        delegate.selectedUserToAddFriend(for: selectedUser)
    }
}

