//
//  FriendsAndRequestsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import UIKit
import FirebaseFirestore

protocol FriendsAndRequestVCDelegate: AnyObject {
    func didNeedToFilterSearchResults(_ controller: FriendsAndRequestsVC, with allUsers: [TTUser])
}

enum FriendsVCSegmentedState {
    case myFriends
    case friendRequests
}

class FriendsAndRequestsVC: UIViewController {
    
    //TODO: - friends and friendRequests require public access level due to AddFriendVC
    var searchBar: UISearchBar!
    var friends = [TTUser]() {
        didSet {
            if friends.isEmpty {
                filteredFriends = []
            }
        }
    }
    private var filteredFriends = [TTUser]()
    var friendRequests: [TTFriendRequest] = []
    private var searchWord = ""
    
    private let friendsSC = UISegmentedControl(items: ["My Friends", "Friend Requests"])
    private let table = UITableView()
    private var activityIndicator: TTActivityIndicatorView!
    private var searchFriendsCountLabel: UILabel!
    private var tableTopConstraint: NSLayoutConstraint!
    
    private var friendsVCSegementedState: FriendsVCSegmentedState = .myFriends {
        didSet {
            if friendsVCSegementedState == .friendRequests {
                searchBar.disableSearchBar()
            } else {
                searchBar.enableSearchBar()
            }
            reloadTable()
        }
    }
    
    weak var delegate: FriendsAndRequestVCDelegate!
    let tableViewsPadding: CGFloat = 10
    
