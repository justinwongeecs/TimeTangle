//
//  TTAddUserConfirmationVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

protocol AddUsersModalVCDelegate: AnyObject {
    func didSelectUserToBeAdded(for username: String)
}

class AddUsersModalVC: TTModalCardVC {
    
    private let room: TTRoom!
    
    private var mainContentView = UIView()
    private var filteredFriends = [String]()
    private let friendsSearchBar = UISearchBar()
    private let filteredFriendsTableView = UITableView()
    private let emptyStateView = TTEmptyStateView()
    
    weak var addUsersModalVCDelegate: AddUsersModalVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.text = "Add Friend To Room"
        configureFriendsSearchBar()
        configureMainContentView()
        configureEmptyStateView()
        configureFilteredFriendsTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser), name: .updatedUser, object: nil)
        fetchAndSetFriends()
    }
    
    init(room: TTRoom) {
        self.room = room
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func fetchAndSetFriends() {
        guard let friends = FirebaseManager.shared.currentUser?.friends else { return }
        let filteredFriendsNotAddedToRoom = friends.filter{ !room.users.contains($0) }
        filteredFriends = filteredFriendsNotAddedToRoom
        reloadMainContentView()
    }
    
    private func configureFriendsSearchBar() {
        view.addSubview(friendsSearchBar)
        friendsSearchBar.translatesAutoresizingMaskIntoConstraints = false
        friendsSearchBar.searchBarStyle = .minimal
        friendsSearchBar.placeholder = "Search for a friend"
        friendsSearchBar.delegate = self
        
        NSLayoutConstraint.activate([
            friendsSearchBar.topAnchor.constraint(equalTo: containerViewHeader.bottomAnchor, constant: 10),
            friendsSearchBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            friendsSearchBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            friendsSearchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureMainContentView() {
        view.addSubview(mainContentView)
        mainContentView.translatesAutoresizingMaskIntoConstraints = false
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            mainContentView.topAnchor.constraint(equalTo: friendsSearchBar.bottomAnchor, constant: padding),
            mainContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            mainContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            mainContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
        ])
    }
    
    private func configureFilteredFriendsTableView() {
        mainContentView.addSubview(filteredFriendsTableView)
        filteredFriendsTableView.translatesAutoresizingMaskIntoConstraints = false
        filteredFriendsTableView.delegate = self
        filteredFriendsTableView.dataSource = self
        
        //register table view
        filteredFriendsTableView.register(PlainProfileAndUsernameCell.self, forCellReuseIdentifier: PlainProfileAndUsernameCell.reuseID)
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            filteredFriendsTableView.topAnchor.constraint(equalTo: mainContentView.bottomAnchor),
            filteredFriendsTableView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor),
            filteredFriendsTableView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor),
            filteredFriendsTableView.bottomAnchor.constraint(equalTo: mainContentView.bottomAnchor)
        ])
    }
    
    private func configureEmptyStateView() {
        emptyStateView.messageLabel.text = "No Friends Available"
        mainContentView.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        mainContentView.frame = mainContentView.bounds
        
        NSLayoutConstraint.activate([
            emptyStateView.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor),
            emptyStateView.centerXAnchor.constraint(equalTo: mainContentView.centerXAnchor),
            emptyStateView.widthAnchor.constraint(equalToConstant: 300),
            emptyStateView.heightAnchor.constraint(equalToConstant: 300),
        ])
    }
    
    private func reloadMainContentView() {
//        self.removeEmptyStateView(in: self.mainContentView)
        if filteredFriends.count == 0 {
            //show empty state view
//            self.showEmptyStateView(with: "No Suggested Friends", in: self.mainContentView)
            friendsSearchBar.isUserInteractionEnabled = false
            friendsSearchBar.alpha = 0.75
            mainContentView.bringSubviewToFront(emptyStateView)
        } else {
            //show table view
            DispatchQueue.main.async {
                self.filteredFriendsTableView.reloadData()
                self.view.bringSubviewToFront(self.filteredFriendsTableView)
            }
        }
    }
    
    @objc private func fetchUpdatedUser(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let fetchedUser = notification.object as? TTUser else { return }
            self.filteredFriends = fetchedUser.friends
            self.reloadMainContentView()
        }
    }
}

extension AddUsersModalVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = filteredFriendsTableView.dequeueReusableCell(withIdentifier: PlainProfileAndUsernameCell.reuseID) as! PlainProfileAndUsernameCell
        let filteredUsername = filteredFriends[indexPath.row]
        FirebaseManager.shared.fetchUserDocumentData(with: filteredUsername) { [weak self] result in
            switch result {
            case .success(let user):
                cell.setCell(for: user)
            case .failure(let error):
                self?.presentTTAlert(title: "Error fetching user", message: error.rawValue, buttonTitle: "Ok")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let delegate = addUsersModalVCDelegate else { return }
        let selectedFriend = filteredFriends[indexPath.row]
        delegate.didSelectUserToBeAdded(for: selectedFriend)
    }
}

extension AddUsersModalVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //Search bar text changed -> Do the filtering friends here
        self.filteredFriends = filteredFriends.filter { $0.contains(searchText) }
        reloadMainContentView()
    }
}

class PlainProfileAndUsernameCell: UITableViewCell {
    
    static let reuseID = "PlainProfileAndUsernameCell"
    
    private let profileView = UIImageView()
    private let usernameLabel = TTBodyLabel(textAlignment: .left)
    private let padding: CGFloat = 5
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        //TODO: Figure how to make cell have rounded corners when selected
//        layer.masksToBounds = true
//        layer.cornerRadius = 8
        configureProfileView()
        configureUsernameLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCell(for user: TTUser) {
        usernameLabel.text = user.username
    }
    
    private func configureProfileView() {
        addSubview(profileView)
        profileView.image =  UIImage(systemName: "person.crop.circle")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        profileView.image?.withTintColor(.secondaryLabel)
        profileView.frame = CGRect(x: 10, y: 10, width: 30, height: 30)
        
        NSLayoutConstraint.activate([
            profileView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            profileView.leadingAnchor.constraint(equalTo: leadingAnchor),
            profileView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            profileView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func configureUsernameLabel() {
        addSubview(usernameLabel)
        
        NSLayoutConstraint.activate([
            usernameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: profileView.trailingAnchor, constant: 10),
            usernameLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

