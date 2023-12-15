//
//  GroupDetailVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/30/22.
//

import UIKit
import CalendarKit
import FirebaseFirestore

protocol GroupUpdateDelegate: AnyObject {
    func groupDidUpdate(for group: TTGroup, showSaveOrCancel: Bool)
    func groupAddHistory(of editType: TTGroupEditType, before: String?, after: String?)
    func groupUserVisibilityDidUpdate(for id: String)
}

extension GroupUpdateDelegate {
    func groupUserVisibilityDidUpdate(for id: String) {}
}

class GroupDetailVC: UIViewController {
    
    @IBOutlet weak var usersCountButton: UIButton!
    @IBOutlet weak var startingDatePicker: UIDatePicker!
    @IBOutlet weak var endingDatePicker: UIDatePicker!
    @IBOutlet weak var aggregateResultView: UIView!
    
    private var groupAggregateVC: GroupAggregateResultVC!
    private var groupUsersVC: GroupUsersVC!
    private var group: TTGroup!
    private var groupHistoryVC: GroupHistoryVC!
    private var groupOverviewVC: GroupOverviewVC!
    private var confirmGroupChangesContainerView: UIView!
    private var saveOrCancelIsland: SaveOrCancelIsland!
    
    private var groupMembers = [TTUser]()
    private var groupsUsersCache: TTCache<String, TTUser>!
    private var originalGroupState: TTGroup!
    private var openIntervals = [TTEvent]()
    private var isPresentingGroupChangesView: Bool = false
    
    //filters displaying users
    var usersNotVisible = [String]()
    
