//
//  FriendsAndRequestsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import UIKit

protocol FriendsAndRequestVCDelegate: AnyObject {
    func didNeedToFilterSearchResults(_ controller: FriendsAndRequestsVC, with allUsers: [TTUser])
}

enum FriendsVCSegmentedState {
    case myFriends
    case friendRequests
}

class FriendsAndRequestsVC: UIViewController {
    
    var friends: [String] = []
    //filteredFriends is what's being visibily shown
    var filteredFriends: [String] = []
    var friendRequests: [TTFriendRequest] = []
    
    let friendsSC = UISegmentedControl(items: ["My Friends", "Friend Requests"])
    let table = UITableView()
    
    var friendsVCSegementedState: FriendsVCSegmentedState = .myFriends {
        didSet {
            reloadTable()
        }
    }
    
    weak var delegate: FriendsAndRequestVCDelegate!
    let tableViewsPadding: CGFloat = 10

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackgroundView()
        configureFriendsSC()
        configureFriendsTable()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser(_:)), name: .updatedUser, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let friendRequests = FirebaseManager.shared.currentUser?.friendRequests else { return }
        guard let friends = FirebaseManager.shared.currentUser?.friends else { return }
 
        DispatchQueue.main.async {
            self.friendRequests = friendRequests
            self.friends = friends
            self.filteredFriends = friends
            self.reloadTable()
        }
    }
    
    func filterFriends(with searchWord: String) {
        print("SearchWordEmpty: \(searchWord.isEmpty)")
        if searchWord.isEmpty {
            filteredFriends = friends
        } else {
            filteredFriends = friends.filter({ $0.contains(searchWord) })
        }
        DispatchQueue.main.async {
            self.reloadTable()
        }
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
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self
        
        table.register(ProfileUsernameCell.self, forCellReuseIdentifier: ProfileUsernameCell.reuseID)
        table.register(FriendRequestCell.self, forCellReuseIdentifier: FriendRequestCell.reuseID)
        
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: friendsSC.bottomAnchor, constant: 10),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: tableViewsPadding),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -tableViewsPadding),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func toggleFriendsSC(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1: //Friend Requests
            friendsVCSegementedState = .friendRequests
        default: //My Friends
            friendsVCSegementedState = .myFriends
        }
    }
    
    @objc private func fetchUpdatedUser(_ notification: Notification) {
        guard let fetchedUser = notification.object as? TTUser else { return }
        friends = fetchedUser.friends 
        filteredFriends = fetchedUser.friends
        friendRequests = fetchedUser.friendRequests
        reloadTable()
    }
    
    private func reloadTable() {
        removeEmptyStateView(in: view)
        switch friendsVCSegementedState {
        case .myFriends:
            if friends.isEmpty {
                showEmptyStateView(with: "No Friends :(", in: view, viewsPresentInFront: [friendsSC])
            }
        case .friendRequests:
            if friendRequests.isEmpty {
                showEmptyStateView(with: "No Friend Requests", in: view, viewsPresentInFront: [friendsSC])
            }
        }
        DispatchQueue.main.async {
            self.table.reloadData()
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
            let myFriendCell = table.dequeueReusableCell(withIdentifier: ProfileUsernameCell.reuseID) as! ProfileUsernameCell

            FirebaseManager.shared.fetchUserDocumentData(with: filteredFriends[indexPath.section]) { result in
                switch result {
                case .success(let user):
                    myFriendCell.set(for: user)
                case .failure(_):
                    break
                }
            }
            return myFriendCell
        }
        
        let myFriendRequestCell = table.dequeueReusableCell(withIdentifier: FriendRequestCell.reuseID) as! FriendRequestCell
        let friendRequest = friendRequests[indexPath.row]
        myFriendRequestCell.set(for: friendRequest)
        myFriendRequestCell.delegate = self
        return myFriendRequestCell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 5.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if friendsVCSegementedState == .myFriends {
            return filteredFriends.count
        } else {
            return friendRequests.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 10))
        view.backgroundColor = .clear
        return view
    }
}

//MARK: - AddFriendVCDelegate
extension FriendsAndRequestsVC: AddFriendVCDelegate {
    
    func selectedUserToAddFriend(for user: TTUser) {
        //catch if friend has already been added
        guard friends.filter({ $0 == user.username }).count == 0 else {
            presentTTAlert(title: "Cannot Friend Request", message: TTError.friendAlreadyAdded.rawValue, buttonTitle: "Ok")
            return
        }
        
        //catch if friend has not been added yet officially but has been requested
        guard friendRequests.filter({ $0.senderUsername == user.username }).count == 0 else {
            presentTTAlert(title: "Cannot Friend Request", message: TTError.friendAlreadyRequested.rawValue, buttonTitle: "Ok")
            return
        }
        
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        //update user on Firebase
        let senderFriendRequest = TTFriendRequest(senderUsername: currentUser.username, recipientUsername: user.username, requestType: .outgoing)
        let recipientFriendRequest = TTFriendRequest(senderUsername: currentUser.username, recipientUsername: user.username, requestType: .receiving)
        
        let senderUpdateData = [
            TTConstants.friendRequests: currentUser.friendRequests.arrayByAppending(senderFriendRequest).map{ $0.dictionary }
        ]
        let recipientUpdateData = [
            TTConstants.friendRequests: user.friendRequests.arrayByAppending(recipientFriendRequest).map{ $0.dictionary }
        ]
        
        //update current user's friendRequests field
        FirebaseManager.shared.updateUserData(for: currentUser.username, with: senderUpdateData) { [weak self] error in
            guard let error = error else { return }
        
            //error returned, present error to user
            self?.presentTTAlert(title: "Update User Error", message: error.rawValue, buttonTitle: "Ok")
        }
        
        //update receiving user's friendRequests field
        FirebaseManager.shared.updateUserData(for: user.username, with: recipientUpdateData) { [weak self] error in
            guard let error = error else { return }
            
            self?.presentTTAlert(title: "Update User Error", message: error.rawValue, buttonTitle: "Ok")
        }
        
        dismiss(animated: true)
    }
}

//MARK: - FriendRequestCellDelegate
extension FriendsAndRequestsVC: FriendRequestCellDelegate {
    func clickedFriendRequestActionButton(result: Result<Void, TTError>) {
        switch result {
        case .success(_):
            print("Friends count: \(friends.count)")
            DispatchQueue.main.async {
                self.reloadTable()
            }
        case .failure(let error):
            self.presentTTAlert(title: "Friend Request Action Error", message: error.rawValue, buttonTitle: "Ok")
        }
    }
}


