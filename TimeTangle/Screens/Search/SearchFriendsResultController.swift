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
    private var activityIndicator: TTActivityIndicatorView!
    
    private var allFriends = [TTUser]()
    private var filteredFriends = [TTUser]()
    
    weak var suggestedSearchDelegate: SearchFriendsResultControllerDelegate!
    weak var searchVCRef: CreateRoomVC!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        configureDismissEditingTapGestureRecognizer()
        configureSearchFriendsResultTable()
        configureActivityIndicator()
        
        fetchAllFriends()
    }
    
    func fetchAllFriends() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        if !currentUser.friends.isEmpty {
            activityIndicator.startAnimating()
            FirebaseManager.shared.fetchMultipleUsersDocumentData(with: currentUser.friends) { [weak self] result in
                self?.activityIndicator.stopAnimating()
                guard let self = self else { return }
                switch result {
                case .success(let allFriends):
                    let usersInQueue = searchVCRef.getUsersQueueForRoomCreation()
                    let friendsNotInUsersQueue = allFriends.filter { !usersInQueue.map{ $0.username }.contains($0.username) }
                    self.allFriends = friendsNotInUsersQueue
                    self.filteredFriends = friendsNotInUsersQueue
                    self.reloadTable()
                case .failure(let error):
                    self.presentTTAlert(title: "Fetch Error", message: error.rawValue, buttonTitle: "OK")
                }
            }
        }
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
    
    private func configureActivityIndicator() {
        activityIndicator = TTActivityIndicatorView(containerView: searchFriendsResultTable)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func search(with searchText: String) {
        if searchText.isEmpty {
            filteredFriends = allFriends
        } else {
            filteredFriends = allFriends.filter { $0.username.lowercased().contains(searchText.lowercased()) }
        }
        
        reloadTable()
    }
    
    private func reloadTable() {
        if filteredFriends.isEmpty {
            searchFriendsResultTable.isHidden = true
            searchFriendsResultTable.backgroundView = TTEmptyStateView(message: "No Friends Found")
        } else {
            searchFriendsResultTable.isHidden = false
            searchFriendsResultTable.backgroundView = nil
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
        let selectedFilteredUser = filteredFriends[indexPath.section]
        suggestedSearchDelegate.didSelectSuggestedSearch(for: selectedFilteredUser)
    }
    
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 5))
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 7.0
    }
}
