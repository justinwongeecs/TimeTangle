//
//  SearchFriendsResultController.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/27/22.
//

import UIKit

protocol SearchFriendsResultControllerDelegate: AnyObject {
    func didSelectSuggestedSearch(for user: TTUser)
}

class SearchFriendsResultController: UIViewController {
    
    private let searchFriendsResultTable = UITableView()
    
    private var allFriends = [TTUser]()
    private var filteredFriends = [TTUser]()
    
    weak var suggestedSearchDelegate: SearchFriendsResultControllerDelegate!
    weak var searchVCRef: SearchVC!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureSearchFriendsResultTable()
    }
    
    func setAllFriends(with friends: [TTUser]) {
        let usersInQueue = searchVCRef.getUsersQueueForRoomCreation()
        let friendsNotInUsersQueue = friends.filter { !usersInQueue.map{ $0.username }.contains($0.username) }
        allFriends = friendsNotInUsersQueue
        filteredFriends = friendsNotInUsersQueue
        
        reloadTable()
    }
    
    private func configureSearchFriendsResultTable() {
        view.addSubview(searchFriendsResultTable)
        searchFriendsResultTable.translatesAutoresizingMaskIntoConstraints = false
        searchFriendsResultTable.delegate = self
        searchFriendsResultTable.dataSource = self
        searchFriendsResultTable.register(ProfileUsernameCell.self, forCellReuseIdentifier: ProfileUsernameCell.reuseID)
        
        searchFriendsResultTable.separatorStyle = .none
        
        NSLayoutConstraint.activate([
            searchFriendsResultTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchFriendsResultTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchFriendsResultTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            searchFriendsResultTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func search(with searchText: String) {
        if searchText.isEmpty {
            filteredFriends = allFriends
        } else {
            filteredFriends = allFriends.filter { $0.username.contains(searchText) }
        }
        
        reloadTable()
    }
    
    private func reloadTable() {
        removeEmptyStateView(in: view)
        
        if filteredFriends.isEmpty {
            searchFriendsResultTable.isHidden = true
            showEmptyStateView(with: "No Friends Found", in: view)
        } else {
            searchFriendsResultTable.isHidden = false
        }
        
        DispatchQueue.main.async {
            self.searchFriendsResultTable.reloadData()
        }
    }
}

// MARK: - Table view data source
extension SearchFriendsResultController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = searchFriendsResultTable.dequeueReusableCell(withIdentifier: ProfileUsernameCell.reuseID) as! ProfileUsernameCell
        
        let filteredFriend = filteredFriends[indexPath.section]
        cell.set(for: filteredFriend)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFilteredUser = filteredFriends[indexPath.row]
        suggestedSearchDelegate.didSelectSuggestedSearch(for: selectedFilteredUser)
    }
}
