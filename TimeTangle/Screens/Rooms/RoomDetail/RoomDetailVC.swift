//
//  RoomDetailVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/30/22.
//

import UIKit
import CalendarKit
import FirebaseFirestore

protocol RoomUpdateDelegate: AnyObject {
    func roomDidUpdate(for room: TTRoom)
    func roomUserVisibilityDidUpdate(for username: String)
}

extension RoomUpdateDelegate {
    func roomUserVisibilityDidUpdate(for username: String) {}
}

class RoomDetailVC: UIViewController {
    
    @IBOutlet weak var usersCountButton: UIButton!
    @IBOutlet weak var startingDatePicker: UIDatePicker!
    @IBOutlet weak var endingDatePicker: UIDatePicker!
    @IBOutlet weak var aggregateResultView: UIView!
    
    private var roomAggregateVC: RoomAggregateResultVC!
    private var roomUsersVC: RoomUsersVC!
    private var room: TTRoom!
    private var roomHistoryVC: RoomHistoryVC!
    private var roomOverviewVC: RoomOverviewVC!
    private var confirmRoomChangesContainerView: UIView!
    private var saveOrCancelIsland: SaveOrCancelIsland!
    
    private var originalRoomState: TTRoom!
    private var openIntervals = [TTEvent]()
    private var isPresentingRoomChangesView: Bool = false
    
    //filters displaying users
    var usersNotVisible = [String]()
    
    init(room: TTRoom, nibName: String) {
        super.init(nibName: nibName, bundle: nil)
        self.room = room
        title = "\(room.name)"
        originalRoomState = room
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        configureNavigationBarItems()
        configureRoomAggregateResultView()
        configureSaveOrCancelIsland()
//        configureAdminEnability()
        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
//    private func configureAdminEnability() {
//        guard let currentUser = FirebaseManager.shared.currentUser else { return }
//        if !room.doesContainsAdmin(for: currentUser.username) {
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
    
    //MARK: - NavigationBarItems
    private func configureNavigationBarItems() {
        view.backgroundColor = .systemBackground
        
        let infoButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(clickedOnViewResultButton))
        
        let roomMoreMenu = UIMenu(title: "", children: [
            UIAction(title: "Add User", image: UIImage(systemName: "person.badge.plus")) { [weak self] action in
                self?.showAddUserModal()
            },
            
            UIAction(title: "Show Room History", image: UIImage(systemName: "clock")) { [weak self] action in
                self?.showRoomHistoryVC()
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
            
            UIAction(title: "Room Settings", image: UIImage(systemName: "gear")) { [weak self] action in
                self?.showRoomSettingsVC()
            }
        ])
        
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), primaryAction: nil, menu: roomMoreMenu)
        
        infoButton.tintColor = .systemGreen
        sortButton.tintColor = .systemGreen
        
