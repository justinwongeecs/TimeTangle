//
//  FriendsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/25/22.
//

import UIKit
import SwiftUI

class FriendsVC: UIViewController {
    private var storeViewModel: StoreViewModel
    
    private let searchBarField = UISearchBar()
    private let friendsAndRequestsView = UIView()
    private var friendsAndRequestsVC: FriendsAndRequestsVC!
    
    init(storeViewModel: StoreViewModel) {
        self.storeViewModel = storeViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureSearchArea()
        configureFriendsAndRequestsView()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        friendsAndRequestsVC.setTableViewEditing(to: editing)
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        title = "Friends"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        configureNavBar()
        configureDismissEditingTapGestureRecognizer()
    }
    
    private func configureNavBar() {
        let showGroupPresetsViewButton = UIBarButtonItem(image: UIImage(systemName: "person.3"), style: .plain, target: self, action: #selector(showGroupPresetsView))
        showGroupPresetsViewButton.tintColor = .systemGreen
        
        let addFriendButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFriend))
        addFriendButton.tintColor = .systemGreen
        
        //TODO: Change This Back Later 
//        if storeViewModel.isSubscriptionPro {
            navigationItem.rightBarButtonItems = [addFriendButton, showGroupPresetsViewButton]
//        } else {
//            navigationItem.rightBarButtonItem = addFriendButton
//        }
    }
    
    @objc private func showGroupPresetsView() {
        let mockData = [TTGroupPreset(name: "Group 1", users: [
            TTUser(firstname: "Justin", lastname: "Wong", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
        ]),
        TTGroupPreset(name: "Group 2", users: [
            TTUser(firstname: "Justin", lastname: "Wong", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", username: "jwongeecs", uid: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [])
        ])]
        let friendsGroupPresetsViewHostingController = UIHostingController(rootView: FriendsGroupPresetsView(groupPresets: mockData))
        present(friendsGroupPresetsViewHostingController, animated: true)
    }
    
    @objc private func addFriend() {
        let ac = UIAlertController(title: "Enter Friend Username", message: nil, preferredStyle: .alert)
        ac.view.tintColor = .systemGreen
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Send Request", style: .default) { [unowned ac] _ in
            let friendUsername = ac.textFields![0].text ?? ""
            
            if friendUsername.isEmpty {
                self.presentTTAlert(title: "Username Cannot Be Empty", message: "Please enter a valid username", buttonTitle: "OK")
            } else {
                FirebaseManager.shared.fetchUserDocumentData(with: friendUsername) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let user):
                        print(user)
                        friendsAndRequestsVC.selectedUserToAddFriend(for: user)
                    case .failure(let error):
                        presentTTAlert(title: "Cannot Find User", message: error.localizedDescription, buttonTitle: "OK")
                    }
                }
            }
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
    
    private func configureSearchArea() {
        view.addSubview(searchBarField)
        searchBarField.delegate = self
        searchBarField.autocorrectionType = .no
        searchBarField.searchBarStyle = .minimal
        searchBarField.tintColor = .systemGreen
        searchBarField.translatesAutoresizingMaskIntoConstraints = false
        searchBarField.placeholder = "Search for friend"
        searchBarField.autocapitalizationType = .none
        
        //Constraints for searchUserField in relationship to searchArea
        NSLayoutConstraint.activate([
            searchBarField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBarField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            searchBarField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            searchBarField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    
    private func configureFriendsAndRequestsView() {
        friendsAndRequestsVC = FriendsAndRequestsVC(searchBar: searchBarField)
        view.addSubview(friendsAndRequestsView)
        friendsAndRequestsView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            friendsAndRequestsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            friendsAndRequestsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            friendsAndRequestsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            friendsAndRequestsView.topAnchor.constraint(equalTo: searchBarField.bottomAnchor, constant: 10)
        ])

        add(childVC: friendsAndRequestsVC, to: friendsAndRequestsView)
    }
}

//MARK: - Delegates
extension FriendsVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        friendsAndRequestsVC.filterFriends(with: searchText)
    }
}