    required init(searchBar: UISearchBar) {
        self.searchBar = searchBar
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackgroundView()
        configureFriendsSC()
        configureSearchFriendsCountLabel()
        configureFriendsTable()
        configureActivityIndicator()
    
        fetchFriends()
        reloadTable()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser(_:)), name: .updatedUser, object: nil)
    }
    
    @objc private func fetchUpdatedUser(_ notification: Notification) {
       fetchFriends()
    }
    
    private func fetchFriends() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        friendRequests = currentUser.friendRequests
        
        print("fetch friends")
        
        if !currentUser.friends.isEmpty {
            activityIndicator.startAnimating()
            FirebaseManager.shared.fetchMultipleUsersDocumentData(with: currentUser.friends) { [weak self] result in
                self?.activityIndicator.stopAnimating()
                switch result {
                case .success(let users):
                    self?.friends = users
                    self?.filterFriends(with: self?.searchWord ?? "")
                case .failure(let error):
                    self?.presentTTAlert(title: "Fetch Error", message: error.rawValue, buttonTitle: "OK")
                }
                DispatchQueue.main.async {
                    self?.reloadTable()
                }
            }
        } else {
            friends = []
        }
        reloadTable()
    }
    
    func filterFriends(with searchWord: String) {
        self.searchWord = searchWord
        
        if searchWord.isEmpty {
            filteredFriends = friends
            displaySearchCountLabel(isHidden: true)
        } else {
            filteredFriends = friends.filter({ $0.username.lowercased().contains(searchWord.lowercased()) })
            
            if filteredFriends.isEmpty {
                displaySearchCountLabel(isHidden: true)
            } else {
                displaySearchCountLabel(isHidden: false)
                updateSearchFriendsCountLabel(with: filteredFriends.count)
            }
        }
        
        DispatchQueue.main.async {
            self.reloadTable()
        }
    }
    
    func setTableViewEditing(to editing: Bool) {
        table.setEditing(editing, animated: true)
    }
    
    private func configureBackgroundView() {
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 18
    }
    
    private func configureFriendsSC() {
        // Add this custom Segmented Control to our view
        view.addSubview(friendsSC)
        
        friendsSC.translatesAutoresizingMaskIntoConstraints = false
        friendsSC.selectedSegmentIndex = 0
        
        let frame = view.bounds
        friendsSC.frame = CGRectMake(frame.minX + 10, frame.minY + 50,
                                          frame.width - 20, frame.height*0.1)

        // Style the Segmented Control
        friendsSC.layer.cornerRadius = 5.0  // Don't let background bleed
        friendsSC.backgroundColor = .systemBackground

        // Add target action method
        friendsSC.addTarget(self, action: #selector(toggleFriendsSC(sender:)), for: .valueChanged)

        NSLayoutConstraint.activate([
            friendsSC.topAnchor.constraint(equalTo: view.topAnchor),
            friendsSC.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            friendsSC.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            friendsSC.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func configureFriendsTable() {
        view.addSubview(table)
        table.backgroundColor = .systemBackground
        table.separatorStyle = .none
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        
        table.register(FriendCell.self, forCellReuseIdentifier: FriendCell.friendCellReuseID)
        table.register(FriendRequestCell.self, forCellReuseIdentifier: FriendRequestCell.reuseID)
        
        tableTopConstraint = table.topAnchor.constraint(equalTo: friendsSC.bottomAnchor, constant: 10)
        tableTopConstraint.isActive = true 
        
        NSLayoutConstraint.activate([
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: tableViewsPadding),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -tableViewsPadding),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureActivityIndicator() {
        activityIndicator = TTActivityIndicatorView(containerView: table)
    }
    
    @objc private func toggleFriendsSC(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1: //Friend Requests
            friendsVCSegementedState = .friendRequests
        default: //My Friends
            friendsVCSegementedState = .myFriends
        }
    }
    
    private func reloadTable() {
        switch friendsVCSegementedState {
        case .myFriends:
            if filteredFriends.isEmpty {
                table.backgroundView = TTEmptyStateView(message: "No Friends Available")
            } else {
                searchBar.enableSearchBar()
                table.backgroundView = nil
            }
        case .friendRequests:
            if friendRequests.isEmpty {
                table.backgroundView = TTEmptyStateView(message: "No Friend Requests")
            } else {
                table.backgroundView = nil
            }
        }
        table.reloadData()
    }
    
    private func configureSearchFriendsCountLabel() {
        searchFriendsCountLabel = UILabel().withSearchCountStyle()
        view.addSubview(searchFriendsCountLabel)
        
        NSLayoutConstraint.activate([
            searchFriendsCountLabel.topAnchor.constraint(equalTo: friendsSC.bottomAnchor, constant: 10),
            searchFriendsCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchFriendsCountLabel.heightAnchor.constraint(equalToConstant: 20),
            searchFriendsCountLabel.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func displaySearchCountLabel(isHidden: Bool) {
        UIView.transition(with: searchFriendsCountLabel, duration: 0.5, options: .transitionCrossDissolve) {
            self.searchFriendsCountLabel.isHidden = isHidden
        }
        
        //update groupsTable top constraint
        if isHidden {
            UIView.animate(withDuration: 0.35) { [weak self] in
                guard let self = self else { return }
                let newConstraint = self.table.topAnchor.constraint(equalTo: self.friendsSC.bottomAnchor, constant: 10)
                self.updateTableTopConstraint(for: newConstraint)
            }
        } else {
            UIView.animate(withDuration: 0.35) { [weak self] in
                guard let self = self else { return }
                let newConstraint = self.table.topAnchor.constraint(equalTo: self.searchFriendsCountLabel.bottomAnchor, constant: 10)
                self.updateTableTopConstraint(for: newConstraint)
            }
        }
    }
    
    private func updateTableTopConstraint(for constraint: NSLayoutConstraint) {
        tableTopConstraint.isActive = false
        tableTopConstraint = constraint
        tableTopConstraint.isActive = true
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    private func updateSearchFriendsCountLabel(with count: Int) {
        searchFriendsCountLabel.text = "\(count) Found"
    }
    
    func selectedUserToAddFriend(for user: TTUser) {
        //catch if friend has already been added
        guard friends.filter({ $0 == user }).count == 0 else {
            presentTTAlert(title: "Cannot Friend Request", message: TTError.friendAlreadyAdded.rawValue, buttonTitle: "Ok")
            return
        }
        
        //catch if friend has not been added yet officially but has been requested
        guard friendRequests.filter({ $0.senderName == user.username }).count == 0 else {
            presentTTAlert(title: "Cannot Friend Request", message: TTError.friendAlreadyRequested.rawValue, buttonTitle: "Ok")
            return
        }
        
        //current user is the SENDER
        //parameter user is the RECEIPIENT
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
                
        let senderFriendRequest = TTFriendRequest(senderProfilePictureData: currentUser.profilePictureData, recipientProfilePictureData: user.profilePictureData, senderName: currentUser.getFullName(), recipientName: user.getFullName(), requestType: .outgoing)
        var recipientFriendRequest = senderFriendRequest
        recipientFriendRequest.requestType = .receiving
        
        let senderUpdateData = [
            TTConstants.friendRequests: FieldValue.arrayUnion([senderFriendRequest.dictionary])
        ]
        let recipientUpdateData = [
            TTConstants.friendRequests: FieldValue.arrayUnion([recipientFriendRequest.dictionary])
        ]
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let currentUserRef = db.collection(TTConstants.usersCollection).document(currentUser.username)
        batch.updateData(senderUpdateData, forDocument: currentUserRef)
        
        let recipientUserRef = db.collection(TTConstants.usersCollection).document(user.username)
        batch.updateData(recipientUpdateData, forDocument: recipientUserRef)
        
        batch.commit() { [weak self] error in
            if let error = error {
                self?.presentTTAlert(title: "Update User Error", message: error.localizedDescription, buttonTitle: "OK")
            } else {
                self?.dismiss(animated: true)
            }
        }
    }
}

//MARK: - Delegates
extension FriendsAndRequestsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if friendsVCSegementedState == .myFriends  {
            let friend = filteredFriends[indexPath.section]
            let myFriendCell = table.dequeueReusableCell(withIdentifier: FriendCell.friendCellReuseID) as! FriendCell
            myFriendCell.set(for: friend)
            return myFriendCell
        }
        
        let myFriendRequestCell = table.dequeueReusableCell(withIdentifier: FriendRequestCell.reuseID) as! FriendRequestCell
        let friendRequest = friendRequests[indexPath.section]
        myFriendRequestCell.set(for: friendRequest)
        myFriendRequestCell.delegate = self
        return myFriendRequestCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TTConstants.defaultCellHeight
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if friendsVCSegementedState == .myFriends {
            return filteredFriends.count
        } else {
            return friendRequests.count
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
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
}

//MARK: - FriendRequestCellDelegate
extension FriendsAndRequestsVC: FriendRequestCellDelegate {
    func clickedFriendRequestActionButton(result: Result<Void, TTError>) {
        switch result {
        case .success(_):
            DispatchQueue.main.async {
                self.reloadTable()
            }
        case .failure(let error):
            self.presentTTAlert(title: "Friend Request Action Error", message: error.rawValue, buttonTitle: "OK")
        }
    }
}


