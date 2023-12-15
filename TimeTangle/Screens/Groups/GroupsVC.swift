//
//  GroupsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit
import SwiftUI

class GroupsVC: UIViewController {
    
    private var groups = [TTGroup]()
    private var updatedGroups = Set<TTGroup>()
    private var groupsCache = TTCache<String, TTGroup>()
    private var groupUsersCache: TTCache<String, TTUser>!
    
    private let groupsTable = UITableView()
    private let refreshControl = UIRefreshControl()
    
    private var selectedVCIndex: Int?
    
    init(usersCache: TTCache<String, TTUser>) {
        self.groupUsersCache = usersCache
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureGroupsTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
        fetchGroups()
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        
        NotificationCenter.default.addObserver(self, selector: #selector(getUpdatedGroups(_:)), name: .updatedCurrentUserGroups, object: nil)
        configureDismissEditingTapGestureRecognizer()
        
        let showGroupPresetsViewButton = UIBarButtonItem(image: UIImage(systemName: "person.3"), style: .plain, target: self, action: #selector(showGroupPresetsView))
        showGroupPresetsViewButton.tintColor = .systemGreen
        
        if FirebaseManager.shared.storeViewModel.isSubscriptionPro {
            navigationItem.rightBarButtonItem = showGroupPresetsViewButton
        }
    }
    
    @objc private func showGroupPresetsView() {
        let friendsGroupPresetsViewHostingController = UIHostingController(rootView: GroupPresetsView())
        present(friendsGroupPresetsViewHostingController, animated: true)
    }
    
    private func configureGroupsTable() {
        view.addSubview(groupsTable)
        groupsTable.translatesAutoresizingMaskIntoConstraints = false
        groupsTable.separatorStyle = .none
        groupsTable.delegate = self
        groupsTable.dataSource = self
        groupsTable.register(GroupViewCell.self, forCellReuseIdentifier: GroupViewCell.reuseID)
        
        NSLayoutConstraint.activate([
            groupsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            groupsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            groupsTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            groupsTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10)
        ])
    }
    
    @objc private func getUpdatedGroups(_ notification: Notification) {
        if let groupModifications = notification.object as? [TTGroupModification] {
            
            if groupModifications.count != 1 {
                groups.removeAll()
            }
            
            for groupModification in groupModifications {
                let modifiedGroup = groupModification.group
                let removeIndex = groups.firstIndex(of: modifiedGroup)
                
                if groupModification.modificationType == .removed, let removeIndex = removeIndex {
                    print("remove")
                    groups.remove(at: removeIndex)
                    groupsCache.removeValue(forKey: modifiedGroup.code)
                    return
                } else if groupModification.modificationType == .modified, let removeIndex = removeIndex {
                    print("modified")
                    groups[removeIndex] = modifiedGroup
                } else if groupModification.modificationType == .added && !groups.contains(where: { $0.code == modifiedGroup.code }) {
                    print("append")
                    groups.append(modifiedGroup)
                }
                
                groupsCache.removeValue(forKey: groupModification.group.code)
                groupsCache.insert(groupModification.group, forKey: groupModification.group.code)
            }
            
            updateGroupTableView()
        }
    }
    
    @objc private func fetchGroups() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        groupsTable.backgroundView = nil
        self.groups = []
        
        if currentUser.groupCodes.count > 0 {
            for groupCode in currentUser.groupCodes {
                retrieveOrFetchGroup(for: groupCode)
            }
        } else {
            updateGroupTableView()
        }
    }
    
    private func retrieveOrFetchGroup(for groupCode: String) {
        if let cachedGroup = groupsCache.value(forKey: groupCode) {
            groups.append(cachedGroup)
            groups.sort { $0.startingDate > $1.startingDate }
        } else {
            FirebaseManager.shared.fetchGroup(for: groupCode) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let group):
                    self.groups.append(group)
                    self.groups.sort { $0.startingDate > $1.startingDate }
                    self.groupsCache.insert(group, forKey: groupCode)
                    self.updateGroupTableView()
                case .failure(let error):
                    self.presentTTAlert(title: "Cannot fetch group", message: error.rawValue, buttonTitle: "Ok")
                }
            }
        }
    }
    
    private func updateGroupTableView() {
        if groups.isEmpty {
            groupsTable.backgroundView = TTEmptyStateView(message: "No Groups Found")
        } else {
            groupsTable.backgroundView = nil
        }
        
        DispatchQueue.main.async {
            self.groupsTable.reloadData()
        }
    }
}

//MARK: - Delegates
extension GroupsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = groupsTable.dequeueReusableCell(withIdentifier: GroupViewCell.reuseID) as! GroupViewCell
        let group = groups[indexPath.section]
        
        cell.set(for: group)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedGroup = groups[indexPath.section]
        let groupInfoVC = GroupDetailVC(group: selectedGroup, groupsUsersCache: groupUsersCache, nibName: "GroupDetailNib")
        selectedVCIndex = indexPath.section
    
        updateGroupTableView()
        
        navigationController?.pushViewController(groupInfoVC, animated: true)
    }
}
