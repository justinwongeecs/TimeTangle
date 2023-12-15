//
//  TTAddUserConfirmationVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class AddUsersModalVC: TTModalCardVC {
    
    private let group: TTGroup!
    
    private var friends = [TTUser]()
    private var filteredFriends = [TTUser]()
    
    private let containerViewHeader = UIStackView()
    private var groupCodeView: TTGroupCodeView!
    private let friendsSearchBar = UISearchBar()
    private let filteredFriendsTableView = UITableView()

    private var addUserCompletionHandler: (TTUser) -> Void
    
    init(group: TTGroup, closeButtonClosure: @escaping () -> Void, addUserCompletionHandler: @escaping (TTUser) -> Void) {
        self.group = group
        self.addUserCompletionHandler = addUserCompletionHandler
        super.init(closeButtonClosure: closeButtonClosure)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureContainerViewHeader()
        configureGroupCodeView()
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
        headerLabel.text = "Add Friend To Group"
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
    
    private func configureGroupCodeView() {
        groupCodeView = TTGroupCodeView(codeText: group.code)
        groupCodeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(groupCodeView)
        
        NSLayoutConstraint.activate([
            groupCodeView.topAnchor.constraint(equalTo: containerViewHeader.bottomAnchor, constant: 10),
            groupCodeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 80),
            groupCodeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -80),
            groupCodeView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureFriendsSearchBar() {
        view.addSubview(friendsSearchBar)
        friendsSearchBar.translatesAutoresizingMaskIntoConstraints = false
        friendsSearchBar.searchBarStyle = .minimal
        friendsSearchBar.placeholder = "Search for a friend"
        friendsSearchBar.delegate = self
        
        NSLayoutConstraint.activate([
            friendsSearchBar.topAnchor.constraint(equalTo: groupCodeView.bottomAnchor, constant: 10),
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
        filteredFriendsTableView.register(ProfileAndNameCell.self, forCellReuseIdentifier: ProfileAndNameCell.reuseID)
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            filteredFriendsTableView.topAnchor.constraint(equalTo: friendsSearchBar.bottomAnchor),
            filteredFriendsTableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            filteredFriendsTableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            filteredFriendsTableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
        ])
    }
    
    private func reloadVC() {
        if !group.setting.allowGroupJoin {
            filteredFriendsTableView.backgroundView = TTEmptyStateView(message: "Cannot add user. Group setting \"Allow Group Join\" is toggled off", fontSize: 15)
            friendsSearchBar.disableSearchBar()
        } else if group.setting.maximumNumOfUsers == group.users.count {
            filteredFriendsTableView.backgroundView = TTEmptyStateView(message: "Cannot add user. Reached group setting \"Maximum Users\" of \(group.setting.maximumNumOfUsers)", fontSize: 15)
            friendsSearchBar.disableSearchBar()
        } else if filteredFriends.count == 0 {
            filteredFriendsTableView.backgroundView = TTEmptyStateView(message: "No Friends Available")
            friendsSearchBar.disableSearchBar()
        } else {
            friendsSearchBar.enableSearchBar()
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
        if group.setting.allowGroupJoin {
            guard let friends = FirebaseManager.shared.currentUser?.friends else { return }
            let filteredFriendsNotAddedToGroup = friends.filter{ !group.users.contains($0) }
            
            self.friends = []
            filteredFriends = []
            
            for friendID in filteredFriendsNotAddedToGroup {
                print("Friend id: \(friendID)")
                FirebaseManager.shared.fetchUserDocumentData(with: friendID) { [weak self] result in
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
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = filteredFriends[indexPath.section]
        let cell = filteredFriendsTableView.dequeueReusableCell(withIdentifier: ProfileAndNameCell.reuseID) as! ProfileAndNameCell
        cell.set(for: friend)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFriend = filteredFriends[indexPath.section]
        addUserCompletionHandler(selectedFriend)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 5))
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TTConstants.defaultCellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 7.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 7.0
    }
}

extension AddUsersModalVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.filteredFriends = friends
        } else {
            self.filteredFriends = friends.filter { $0.id.lowercased().contains(searchText.lowercased()) }
        }
 
        reloadVC()
    }
}
