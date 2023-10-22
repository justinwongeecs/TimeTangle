//
//  GroupsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit

class GroupsVC: UIViewController {
    
    private var groups = [TTGroup]()
    private var updatedGroups = Set<TTGroup>()
    private var groupsCache = TTCache<String, TTGroup>()
    private var groupUsersCache = TTCache<String, TTUser>()
    
    private let groupsTable = UITableView()
    private let refreshControl = UIRefreshControl()
    
    private var selectedVCIndex: Int?
    
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
                updateCurrentOccurrencesOfGroup(for: groupModification)
            }
            updateGroupTableView()
        }
    }
    
    private func updateCurrentOccurrencesOfGroup(for groupModification: TTGroupModification) {
        let removeIndex = groups.firstIndex(of: groupModification.group)
        
        if groupModification.modificationType == .removed, let removeIndex = removeIndex {
            print("remove")
            groups.remove(at: removeIndex)
            groupsCache.removeValue(forKey: groupModification.group.code)
            return
        } else if groupModification.modificationType == .modified, let removeIndex = removeIndex {
            print("modified")
            groups[removeIndex] = groupModification.group

            if var currentUpdatedGroupCodes = getUpdatedGroupCodesFromUserDefaults(), !currentUpdatedGroupCodes.contains(groupModification.group.code) {
                currentUpdatedGroupCodes.append(groupModification.group.code)
                saveUpdatedGroupCodesToUserDefaults(for: currentUpdatedGroupCodes)
            } else {
                saveUpdatedGroupCodesToUserDefaults(for: [groupModification.group.code])
            }
        } else {
            print("append")
            groups.append(groupModification.group)
        }
        
        groupsCache.removeValue(forKey: groupModification.group.code)
        groupsCache.insert(groupModification.group, forKey: groupModification.group.code)
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
    
    private func saveUpdatedGroupCodesToUserDefaults(for updatedGroupCodes: [String]) {
        UserDefaults.standard.set(updatedGroupCodes, forKey: TTConstants.userDefaultsUpdatedGroupCodes)
    }
    
    private func getUpdatedGroupCodesFromUserDefaults() -> [String]? {
        return UserDefaults.standard.stringArray(forKey: TTConstants.userDefaultsUpdatedGroupCodes)
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
        
        var isGroupUpdated = false
        
        if let updatedGroupCodes = getUpdatedGroupCodesFromUserDefaults() {
            print(updatedGroupCodes)
            isGroupUpdated = updatedGroupCodes.contains(group.code)
        }
        
        cell.set(for: group, isUpdated: isGroupUpdated)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedGroup = groups[indexPath.section]
        let groupInfoVC = GroupDetailVC(group: selectedGroup, groupsUsersCache: groupUsersCache, nibName: "GroupDetailNib")
        selectedVCIndex = indexPath.section
    
        if var currentUpdatedGroupCodes = getUpdatedGroupCodesFromUserDefaults(), let removeIndex = currentUpdatedGroupCodes.firstIndex(of: selectedGroup.code) {
            currentUpdatedGroupCodes.remove(at: removeIndex)
            saveUpdatedGroupCodesToUserDefaults(for: currentUpdatedGroupCodes)
        }
        
        updateGroupTableView()
        
        navigationController?.pushViewController(groupInfoVC, animated: true)
    }
}
