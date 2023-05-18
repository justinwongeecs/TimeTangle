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
    
    let searchFriendsResultTable = UITableView()
    
    var filteredFriends = [TTUser]()
    
    //Random list of friends for now but maybe in the future we can tailor
    var suggestedSearches = [String]()
    
    weak var suggestedSearchDelegate: SearchFriendsResultControllerDelegate!
    weak var searchVCRef: UIViewController!
    
    var showSuggestedSearches: Bool = false {
        didSet {
            if oldValue != showSuggestedSearches {
                DispatchQueue.main.async {
                    self.searchFriendsResultTable.reloadData()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchFriendsResultTable()
        getSuggestedSearches(withMaxCount: 3)
    }
    
    private func configureSearchFriendsResultTable() {
        view.addSubview(searchFriendsResultTable)
        searchFriendsResultTable.translatesAutoresizingMaskIntoConstraints = false
        searchFriendsResultTable.delegate = self
        searchFriendsResultTable.dataSource = self
        searchFriendsResultTable.register(ProfileUsernameCell.self, forCellReuseIdentifier: ProfileUsernameCell.reuseID)
        
        searchFriendsResultTable.separatorStyle = .none
        
        NSLayoutConstraint.activate([
            searchFriendsResultTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchFriendsResultTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchFriendsResultTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchFriendsResultTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func getSuggestedSearches(withMaxCount maxCount: Int) {
        guard let searchVCRef = searchVCRef as? SearchVC else { return }
        guard let currentUserFriends = FirebaseManager.shared.currentUser?.friends else { return }
        
        //filter out users in usersQueueForRoomCreation (all ready added to queue)
        let fullyFilteredFriends = currentUserFriends.filter({ !searchVCRef.usersQueueForRoomCreation.map{$0.username.lowercased()}.contains($0.lowercased()) })

        self.removeEmptyStateView(in: self.view)
        if fullyFilteredFriends.count == 0 {
            //Display empty state view
            self.showEmptyStateView(with: "No Suggested Search Results Available", in: self.view)
            self.suggestedSearches = []
        } else if fullyFilteredFriends.count <= maxCount {
            self.suggestedSearches = Array(fullyFilteredFriends[0..<fullyFilteredFriends.count])
        } else {
            self.suggestedSearches = Array(fullyFilteredFriends[0..<maxCount])
        }
        
        DispatchQueue.main.async {
            self.searchFriendsResultTable.reloadData()
        }
    }
    
    func search(with searchText: String) {
        removeEmptyStateView(in: self.view)
        
        if searchText.isEmpty {
            showSuggestedSearches = true
            return 
        }
        
        var searchResults = [String]()
        guard let currentUserFriends = FirebaseManager.shared.currentUser?.friends else { return }
        
        for filteredFriend in currentUserFriends {
            if filteredFriend.contains(searchText) {
                searchResults.append(filteredFriend)
            }
        }
        
        if !searchResults.isEmpty {
            FirebaseManager.shared.fetchMultipleUsersDocumentData(with: searchResults) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let ttUsers):
                    filteredFriends = ttUsers
                    DispatchQueue.main.async {
                        self.searchFriendsResultTable.reloadData()
                    }
                    break
                case .failure(let error):
                    //TODO: Put alert messages into a static class
                    self.presentTTAlert(title: "Server Error", message: error.rawValue, buttonTitle: "Ok")
                }
            }
        } else {
            showEmptyStateView(with: "No Friends Found", in: self.view)
        }
    }
}

// MARK: - Table view data source
extension SearchFriendsResultController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return showSuggestedSearches ? suggestedSearches.count : filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return showSuggestedSearches ? "Suggested Friends" : ""
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = searchFriendsResultTable.dequeueReusableCell(withIdentifier: ProfileUsernameCell.reuseID) as! ProfileUsernameCell
        
        if showSuggestedSearches {
            let suggestedFriendUsername = suggestedSearches[indexPath.section]
            cell.set(for: suggestedFriendUsername)
//            FirebaseManager.shared.fetchUserDocumentData(with: suggestedFriendUsername) { [weak self] result in
//                switch result {
//                case .success(let user):
//                    cell.set(for: user)
//                case .failure(let error):
//                    self?.presentTTAlert(title: "Fetch Suggested Users Error", message: error.rawValue, buttonTitle: "Ok")
//                }
//            }
        } else  {
            let filteredFriend = filteredFriends[indexPath.section]
            cell.set(for: filteredFriend.username)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Add to usersQueue list in SearchVC
        if showSuggestedSearches {
            let selectedSuggestedUsername = suggestedSearches[indexPath.section]
            print(selectedSuggestedUsername)
            FirebaseManager.shared.fetchUserDocumentData(with: selectedSuggestedUsername) { [weak self] result in
                switch result {
                case .success(let user):
                    self?.suggestedSearchDelegate.didSelectSuggestedSearch(for: user)
                case .failure(let error):
                    self?.presentTTAlert(title: "Fetch User Error", message: error.rawValue, buttonTitle: "Ok")
                }
            }
        } else {
            let selectedFilteredUser = filteredFriends[indexPath.row]
            suggestedSearchDelegate.didSelectSuggestedSearch(for: selectedFilteredUser)
        }
    }
}
