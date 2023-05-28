//
//  TTAddUserConfirmationVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class AddUsersModalVC: TTModalCardVC {
    
    private let room: TTRoom!
    
    private var friends = [TTUser]()
    private var filteredFriends = [TTUser]()
    
    private let containerViewHeader = UIStackView()
    private var roomCodeView: TTRoomCodeView!
    private let friendsSearchBar = UISearchBar()
    private let filteredFriendsTableView = UITableView()

    private var addUserCompletionHandler: (String) -> Void
    
    init(room: TTRoom, closeButtonClosure: @escaping () -> Void, addUserCompletionHandler: @escaping (String) -> Void) {
        self.room = room
        self.addUserCompletionHandler = addUserCompletionHandler
        super.init(closeButtonClosure: closeButtonClosure)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureContainerViewHeader()
        configureRoomCodeView()
        configureFriendsSearchBar()
        configureFilteredFriendsTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser), name: .updatedUser, object: nil)
        fetchFriends()
        reloadVC()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureContainerViewHeader() {
        containerView.addSubview(containerViewHeader)
        containerViewHeader.translatesAutoresizingMaskIntoConstraints = false
        containerViewHeader.layer.cornerRadius = 16
        containerViewHeader.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerViewHeader.backgroundColor = .systemBackground
        containerViewHeader.axis = .horizontal
    
        let headerLabel = TTTitleLabel(textAlignment: .center, fontSize: 18)
        headerLabel.text = "Add Friend To Room"
        headerLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        let closeButton = TTCloseButton()
        closeButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        
        containerViewHeader.addArrangedSubview(headerLabel)
        containerViewHeader.addArrangedSubview(closeButton)
        
        NSLayoutConstraint.activate([
            containerViewHeader.topAnchor.constraint(equalTo: containerView.topAnchor),
            containerViewHeader.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            containerViewHeader.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            containerViewHeader.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureRoomCodeView() {
        roomCodeView = TTRoomCodeView(codeText: room.code)
        roomCodeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roomCodeView)
        
        NSLayoutConstraint.activate([
            roomCodeView.topAnchor.constraint(equalTo: containerViewHeader.bottomAnchor, constant: 10),
            roomCodeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 80),
            roomCodeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -80),
            roomCodeView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureFriendsSearchBar() {
        view.addSubview(friendsSearchBar)
        friendsSearchBar.translatesAutoresizingMaskIntoConstraints = false
        friendsSearchBar.searchBarStyle = .minimal
        friendsSearchBar.placeholder = "Search for a friend"
        friendsSearchBar.delegate = self
        
        NSLayoutConstraint.activate([
            friendsSearchBar.topAnchor.constraint(equalTo: roomCodeView.bottomAnchor, constant: 10),
            friendsSearchBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            friendsSearchBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            friendsSearchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureFilteredFriendsTableView() {
        containerView.addSubview(filteredFriendsTableView)
        filteredFriendsTableView.separatorStyle = .none
        filteredFriendsTableView.translatesAutoresizingMaskIntoConstraints = false
        filteredFriendsTableView.delegate = self
        filteredFriendsTableView.dataSource = self
        filteredFriendsTableView.register(ProfileUsernameCell.self, forCellReuseIdentifier: ProfileUsernameCell.reuseID)
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            filteredFriendsTableView.topAnchor.constraint(equalTo: friendsSearchBar.bottomAnchor),
            filteredFriendsTableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            filteredFriendsTableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            filteredFriendsTableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
        ])
    }
    
    private func reloadVC() {
        if !room.setting.allowRoomJoin {
            filteredFriendsTableView.backgroundView = TTEmptyStateView(message: "Cannot add user. Room setting \"Allow Room Join\" is toggled off", fontSize: 15)
            disableFriendsSearchBar()
        } else if room.setting.maximumNumOfUsers == room.users.count {
            filteredFriendsTableView.backgroundView = TTEmptyStateView(message: "Cannot add user. Reached room setting \"Maximum Users\" of \(room.setting.maximumNumOfUsers)", fontSize: 15)
            disableFriendsSearchBar()
        } else if filteredFriends.count == 0 {
            filteredFriendsTableView.backgroundView = TTEmptyStateView(message: "No Friends Available")
            disableFriendsSearchBar()
        } else {
            filteredFriendsTableView.backgroundView = nil
        }
        
        DispatchQueue.main.async {
            self.filteredFriendsTableView.reloadData()
        }
    }
    
    @objc private func fetchUpdatedUser(_ notification: Notification) {
        DispatchQueue.main.async {
            self.fetchFriends()
            self.reloadVC()
        }
    }
    
    private func fetchFriends() {
        if room.setting.allowRoomJoin {
            guard let friends = FirebaseManager.shared.currentUser?.friends else { return }
            let filteredFriendsNotAddedToRoom = friends.filter{ !room.users.contains($0) }
            
            self.friends = []
            filteredFriends = []
            
            for friendUsername in filteredFriendsNotAddedToRoom {
                print("Friend username: \(friendUsername)")
                FirebaseManager.shared.fetchUserDocumentData(with: friendUsername) { [weak self] result in
                    switch result {
                    case .success(let ttUser):
                        self?.friends.append(ttUser)
                        self?.filteredFriends.append(ttUser)
                        
                        DispatchQueue.main.async {
                            self?.reloadVC()
                        }
                    case .failure(let error):
                        self?.presentTTAlert(title: "Cannot Fetch Friends", message: error.rawValue, buttonTitle: "OK")
                    }
                }
            }
        }
    }
    
    private func disableFriendsSearchBar() {
        if #available(iOS 16.4, *) {
            friendsSearchBar.isEnabled = false
        } else {
            // Fallback on earlier versions
            friendsSearchBar.isUserInteractionEnabled = false
            friendsSearchBar.layer.opacity = 0.1
        }
    }
}

extension AddUsersModalVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = filteredFriends[indexPath.row]
        let cell = filteredFriendsTableView.dequeueReusableCell(withIdentifier: ProfileUsernameCell.reuseID) as! ProfileUsernameCell
        cell.set(for: friend)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFriend = filteredFriends[indexPath.row]
        addUserCompletionHandler(selectedFriend.username)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
}

extension AddUsersModalVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.filteredFriends = friends
        } else {
            self.filteredFriends = friends.filter { $0.username.lowercased().contains(searchText.lowercased()) }
        }
 
        reloadVC()
    }
}
