//
//  CreateRoomVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class CreateRoomVC: UIViewController {
    
    private var allFriends = [TTUser]()
    private var usersQueueForRoomCreation = [TTUser]()
    
    private var searchController: UISearchController!
    private var searchFriendsResultController: SearchFriendsResultController!
    
    private let usersQueueCountLabel = TTTitleLabel(textAlignment: .center, fontSize: 15)
    private let usersQueueTable = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let createRoomButton = TTButton(backgroundColor: .systemGreen, title: "Create Room")

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureSearchController()
        configureUsersQueueCountLabel()
        configureCreateRoomButton()
        configureTableView()
        configureActivityIndicator()
        createDismissKeyboardTapGesture()
        
        addCurrentUser()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser), name: .updatedUser, object: nil)
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        title = "Create Room"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        //Join Room Button
        let joinRoomButton = UIBarButtonItem(image: UIImage(systemName: "ipad.and.arrow.forward"), style: .plain, target: self, action: #selector(joinRoom))
        joinRoomButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = joinRoomButton
    }
    
    @objc private func joinRoom() {
        let joinRoomVC = JoinRoomVC() { [weak self] in
            self?.dismiss(animated: true)
        }
        joinRoomVC.modalPresentationStyle = .overFullScreen
        joinRoomVC.modalTransitionStyle = .crossDissolve
        self.present(joinRoomVC, animated: true)
    }
    
    @objc private func fetchUpdatedUser() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        activityIndicator.startAnimating()
        if !currentUser.friends.isEmpty  {
            FirebaseManager.shared.fetchMultipleUsersDocumentData(with: currentUser.friends) { [weak self] result in
                self?.activityIndicator.stopAnimating()
                guard let self = self else { return }
                switch result {
                case .success(let allFriends):
                    self.allFriends = allFriends
                    let usersQueueUsernames = self.usersQueueForRoomCreation.map{ $0.username }
                    self.usersQueueForRoomCreation.append(contentsOf: allFriends.filter { usersQueueUsernames.contains($0.username) })
                    self.refreshTableView()
                case .failure(let error):
                    self.presentTTAlert(title: "Fetch Error", message: error.rawValue, buttonTitle: "OK")
                }
            }
        } else {
            activityIndicator.stopAnimating()
        }
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
            usersQueueCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
        
        usersQueueTable.register(CreateRoomUserQueueCell.self, forCellReuseIdentifier: CreateRoomUserQueueCell.getReuseID())
        
        NSLayoutConstraint.activate([
            usersQueueTable.topAnchor.constraint(equalTo: usersQueueCountLabel.bottomAnchor, constant: 10),
            usersQueueTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            usersQueueTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            usersQueueTable.bottomAnchor.constraint(equalTo: createRoomButton.topAnchor, constant: -10)
        ])
    }
    
    private func configureActivityIndicator() {
        activityIndicator.color = .lightGray
        activityIndicator.center = CGPoint(x: usersQueueTable.bounds.width / 2, y: activityIndicator.bounds.height / 2)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        usersQueueTable.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: usersQueueTable.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: usersQueueTable.centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 20),
            activityIndicator.heightAnchor.constraint(equalToConstant: 20)
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
        let createRoomConfirmationVC = CreateRoomConfirmationVC(users: usersQueueForRoomCreation) { [weak self] in
            self?.dismiss(animated: true)
        }
        createRoomConfirmationVC.modalPresentationStyle = .overFullScreen
        createRoomConfirmationVC.modalTransitionStyle = .crossDissolve
        createRoomConfirmationVC.createRoomConfirmationDelegate = self
        self.present(createRoomConfirmationVC, animated: true)
    }
    
    private func addCurrentUser() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        usersQueueForRoomCreation.append(currentUser)
        refreshTableView()
    }
    
    private func refreshTableView() {
        DispatchQueue.main.async {
            self.usersQueueTable.reloadData()
            self.view.bringSubviewToFront(self.usersQueueTable)
        }
    }
    
    func getUsersQueueForRoomCreation() -> [TTUser] {
        return usersQueueForRoomCreation
    }
}

//MARK: - Delegates
extension CreateRoomVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersQueueTable.dequeueReusableCell(withIdentifier: CreateRoomUserQueueCell.getReuseID()) as! CreateRoomUserQueueCell
        let userInQueue = usersQueueForRoomCreation[indexPath.section]
        cell.set(for: userInQueue) {
            if userInQueue.username != FirebaseManager.shared.currentUser?.username {
                self.usersQueueForRoomCreation.remove(at: indexPath.section)
                self.usersQueueTable.beginUpdates()
                self.usersQueueTable.deleteSections([indexPath.section], with: .fade)
                self.usersQueueTable.endUpdates()
                self.updateUsersQueueCountLabel()
            }
        }
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
}

extension CreateRoomVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchFriendsResultController.search(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //User tapped the Done button on the keyboard
        searchController.dismiss(animated: true, completion: nil)
        searchBar.text = ""
    }
}

extension CreateRoomVC: UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        searchController.showsSearchResultsController = true
        searchFriendsResultController.setAllFriends(with: allFriends)
    }
}

extension CreateRoomVC: SearchFriendsResultControllerDelegate {
    func didSelectSuggestedSearch(for user: TTUser) {
        searchController.showsSearchResultsController = false
        searchController.dismiss(animated: true, completion: nil)
        
        usersQueueForRoomCreation.append(user)
        refreshTableView()
        updateUsersQueueCountLabel()
    }
}

extension CreateRoomVC: CreateRoomConfirmationVCDelegate {
    func didSuccessfullyCreateRoom() {
        usersQueueForRoomCreation = []
        addCurrentUser()
        updateUsersQueueCountLabel()
        dismiss(animated: true)
    }
}