        navigationItem.rightBarButtonItems = [sortButton, infoButton]
    }
    
    private func configureRoomAggregateResultView() {
        roomAggregateVC = RoomAggregateResultVC(room: room, usersNotVisible: usersNotVisible)
        roomAggregateVC.roomAggregateResultDelegate = self
        add(childVC: roomAggregateVC, to: aggregateResultView)
    }
    
    @objc private func showAddUserModal() {
        let destVC = AddUsersModalVC(room: room) { [weak self] in
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
        let updatedRoomFields = [
            TTConstants.roomUsers: FieldValue.arrayUnion([username])
        ]
        
        FirebaseManager.shared.updateRoom(for: self.room.code, with: updatedRoomFields) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.presentTTAlert(title: "Error updating room", message: error.rawValue, buttonTitle: "Ok")
            } else {
                //update added user roomcodes field
                print(username)
                FirebaseManager.shared.updateUserData(for: username, with: [
                    TTConstants.roomCodes: FieldValue.arrayUnion([self.room.code])
                ]) { [weak self] error in
                    print("Current User : \(FirebaseManager.shared.currentUser?.username ?? "")")
                    if let error = error {
                        self?.presentTTAlert(title: "Cannot add user to room", message: error.rawValue, buttonTitle: "OK")
                    } else {
                        //add to room edit history
                        self?.addRoomHistory(of: .addedUserToRoom, before: nil, after: username)
                        self?.room.users.append(username)

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
    
    @objc private func showRoomHistoryVC() {
        roomHistoryVC = RoomHistoryVC(room: room)
        navigationController?.pushViewController(roomHistoryVC, animated: true)
    }
    
    private func renameRoom() {
        let alertController = UIAlertController(title: "Rename Room", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { [weak self] textField in
            guard let self = self else { return }
            textField.placeholder = "\(self.room.name)"
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            if let newRoomName = alertController.textFields?.first?.text {
                FirebaseManager.shared.updateRoom(for: self.room.code, with: [
                    TTConstants.roomName: newRoomName
                ]) { [weak self] error in
                    guard let error = error else {
                        self?.title = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
                        return
                    }
                    self?.presentTTAlert(title: "Fetch Room Error", message: error.rawValue, buttonTitle: "OK")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true )
    }
    
    @objc private func syncUserCalendar() {
        //Fetch current user's events within room time frame
        let ekManager = EventKitManager()
        let userEventsWithinRoomRange = ekManager.getUserTTEvents(from: room.startingDate, to: room.endingDate)

        for userEvent in userEventsWithinRoomRange {
            if !room.events.contains(userEvent) {
                room.events.append(userEvent)
            }
        }
        updateRoomAggregateVC()
        updateSaveOrCancelIsland()
    }
    
    private func showRoomSettingsVC() {
        let config = Configuration()
        let roomSettingsView = RoomSettingsView(room: room, config: config) { [weak self] newRoom in
            self?.room = newRoom
            DispatchQueue.main.async {
                self?.updateView()
            }
        } popUIViewController: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        let roomSettingsHostingController = TTHostingController(rootView: roomSettingsView)
        config.hostingController = roomSettingsHostingController
        present(roomSettingsHostingController, animated: true)
    }

    @objc private func refreshRoom() {
        //Update Room Code, Starting and Ending Dates
        let updateFields = [
            TTConstants.roomStartingDate: startingDatePicker.date,
            TTConstants.roomEndingDate: endingDatePicker.date
        ]
        
        FirebaseManager.shared.updateRoom(for: room.code, with: updateFields) { [weak self] error in
            guard let error = error else { return }
            self?.presentTTAlert(title: "Cannot change starting date", message: error.rawValue, buttonTitle: "Ok")
        }
    }
    
    @objc func clickedOnViewResultButton(_ sender: UIButton) {
        //show summary view
        roomOverviewVC = RoomOverviewVC(room: room, notVisibleMembers: usersNotVisible, openIntervals: openIntervals)
        navigationController?.pushViewController(roomOverviewVC, animated: true)
    }
    
    private func updateView() {
        title = room.name
        usersCountButton.setTitle("\(room.users.count) \(room.users.count > 1 ? "Members" : "Member")", for: .normal)
        startingDatePicker.date = room.startingDate
        startingDatePicker.isEnabled = !room.setting.lockRoomChanges
        startingDatePicker.minimumDate = room.setting.boundedStartDate
        startingDatePicker.maximumDate = room.setting.boundedEndDate
        
        endingDatePicker.date = room.endingDate
        endingDatePicker.isEnabled = !room.setting.lockRoomChanges
        endingDatePicker.minimumDate = room.setting.boundedStartDate
        endingDatePicker.maximumDate = room.setting.boundedEndDate 
    }
    
    private func configureSaveOrCancelIsland() {
        saveOrCancelIsland = SaveOrCancelIsland(parentVC: self)
        saveOrCancelIsland.delegate = self
        view.addSubview(saveOrCancelIsland)
    }

    private func updateSaveOrCancelIsland() {
        if room == originalRoomState{
            //Dismiss
            saveOrCancelIsland.dismiss()
        } else if room != originalRoomState {
            //Present
            saveOrCancelIsland.present()
        }
    }
    
    //MARK: - IBAction Buttons
    
    //push new view controller to display list of members view
    @IBAction func clickedUsersCountButton(_ sender: UIButton) {
        roomUsersVC = RoomUsersVC(room: room, usersNotVisible: usersNotVisible)
        roomUsersVC.delegate = self 
        navigationController?.pushViewController(roomUsersVC, animated: true)
    }
    
    @IBAction func startingDateChanged(_ sender: UIDatePicker) {
        //check to see if starting date is after ending date
        guard sender.date <= endingDatePicker.date else {
            //dismiss UIDatePickerContainerViewController
            dismiss(animated: true)
            presentTTAlert(title: "Invalid Starting Date", message: "Starting date cannot be after ending date", buttonTitle: "Ok")
            sender.date = room.startingDate
            return
        }
        room.startingDate = sender.date
      
        updateRoomAggregateVC()
        updateSaveOrCancelIsland()
    }
    
    @IBAction func endingDateChanged(_ sender: UIDatePicker) {
        //check to see if ending date is before starting date
        guard sender.date >= startingDatePicker.date else {
            //dismiss UIDatePickerContainerViewController
            dismiss(animated: true)
            presentTTAlert(title: "Invalid Ending Date", message: "Ending date cannot be before starting date", buttonTitle: "Ok")
            sender.date = room.endingDate
            return
        }
        room.endingDate = sender.date

        updateRoomAggregateVC()
        updateSaveOrCancelIsland()
    }
    
    
    //Should be triggered after every room edit
    private func addRoomHistory(of editType: TTRoomEditType, before: String?, after: String?) {

        guard let currentUserUsername = FirebaseManager.shared.currentUser?.username else { return }
        let editDifference = TTRoomEditDifference(before: before, after: after)
        let newRoomEdit = TTRoomEdit(author: currentUserUsername, createdDate: Date(), editDifference: editDifference, editType: editType)
        room.histories.append(newRoomEdit)
        do {
            let newRoomHistory = try room.histories.arrayByAppending(newRoomEdit).map{ try Firestore.Encoder().encode($0) }
            FirebaseManager.shared.updateRoom(for: room.code, with: [
                TTConstants.roomHistories: newRoomHistory
            ]) { [weak self] error in
                guard let error = error else { return }
                self?.presentTTAlert(title: "Cannot add room history", message: error.rawValue, buttonTitle: "Ok")
            }
        } catch {
            //Do error catching here
            presentTTAlert(title: "Cannot add room history", message: TTError.unableToAddRoomHistory.rawValue, buttonTitle: "Ok")
        }
    }
    
    private func updateRoomAggregateVC() {
        //filter and or add to room.events so that between startDate and endDate
        room.events = room.events.filter { $0.startDate >= startingDatePicker.date && $0.endDate <= endingDatePicker.date }
        roomAggregateVC.setView(usersNotVisible: usersNotVisible, room: room)
    }
    
    //MARK: - Getters and Setters
    public func setRoomHistories(with histories: [TTRoomEdit]) {
        room.histories = histories
    }
}

//MARK: - Delegates

extension RoomDetailVC: RoomAggregateResultVCDelegate {
    func updatedAggregateResultVC(events: [Event]) {
        openIntervals = events.map { $0.toTTEvent() }
    }
}

extension RoomDetailVC: RoomUpdateDelegate {
    func roomDidUpdate(for room: TTRoom) {
        self.room = room
        updateView()
        updateRoomAggregateVC()
        updateSaveOrCancelIsland()
    }
    
    func roomUserVisibilityDidUpdate(for username: String) {
        if usersNotVisible.contains(username) {
            if let removeIndex = usersNotVisible.firstIndex(of: username) {
                usersNotVisible.remove(at: removeIndex)
            }
        } else {
            usersNotVisible.append(username)
        }
       updateRoomAggregateVC()
    }
}

extension RoomDetailVC: SaveOrCancelIslandDelegate {
    func didCancelIsland() {
        room = originalRoomState
        updateView()
        updateRoomAggregateVC()
    }
    
    func didSaveIsland() {
        if !room.setting.lockRoomChanges {
            
            let previousStartingDate = originalRoomState.startingDate
            let previousEndingDate = originalRoomState.endingDate
            
            FirebaseManager.shared.updateRoom(for: room.code, with: [
                TTConstants.roomStartingDate: room.startingDate,
                TTConstants.roomEndingDate: room.endingDate,
                TTConstants.roomEvents: room.events.map { $0.dictionary }
            ]) { [weak self] error in
                guard let self = self else { return }
                guard let error = error  else {
                    let dateFormat = "MMM d y, h:mm a"
                    
                    if room.startingDate != previousStartingDate {
                        self.addRoomHistory(of: .changedStartingDate, before: previousStartingDate.formatted(with: dateFormat), after: self.room.startingDate.formatted(with: dateFormat))
                    }
                    
                    if room.endingDate != previousEndingDate {
                        self.addRoomHistory(of: .changedEndingDate, before: previousEndingDate.formatted(with: dateFormat), after: self.room.endingDate.formatted(with: dateFormat))
                    }
            
                    DispatchQueue.main.async {
                        self.saveOrCancelIsland.dismiss()
                    }
                    return
                }
                self.presentTTAlert(title: "Cannot change ending date", message: error.rawValue, buttonTitle: "Ok")
            }
        } else {
            presentTTAlert(title: "Cannot Save Room", message: "Room setting \"Lock Room Changes\" is set to true. This room cannot be edited", buttonTitle: "OK")
        }
    }
}

