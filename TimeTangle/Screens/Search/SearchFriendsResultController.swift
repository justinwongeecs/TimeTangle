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
    private var usersInQueueCache: TTCache<String, TTUser>!
    
    weak var suggestedSearchDelegate: SearchFriendsResultControllerDelegate!
    weak var searchVCRef: CreateGroupVC!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        configureDismissEditingTapGestureRecognizer()
        configureSearchFriendsResultTable()
        configureActivityIndicator()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchAllFriends()
    }
    
    init(usersInQueueCache: TTCache<String, TTUser>) {
        super.init(nibName: nil, bundle: nil)
        self.usersInQueueCache = usersInQueueCache
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fetchAllFriends() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        activityIndicator.startAnimating()
        allFriends.removeAll()
        filteredFriends.removeAll()
        
        for friendUsername in currentUser.friends {
            if let cachedFriend = usersInQueueCache.value(forKey: friendUsername) {
                validateFriend(for: cachedFriend)
            } else {
                activityIndicator.startAnimating()
                FirebaseManager.shared.fetchUserDocumentData(with: friendUsername) { [weak self] result in
                    self?.activityIndicator.stopAnimating()
                    guard let self = self else { return }
                    switch result {
                    case .success(let fetchedFriend):
                        validateFriend(for: fetchedFriend)
                        usersInQueueCache.insert(fetchedFriend, forKey: fetchedFriend.username )
                    case .failure(let error):
                        self.presentTTAlert(title: "Fetch Error", message: error.rawValue, buttonTitle: "OK")
                    }
                }
            }
        }
        activityIndicator.stopAnimating()
    }
    
    private func validateFriend(for friend: TTUser) {
        let usersInQueueUsernames = searchVCRef.getUsersQueueForGroupCreation().getUsernames()
        
        if !usersInQueueUsernames.contains(friend.username) {
            allFriends.append(friend)
            filteredFriends.append(friend)
        }
        
        DispatchQueue.main.async {
            self.reloadTable()
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
            searchFriendsResultTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
            searchFriendsResultTable.backgroundView = TTEmptyStateView(message: "No Friends Found")
        } else {
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
        return TTConstants.defaultCellHeight
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
