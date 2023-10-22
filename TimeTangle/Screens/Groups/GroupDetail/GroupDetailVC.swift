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
    func groupDidUpdate(for group: TTGroup)
    func groupUserVisibilityDidUpdate(for username: String)
}

extension GroupUpdateDelegate {
    func groupUserVisibilityDidUpdate(for username: String) {}
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
//        if !group.doesContainsAdmin(for: currentUser.username) {
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
        for username in group.users {
            if let cachedUser = groupsUsersCache[username] {
                groupMembers.append(cachedUser)
            } else {
                fetchGroupTTUser(for: username)
            }
        }
    }
    
    private func fetchGroupTTUser(for username: String) {
        FirebaseManager.shared.fetchUserDocumentData(with: username) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let ttUser):
                self.groupMembers.append(ttUser)
                self.groupsUsersCache.insert(ttUser, forKey: ttUser.username)
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
            
            UIAction(title: "Save", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] action in
                guard let self = self else { return }
                if self.saveOrCancelIsland.isPresenting() {
                    self.saveOrCancelIsland.save()
                } else {
                    self.saveOrCancelIsland.present()
                }
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
        groupAggregateVC = GroupAggregateResultVC(group: group, usersNotVisible: usersNotVisible)
        groupAggregateVC.groupAggregateResultDelegate = self
        add(childVC: groupAggregateVC, to: aggregateResultView)
    }
    
    @objc private func showAddUserModal() {
        let destVC = AddUsersModalVC(group: group) { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        } addUserCompletionHandler: { [weak self] username in
            self?.addUserCompletionHandler(username: username)
        }
        
        destVC.modalPresentationStyle = .overFullScreen
        destVC.modalTransitionStyle = .crossDissolve
        self.present(destVC, animated: true)
    }
    
    private func addUserCompletionHandler(username: String) {
        let updatedGroupFields = [
            TTConstants.groupUsers: FieldValue.arrayUnion([username])
        ]
        
        FirebaseManager.shared.updateGroup(for: self.group.code, with: updatedGroupFields) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.presentTTAlert(title: "Error updating group", message: error.rawValue, buttonTitle: "Ok")
            } else {
                //update added user groupcodes field
                FirebaseManager.shared.updateUserData(for: username, with: [
                    TTConstants.groupCodes: FieldValue.arrayUnion([self.group.code])
                ]) { [weak self] error in
                    if let error = error {
                        self?.presentTTAlert(title: "Cannot add user to group", message: error.rawValue, buttonTitle: "OK")
                    } else {
                        //add to group edit history
                        self?.addGroupHistory(of: .addedUserToGroup, before: nil, after: username)
                        self?.group.users.append(username)

                        DispatchQueue.main.async {
                            self?.updateView()
                            self?.updateSaveOrCancelIsland()
                        }

                        self?.dismiss(animated: true)
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
        let userEventsWithinGroupRangeSet = Set(ekManager.getUserTTEvents(from: group.startingDate, to: group.endingDate))
        let currGroupEventsSet = Set(group.events)
        let unionGroupEvents = Array(currGroupEventsSet.union(userEventsWithinGroupRangeSet))

        group.events = unionGroupEvents
        updateGroupAggregateVC()
    
        let syncUserCalendarSaveOrCancelIsland = SaveOrCancelIsland(parentVC: self) { [weak self] in
            self?.updateGroupEventsWithCurrentUserEvents(with: unionGroupEvents)
            self?.addGroupHistory(of: .userSynced, before: nil, after: nil)
        }
        syncUserCalendarSaveOrCancelIsland.delegate = self 
        view.addSubview(syncUserCalendarSaveOrCancelIsland)
        
        syncUserCalendarSaveOrCancelIsland.present()
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
        groupOverviewVC = GroupOverviewVC(group: group, notVisibleMembers: usersNotVisible, openIntervals: openIntervals)
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
        groupUsersVC = GroupUsersVC(group: group, groupUsers: groupMembers, usersNotVisible: usersNotVisible)
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
    private func addGroupHistory(of editType: TTGroupEditType, before: String?, after: String?) {
        guard let currentUserUsername = FirebaseManager.shared.currentUser?.username else { return }
        let editDifference = TTGroupEditDifference(before: before, after: after)
        let newGroupEdit = TTGroupEdit(author: currentUserUsername, createdDate: Date(), editDifference: editDifference, editType: editType)
        group.histories.append(newGroupEdit)
        do {
            let newGroupHistory = try group.histories.arrayByAppending(newGroupEdit).map{ try Firestore.Encoder().encode($0) }
            FirebaseManager.shared.updateGroup(for: group.code, with: [
                TTConstants.groupHistories: newGroupHistory
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
    func groupDidUpdate(for group: TTGroup) {
        self.group = group
        updateView()
        updateGroupAggregateVC()
        updateSaveOrCancelIsland()
    }
    
    func groupUserVisibilityDidUpdate(for username: String) {
        if usersNotVisible.contains(username) {
            if let removeIndex = usersNotVisible.firstIndex(of: username) {
                usersNotVisible.remove(at: removeIndex)
            }
        } else {
            usersNotVisible.append(username)
        }
       updateGroupAggregateVC()
    }
}

extension GroupDetailVC: SaveOrCancelIslandDelegate {
    func didCancelIsland() {
        group = originalGroupState
        updateView()
        updateGroupAggregateVC()
    }
}