    init(group: TTGroup, groupsUsersCache: TTCache<String, TTUser>, nibName: String) {
        super.init(nibName: nibName, bundle: nil)
        self.group = group
        self.groupsUsersCache = groupsUsersCache
        title = "\(group.name)"
        originalGroupState = group
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        configureNavigationBarItems()
        configureGroupAggregateResultView()
        configureSaveOrCancelIsland()
        updateView()
        loadGroupUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
//    private func configureAdminEnability() {
//        guard let currentUser = FirebaseManager.shared.currentUser else { return }
//        if !group.doesContainsAdmin(for: currentUser.id) {
//            startingDatePicker.isEnabled = false
//            startingDatePicker.isUserInteractionEnabled = false
//            endingDatePicker.isEnabled = false
//            endingDatePicker.isUserInteractionEnabled = false
//        } else {
//            startingDatePicker.isEnabled = true
//            startingDatePicker.isUserInteractionEnabled = true
//            endingDatePicker.isEnabled = true
//            endingDatePicker.isUserInteractionEnabled = true
//        }
//    }
    
    //MARK: - Load Group Users
    private func loadGroupUsers() {
        for id in group.users {
            if let cachedUser = groupsUsersCache[id] {
                groupMembers.append(cachedUser)
            } else {
                fetchGroupTTUser(for: id)
            }
        }
    }
    
    private func fetchGroupTTUser(for id: String) {
        FirebaseManager.shared.fetchUserDocumentData(with: id) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let ttUser):
                self.groupMembers.append(ttUser)
                self.groupsUsersCache.insert(ttUser, forKey: ttUser.id)
                self.groupAggregateVC.setView(usersNotVisible: usersNotVisible, group: group)
            case .failure(let error):
                self.presentTTAlert(title: "Fetch Error", message: error.rawValue, buttonTitle: "OK")
            }
        }
    }
    
    //MARK: - NavigationBarItems
    private func configureNavigationBarItems() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .systemGreen
        
        let infoButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(clickedOnViewResultButton))
        
        let groupMoreMenu = UIMenu(title: "", children: [
            UIAction(title: "Add User", image: UIImage(systemName: "person.badge.plus")) { [weak self] action in
                self?.showAddUserModal()
            },
            
            UIAction(title: "Show Group History", image: UIImage(systemName: "clock")) { [weak self] action in
                self?.showGroupHistoryVC()
            },
            
            UIAction(title: "Sync Calendar", image: UIImage(systemName: "calendar")) { [weak self] action in
                self?.syncUserCalendar()
            },
            
            UIAction(title: "Group Settings", image: UIImage(systemName: "gear")) { [weak self] action in
                self?.showGroupSettingsVC()
            }
        ])
        
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), primaryAction: nil, menu: groupMoreMenu)
        
        infoButton.tintColor = .systemGreen
        sortButton.tintColor = .systemGreen
        
        navigationItem.rightBarButtonItems = [sortButton, infoButton]
    }
    
    private func configureGroupAggregateResultView() {
        groupAggregateVC = GroupAggregateResultVC(group: group, groupsUsersCache: groupsUsersCache, usersNotVisible: usersNotVisible)
        groupAggregateVC.groupAggregateResultDelegate = self
        add(childVC: groupAggregateVC, to: aggregateResultView)
    }
    
    @objc private func showAddUserModal() {
        let destVC = AddUsersModalVC(group: group) { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        } addUserCompletionHandler: { [weak self] user in
            self?.addUserCompletionHandler(user: user)
        }
        
        destVC.modalPresentationStyle = .overFullScreen
        destVC.modalTransitionStyle = .crossDissolve
        self.present(destVC, animated: true)
    }
    
    private func addUserCompletionHandler(user: TTUser) {
        let updatedGroupFields = [
            TTConstants.groupUsers: FieldValue.arrayUnion([user.id])
        ]
        
        FirebaseManager.shared.updateGroup(for: self.group.code, with: updatedGroupFields) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.presentTTAlert(title: "Error updating group", message: error.rawValue, buttonTitle: "Ok")
            } else {
                //update added user groupcodes field
                FirebaseManager.shared.updateUserData(for: user.id, with: [
                    TTConstants.groupCodes: FieldValue.arrayUnion([self.group.code])
                ]) { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        self.presentTTAlert(title: "Cannot add user to group", message: error.rawValue, buttonTitle: "OK")
                    } else {
                        //add to group edit history
                        self.addGroupHistory(of: .addedUserToGroup, after: user.getFullName())
                        self.group.users.append(user.id)
                        DispatchQueue.main.async {
                            self.updateView()
                        }
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    @objc private func showGroupHistoryVC() {
        groupHistoryVC = GroupHistoryVC(group: group, groupUsers: groupMembers)
        navigationController?.pushViewController(groupHistoryVC, animated: true)
    }
    
    private func renameGroup() {
        let alertController = UIAlertController(title: "Rename Group", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { [weak self] textField in
            guard let self = self else { return }
            textField.placeholder = "\(self.group.name)"
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            if let newGroupName = alertController.textFields?.first?.text {
                FirebaseManager.shared.updateGroup(for: self.group.code, with: [
                    TTConstants.groupName: newGroupName
                ]) { [weak self] error in
                    guard let error = error else {
                        self?.title = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                        return
                    }
                    self?.presentTTAlert(title: "Fetch Group Error", message: error.rawValue, buttonTitle: "OK")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true )
    }
    
    @objc private func syncUserCalendar() {
        //Fetch current user's events within group time frame
        let ekManager = EventKitManager.shared
        
        Task {
            do {
                try await ekManager.setupEventStore()
                
                let userEventsWithinGroupRangeSet = Set(ekManager.getUserTTEvents(from: group.startingDate, to: group.endingDate))
                let currGroupEventsSet = Set(group.events)
                let unionGroupEvents = Array(currGroupEventsSet.union(userEventsWithinGroupRangeSet))

                group.events = unionGroupEvents
                print("Group Events: \(unionGroupEvents)")
                updateGroupAggregateVC()
            
                let syncUserCalendarSaveOrCancelIsland = SaveOrCancelIsland(parentVC: self) { [weak self] in
                    print("Save Calendar")
                    self?.updateGroupEventsWithCurrentUserEvents(with: unionGroupEvents)
                    self?.addGroupHistory(of: .userSynced)
                }
                syncUserCalendarSaveOrCancelIsland.delegate = self
                view.addSubview(syncUserCalendarSaveOrCancelIsland)
                
                syncUserCalendarSaveOrCancelIsland.present()
            } catch {
                let ac = UIAlertController(title: "Calendar Authorization Error", message: error.localizedDescription, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(ac, animated: true)
            }
        }
    }
    
    private func updateGroupEventsWithCurrentUserEvents(with currUserEvents: [TTEvent]) {
        FirebaseManager.shared.updateGroup(for: group.code, with: [
            TTConstants.groupEvents: currUserEvents.getFirestoreDictionaries()
        ]) { error in
            if let error = error  {
                self.presentTTAlert(title: "Cannot Sync Calendar", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    private func showGroupSettingsVC() {
        let config = Configuration()
        let groupSettingsView = GroupSettingsView(group: group, config: config) { [weak self] newGroup in
            self?.group = newGroup
            DispatchQueue.main.async {
                self?.updateView()
            }
        } popUIViewController: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        let groupSettingsHostingController = TTHostingController(rootView: groupSettingsView)
        config.hostingController = groupSettingsHostingController
        present(groupSettingsHostingController, animated: true)
    }

    @objc private func refreshGroup() {
        //Update Group Code, Starting and Ending Dates
        let updateFields = [
            TTConstants.groupStartingDate: startingDatePicker.date,
            TTConstants.groupEndingDate: endingDatePicker.date
        ]
        
        FirebaseManager.shared.updateGroup(for: group.code, with: updateFields) { [weak self] error in
            guard let error = error else { return }
            self?.presentTTAlert(title: "Cannot change starting date", message: error.rawValue, buttonTitle: "Ok")
        }
    }
    
    @objc func clickedOnViewResultButton(_ sender: UIButton) {
        //show summary view
        groupOverviewVC = GroupOverviewVC(
            group: group,
            groupsUsersCache: groupsUsersCache,
            notVisibleMembers: usersNotVisible,
            openIntervals: openIntervals
        )
        navigationController?.pushViewController(groupOverviewVC, animated: true)
    }
    
    private func updateView() {
        title = group.name
        usersCountButton.setTitle("\(group.users.count) \(group.users.count > 1 ? "Members" : "Member")", for: .normal)
        startingDatePicker.date = group.startingDate
        startingDatePicker.isEnabled = !group.setting.lockGroupChanges
        startingDatePicker.minimumDate = group.setting.boundedStartDate
        startingDatePicker.maximumDate = group.setting.boundedEndDate
        
        endingDatePicker.date = group.endingDate
        endingDatePicker.isEnabled = !group.setting.lockGroupChanges
        endingDatePicker.minimumDate = group.setting.boundedStartDate
        endingDatePicker.maximumDate = group.setting.boundedEndDate
    }
    
    private func configureSaveOrCancelIsland() {
        saveOrCancelIsland = SaveOrCancelIsland(parentVC: self) { [weak self] in
            self?.generalGroupSave()
        }
        saveOrCancelIsland.delegate = self
        view.addSubview(saveOrCancelIsland)
    }

    private func updateSaveOrCancelIsland() {
        if group == originalGroupState {
            //Dismiss
            saveOrCancelIsland.dismiss()
        } else if group != originalGroupState {
            //Present
            saveOrCancelIsland.present()
        }
    }
    
    //MARK: - IBAction Buttons
    
    //push new view controller to display list of members view
    @IBAction func clickedUsersCountButton(_ sender: UIButton) {
        groupUsersVC = GroupUsersVC(group: group, groupUsersCache: groupsUsersCache, usersNotVisible: usersNotVisible)
        groupUsersVC.delegate = self
        navigationController?.pushViewController(groupUsersVC, animated: true)
    }
    
    @IBAction func startingDateChanged(_ sender: UIDatePicker) {
        //check to see if starting date is after ending date
        guard sender.date <= endingDatePicker.date else {
            //dismiss UIDatePickerContainerViewController
            dismiss(animated: true)
            presentTTAlert(title: "Invalid Starting Date", message: "Starting date cannot be after ending date", buttonTitle: "Ok")
            sender.date = group.startingDate
            return
        }
        group.startingDate = sender.date
      
        updateGroupAggregateVC()
        updateSaveOrCancelIsland()
    }
    
    @IBAction func endingDateChanged(_ sender: UIDatePicker) {
        //check to see if ending date is before starting date
        guard sender.date >= startingDatePicker.date else {
            //dismiss UIDatePickerContainerViewController
            dismiss(animated: true)
            presentTTAlert(title: "Invalid Ending Date", message: "Ending date cannot be before starting date", buttonTitle: "Ok")
            sender.date = group.endingDate
            return
        }
        group.endingDate = sender.date

        updateGroupAggregateVC()
        updateSaveOrCancelIsland()
    }
    
    //Should be triggered after every group edit
    private func addGroupHistory(of editType: TTGroupEditType, before: String? = nil, after: String? = nil) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        let editDifference = TTGroupEditDifference(before: before, after: after)
        let newGroupEdit = TTGroupEdit(author: currentUser.getFullName(), authorID: currentUser.id, createdDate: Date(), editDifference: editDifference, editType: editType)
        group.histories.append(newGroupEdit)
        do {
            let newGroupHistory = try Firestore.Encoder().encode(newGroupEdit) 
            FirebaseManager.shared.updateGroup(for: group.code, with: [
                TTConstants.groupHistories: FieldValue.arrayUnion([newGroupHistory])
            ]) { [weak self] error in
                guard let error = error else { return }
                self?.presentTTAlert(title: "Cannot add group history", message: error.rawValue, buttonTitle: "Ok")
            }
        } catch {
            //Do error catching here
            presentTTAlert(title: "Cannot add group history", message: TTError.unableToAddGroupHistory.rawValue, buttonTitle: "Ok")
        }
    }
    
    private func updateGroupAggregateVC() {
        //filter and or add to group.events so that between startDate and endDate
        group.events = group.events.filter { $0.startDate >= startingDatePicker.date && $0.endDate <= endingDatePicker.date }
        groupAggregateVC.setView(usersNotVisible: usersNotVisible, group: group)
    }
    
    //MARK: - Getters and Setters
    public func setGroupHistories(with histories: [TTGroupEdit]) {
        group.histories = histories
    }
    
    private func generalGroupSave() {
        if !group.setting.lockGroupChanges {
            
            let previousStartingDate = originalGroupState.startingDate
            let previousEndingDate = originalGroupState.endingDate
            
            FirebaseManager.shared.updateGroup(for: group.code, with: [
                TTConstants.groupStartingDate: group.startingDate,
                TTConstants.groupEndingDate: group.endingDate,
                TTConstants.groupEvents: group.events.getFirestoreDictionaries()
            ]) { [weak self] error in
                guard let self = self else { return }
                guard let error = error  else {
                    let dateFormat = "MMM d y, h:mm a"
                    
                    if group.startingDate != previousStartingDate {
                        self.addGroupHistory(of: .changedStartingDate, before: previousStartingDate.formatted(with: dateFormat), after: self.group.startingDate.formatted(with: dateFormat))
                        
                        //If new group starting date is "greater" than prior, jump to the new date (irrespective of the ending date)
                        if group.startingDate > previousEndingDate {
                            groupAggregateVC.move(to: group.startingDate)
                        }
                    }
                    
                    if group.endingDate != previousEndingDate {
                        self.addGroupHistory(of: .changedEndingDate, before: previousEndingDate.formatted(with: dateFormat), after: self.group.endingDate.formatted(with: dateFormat))
                    }
            
                    DispatchQueue.main.async {
                        self.saveOrCancelIsland.dismiss()
                    }
                    return
                }
                self.presentTTAlert(title: "Cannot change ending date", message: error.rawValue, buttonTitle: "Ok")
            }
        } else {
            presentTTAlert(title: "Cannot Save Group", message: "Group setting \"Lock Group Changes\" is set to true. This group cannot be edited", buttonTitle: "OK")
        }
    }
}

//MARK: - Delegates
extension GroupDetailVC: GroupAggregateResultVCDelegate {
    func updatedAggregateResultVC(ttEvents: [TTEvent]) {
        openIntervals = ttEvents
    }
}

extension GroupDetailVC: GroupUpdateDelegate {
    func groupDidUpdate(for group: TTGroup, showSaveOrCancel: Bool = false) {
        self.group = group
        updateView()
        updateGroupAggregateVC()
        
        if showSaveOrCancel {
            updateSaveOrCancelIsland()
        }
    }
    
    func groupUserVisibilityDidUpdate(for id: String) {
        if usersNotVisible.contains(id), let removeIndex = usersNotVisible.firstIndex(of: id) {
            usersNotVisible.remove(at: removeIndex)
        } else {
            usersNotVisible.append(id)
        }
        updateGroupAggregateVC()
    }
    
    func groupAddHistory(of editType: TTGroupEditType, before: String? = nil, after: String? = nil) {
        addGroupHistory(of: editType, before: before, after: after)
    }
}

extension GroupDetailVC: SaveOrCancelIslandDelegate {
    func didCancelIsland() {
        group = originalGroupState
        updateView()
        updateGroupAggregateVC()
    }
}

