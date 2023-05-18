//
//  FriendsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/25/22.
//

import UIKit

class FriendsVC: UIViewController {
    
    let searchBarField = UISearchBar()    
    let friendsAndRequestsView = UIView()
    let friendsAndRequestsVC = FriendsAndRequestsVC()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureSearchArea()
        configureFriendsAndRequestsView()
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        title = "Friends"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addFriendButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFriend))
        addFriendButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = addFriendButton
    }

    
    @objc private func addFriend() {
        //show modal UI to add friend
        let destVC = AddFriendVC()
        destVC.delegate = friendsAndRequestsVC
        destVC.friendsAndRequestsVCRef = friendsAndRequestsVC
        let navController = UINavigationController(rootViewController: destVC)
        present(navController, animated: true)
    }
    
    private func configureSearchArea() {
        view.addSubview(searchBarField)
        searchBarField.delegate = self
        searchBarField.autocorrectionType = .no
        searchBarField.searchBarStyle = .minimal
        searchBarField.translatesAutoresizingMaskIntoConstraints = false
        searchBarField.placeholder = "Search for Friend"
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
    
    //don't think this is necessary since we aren't using a search controller
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //user tapped the Done button on the keyboard
        //filter friends
    }
}


