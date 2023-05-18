//
//  SearchVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class SearchVC: UIViewController {
    
    var usersQueueForRoomCreation: [TTUser] = []
    
    var searchController: UISearchController!
    var searchFriendsResultController: SearchFriendsResultController!
    let usersQueueCountLabel = TTTitleLabel(textAlignment: .center, fontSize: 15)
    let usersQueueTable = UITableView()
    let createRoomButton = TTButton(backgroundColor: .systemGreen, title: "Create Room")

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureSearchController()
        configureUsersQueueCountLabel()
        configureCreateRoomButton()
        configureTableView()
        createDismissKeyboardTapGesture()
        addCurrentUser()
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        title = "Search"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        //Join Room Button
        let joinRoomButton = UIBarButtonItem(image: UIImage(systemName: "ipad.and.arrow.forward"), style: .plain, target: self, action: #selector(joinRoom))
        joinRoomButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = joinRoomButton
    }
    
    @objc private func joinRoom() {
        let joinRoomVC = JoinRoomVC()
        joinRoomVC.modalPresentationStyle = .overFullScreen
        joinRoomVC.modalTransitionStyle = .crossDissolve
        joinRoomVC.delegate = self
        self.present(joinRoomVC, animated: true)
    }
    
    
    private func configureSearchController() {
        searchFriendsResultController = SearchFriendsResultController()
       
        searchController = UISearchController(searchResultsController: searchFriendsResultController)
        
        //Place the search bar in the navigation bar
        navigationItem.searchController = searchController
        
        //Make the search bar always visible
        navigationItem.hidesSearchBarWhenScrolling = false
        
        //Monitor when the search controller is presented and dismissed
        searchController.delegate = self
        
        //Monitor when the search button is tapped, and start/end editing
        searchController.searchBar.delegate = self
        
        searchController.searchBar.placeholder = "Search for a friend"
        searchController.searchBar.isTranslucent = true 
        
        searchFriendsResultController.suggestedSearchDelegate = self
        searchFriendsResultController.searchVCRef = self
    }
    
    private func configureUsersQueueCountLabel() {
        view.addSubview(usersQueueCountLabel)
        usersQueueCountLabel.text = "1 Participant"
        usersQueueCountLabel.textColor = .secondaryLabel
        usersQueueCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            usersQueueCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            usersQueueCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            usersQueueCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            usersQueueCountLabel.heightAnchor.constraint(equalToConstant: 15)
        ])
    }
    
    private func updateUsersQueueCountLabel() {
        usersQueueCountLabel.text = "\(self.usersQueueForRoomCreation.count) Participant\(self.usersQueueForRoomCreation.count > 1 ? "s" : "")"
    }
    
    private func configureTableView() {
        view.addSubview(usersQueueTable)
        usersQueueTable.translatesAutoresizingMaskIntoConstraints = false
        usersQueueTable.separatorStyle = .none
        
        usersQueueTable.frame = CGRectMake(0, 100, view.bounds.width, view.bounds.height / 2.5)
        usersQueueTable.delegate = self
        usersQueueTable.dataSource = self
        
        usersQueueTable.register(ProfileUsernameCell.self, forCellReuseIdentifier: ProfileUsernameCell.reuseID)
        
        NSLayoutConstraint.activate([
            usersQueueTable.topAnchor.constraint(equalTo: usersQueueCountLabel.bottomAnchor, constant: 10),
            usersQueueTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            usersQueueTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            usersQueueTable.bottomAnchor.constraint(equalTo: createRoomButton.topAnchor, constant: -10)
        ])
    }
    
    private func configureCreateRoomButton() {
        view.addSubview(createRoomButton)
        createRoomButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            createRoomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createRoomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            createRoomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            createRoomButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func createRoom() {
        //make sure that we have more than self
        
        let createRoomConfirmationVC = CreateRoomConfirmationVC(users: usersQueueForRoomCreation)
        createRoomConfirmationVC.modalPresentationStyle = .overFullScreen
        createRoomConfirmationVC.modalTransitionStyle = .crossDissolve
        createRoomConfirmationVC.delegate = self
        createRoomConfirmationVC.createRoomConfirmationDelegate = self
        self.present(createRoomConfirmationVC, animated: true)
    }
    
    private func addCurrentUser() {
        if let currentUserUsername = FirebaseManager.shared.currentUser?.username  {
            FirebaseManager.shared.fetchUserDocumentData(with: currentUserUsername) { [weak self] result in
                switch result {
                case .success(let user):
                    self?.usersQueueForRoomCreation.append(user)
                    self?.refreshTableView()
                    break
                case .failure(_):
                    break
                }
            }
        }
    }
    
    private func refreshTableView() {
        DispatchQueue.main.async {
            self.usersQueueTable.reloadData()
            self.view.bringSubviewToFront(self.usersQueueTable)
        }
    }
    
    private func setToSuggestedSearches() {
        if searchController.searchBar.searchTextField.tokens.isEmpty {
            searchFriendsResultController.showSuggestedSearches = true
        }
    }
}

//MARK: - Delegates
extension SearchVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersQueueTable.dequeueReusableCell(withIdentifier: ProfileUsernameCell.reuseID) as! ProfileUsernameCell
        let userInQueue = usersQueueForRoomCreation[indexPath.section]
        cell.set(for: userInQueue.username)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return usersQueueForRoomCreation.count
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        
        let userInQueue = usersQueueForRoomCreation[indexPath.section]
        
        if userInQueue.username != FirebaseManager.shared.currentUser?.username {
            usersQueueForRoomCreation.remove(at: indexPath.section)
            usersQueueTable.beginUpdates()
            usersQueueTable.deleteSections([indexPath.section], with: .fade)
            usersQueueTable.endUpdates()
            updateUsersQueueCountLabel()
        }
    }
}

extension SearchVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchFriendsResultController.showSuggestedSearches = false
        searchFriendsResultController.search(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //User tapped the Done button on the keyboard
        searchController.dismiss(animated: true, completion: nil)
        searchBar.text = ""
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        setToSuggestedSearches()
        return true
    }
}

extension SearchVC: UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        searchController.showsSearchResultsController = true
        setToSuggestedSearches()
        searchFriendsResultController.getSuggestedSearches(withMaxCount: 3)
    }
}

//extension SearchVC: UISearchResultsUpdating {
//    func updateSearchResults(for searchController: UISearchController) {
//
//    }
//}

extension SearchVC: SearchFriendsResultControllerDelegate {
    func didSelectSuggestedSearch(for user: TTUser) {
        searchController.showsSearchResultsController = false
        searchController.dismiss(animated: true, completion: nil)
        
        usersQueueForRoomCreation.append(user)
        refreshTableView()
        updateUsersQueueCountLabel()
    }
}

extension SearchVC: CloseButtonDelegate, CreateRoomConfirmationVCDelegate {
    func didDismissPresentedView() {
        dismiss(animated: true)
    }
    
    func didSuccessfullyCreateRoom() {
        dismiss(animated: true)
    }
}



