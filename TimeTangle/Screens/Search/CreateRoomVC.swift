//
//  CreateGroupVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class CreateGroupVC: UIViewController {
    
    private var allFriends = [TTUser]()
    private var usersQueueCache = TTCache<String, TTUser>()
    private var usersQueueForGroupCreation = [TTUser]()
    
    private var searchController: UISearchController!
    private var searchFriendsResultController: SearchFriendsResultController!
    
    private let usersQueueCountLabel = TTTitleLabel(textAlignment: .center, fontSize: 15)
    private let usersQueueTable = UITableView()
    private let createGroupButton = TTButton(backgroundColor: .systemGreen, title: "Create Group")

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureSearchController()
        configureUsersQueueCountLabel()
        configureCreateGroupButton()
        configureTableView()
        createDismissKeyboardTapGesture()
        
        addCurrentUser()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser), name: .updatedUser, object: nil)
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        title = "Create Group"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        //Join Group Button
        let joinGroupButton = UIBarButtonItem(image: UIImage(systemName: "ipad.and.arrow.forward"), style: .plain, target: self, action: #selector(joinGroup))
        joinGroupButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = joinGroupButton
    }
    
    @objc private func joinGroup() {
        let joinGroupVC = JoinGroupVC() { [weak self] in
            self?.dismiss(animated: true)
        }
        joinGroupVC.modalPresentationStyle = .overFullScreen
        joinGroupVC.modalTransitionStyle = .crossDissolve
        self.present(joinGroupVC, animated: true)
    }
    
    @objc private func fetchUpdatedUser() {   
        if !usersQueueForGroupCreation.isEmpty {
            FirebaseManager.shared.fetchMultipleUsersDocumentData(with: usersQueueForGroupCreation.map{ $0.username }) { [weak self] result in
                switch result {
                case .success(let users):
                    self?.usersQueueForGroupCreation = users
                    self?.refreshTableView()
                case .failure(let error):
                    self?.presentTTAlert(title: "Fetch Error", message: error.rawValue, buttonTitle: "OK")
                }
            }
        }
    }
    
    private func configureSearchController() {
        searchFriendsResultController = SearchFriendsResultController(usersInQueueCache: usersQueueCache)
       
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
        searchController.searchBar.tintColor = .systemGreen
        
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
        usersQueueCountLabel.text = "\(self.usersQueueForGroupCreation.count) Participant\(self.usersQueueForGroupCreation.count > 1 ? "s" : "")"
    }
    
    private func configureTableView() {
        view.addSubview(usersQueueTable)
        usersQueueTable.translatesAutoresizingMaskIntoConstraints = false
        usersQueueTable.separatorStyle = .none
        
        usersQueueTable.frame = CGRectMake(0, 100, view.bounds.width, view.bounds.height / 2.5)
        usersQueueTable.delegate = self
        usersQueueTable.dataSource = self
        
        usersQueueTable.register(CreateGroupUserQueueCell.self, forCellReuseIdentifier: CreateGroupUserQueueCell.getReuseID())
        
        NSLayoutConstraint.activate([
            usersQueueTable.topAnchor.constraint(equalTo: usersQueueCountLabel.bottomAnchor, constant: 10),
            usersQueueTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            usersQueueTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            usersQueueTable.bottomAnchor.constraint(equalTo: createGroupButton.topAnchor, constant: -10)
        ])
    }
    
    private func configureCreateGroupButton() {
        view.addSubview(createGroupButton)
        createGroupButton.addTarget(self, action: #selector(createGroup), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            createGroupButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createGroupButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            createGroupButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            createGroupButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func createGroup() {
        let createGroupConfirmationVC = CreateGroupConfirmationVC(users: usersQueueForGroupCreation) { [weak self] in
            self?.dismiss(animated: true)
        }
        createGroupConfirmationVC.modalPresentationStyle = .overFullScreen
        createGroupConfirmationVC.modalTransitionStyle = .crossDissolve
        createGroupConfirmationVC.createGroupConfirmationDelegate = self
        self.present(createGroupConfirmationVC, animated: true)
    }
    
    private func addCurrentUser() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        usersQueueForGroupCreation.append(currentUser)
        refreshTableView()
    }
    
    private func refreshTableView() {
        DispatchQueue.main.async {
            self.usersQueueTable.reloadData()
            self.view.bringSubviewToFront(self.usersQueueTable)
        }
    }
    
    func getUsersQueueForGroupCreation() -> [TTUser] {
        return usersQueueForGroupCreation
    }
}

//MARK: - Delegates
extension CreateGroupVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersQueueTable.dequeueReusableCell(withIdentifier: CreateGroupUserQueueCell.getReuseID()) as! CreateGroupUserQueueCell
        let userInQueue = usersQueueForGroupCreation[indexPath.section]
        cell.set(for: userInQueue) {
            if userInQueue.username != FirebaseManager.shared.currentUser?.username {
                self.usersQueueForGroupCreation.remove(at: indexPath.section)
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
        return usersQueueForGroupCreation.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 5))
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TTConstants.defaultCellHeaderAndFooterHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return TTConstants.defaultCellHeaderAndFooterHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TTConstants.defaultCellHeight
    }
}

extension CreateGroupVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchFriendsResultController.search(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //User tapped the Done button on the keyboard
        searchController.dismiss(animated: true, completion: nil)
    }
}

extension CreateGroupVC: UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        searchController.showsSearchResultsController = true
    }
}

extension CreateGroupVC: SearchFriendsResultControllerDelegate {
    func didSelectSuggestedSearch(for user: TTUser) {
        searchController.showsSearchResultsController = false
        searchController.dismiss(animated: true, completion: nil)
        
        usersQueueForGroupCreation.append(user)
        refreshTableView()
        updateUsersQueueCountLabel()
    }
}

extension CreateGroupVC: CreateGroupConfirmationVCDelegate {
    func didSuccessfullyCreateGroup() {
        usersQueueForGroupCreation = []
        addCurrentUser()
        updateUsersQueueCountLabel()
        dismiss(animated: true)
    }
}



