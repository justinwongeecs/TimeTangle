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
    var usersThatAreNotVisible = [String]()
    
    init(room: TTRoom, nibName: String) {
        super.init(nibName: nibName, bundle: nil)
        self.room = room
        title = "\(room.name)"
        setOriginalRoomState(with: room)
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
        configureAdminEnability()
        updateView()
    }
    
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//
//        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
//        }
//    }
    
    private func setOriginalRoomState(with room: TTRoom) {
        //copy of room assigned to originalRoomState since TTRoom is a struct
        originalRoomState = room
//        if let events = roomAggregateVC.createEventsForOpenIntervals(with: originalRoomState.events) {
//            let ttEvents = events.map { $0.toTTEvent() }
//            originalRoomState.events.append(contentsOf: ttEvents)
//        }
    } 
    
    private func configureAdminEnability() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        if !room.doesContainsAdmin(for: currentUser.username) {
            startingDatePicker.isEnabled = false
            startingDatePicker.isUserInteractionEnabled = false
            endingDatePicker.isEnabled = false
            endingDatePicker.isUserInteractionEnabled = false
        } else {
            startingDatePicker.isEnabled = true
            startingDatePicker.isUserInteractionEnabled = true
            endingDatePicker.isEnabled = true
            endingDatePicker.isUserInteractionEnabled = true
        }
    }
    
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
            }
        ])
        
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), primaryAction: nil, menu: roomMoreMenu)
        
        infoButton.tintColor = .systemGreen
        sortButton.tintColor = .systemGreen
        
        navigationItem.rightBarButtonItems = [sortButton, infoButton]
    }
    
    private func configureRoomAggregateResultView() {
        roomAggregateVC = RoomAggregateResultVC(room: room, usersNotVisible: usersThatAreNotVisible)
        roomAggregateVC.roomAggregateResultDelegate = self
        add(childVC: roomAggregateVC, to: aggregateResultView)
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
    
    @objc func clickedOnViewResultButton(_ sender: UIButton) {
        //show summary view
        roomOverviewVC = RoomOverviewVC(room: room, notVisibleMembers: usersThatAreNotVisible, openIntervals: openIntervals)
        navigationController?.pushViewController(roomOverviewVC, animated: true)
    }
    
    @objc private func showAddUserModal() {
        let destVC = AddUsersModalVC(room: room)
        destVC.modalPresentationStyle = .overFullScreen
        destVC.modalTransitionStyle = .crossDissolve
        destVC.delegate = self
        destVC.addUsersModalVCDelegate = self
        self.present(destVC, animated: true)
    }
    
    @objc private func showRoomHistoryVC() {
        roomHistoryVC = RoomHistoryVC(room: room)
        navigationController?.pushViewController(roomHistoryVC, animated: true)
    }
    
    private func updateView() {
        usersCountButton.setTitle("\(room.users.count) \(room.users.count > 1 ? "Members" : "Member")", for: .normal)
        startingDatePicker.date = room.startingDate
        endingDatePicker.date = room.endingDate
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
        roomUsersVC = RoomUsersVC(room: room, usersNotVisible: usersThatAreNotVisible)
        roomUsersVC.delegate = self 
        navigationController?.pushViewController(roomUsersVC, animated: true)
    }
    
    @IBAction func startingDateChanged(_ sender: UIDatePicker) {
        //check to see if starting date is after ending date
        guard sender.date <= endingDatePicker.date else {
            //dismiss UIDatePickerContainerViewController
            dismiss(animated: true)
            presentTTAlert(title: "Invalid Starting Date", message: "Starting date cannot be after ending date", buttonTitle: "Ok")
            sender.date = endingDatePicker.date
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
        roomAggregateVC.setView(usersNotVisible: usersThatAreNotVisible, room: room)
    }
    
    //MARK: - Getters and Setters
    public func setRoomHistories(with histories: [TTRoomEdit]) {
        room.histories = histories
    }
}

//MARK: - Delegates

extension RoomDetailVC: CloseButtonDelegate {
    func didDismissPresentedView() {
        dismiss(animated: true)
    }
}

extension RoomDetailVC: AddUsersModalVCDelegate {
    func didSelectUserToBeAdded(for username: String) {
        //add user to Firebase room
        //get user data
        do  {
            let updatedRoomFields = [
                TTConstants.roomUsers: room.users.arrayByAppending(username)
            ]
            FirebaseManager.shared.updateRoom(for: room.code, with: updatedRoomFields) { [weak self] error in
                guard let error = error else { return }
                self?.presentTTAlert(title: "Error updating room", message: error.rawValue, buttonTitle: "Ok")
            }
            //update added user roomcodes field
            FirebaseManager.shared.updateUserData(for: username, with: [
                TTConstants.roomCodes: FieldValue.arrayUnion([room.code])
            ]) { error in
                guard let error = error else { return }
            }
            
            //add to room edit history
            addRoomHistory(of: .addedUserToRoom, before: nil, after: username)
            dismiss(animated: true)
        }
//        } catch {
//            dismiss(animated: true)
//            print("Error adding user to room")
//            presentTTAlert(title: "Error adding user to room", message: TTError.unableToUpdateRoom.rawValue, buttonTitle: "Ok")
//        }
    }
}

//Manages toggling user visibility
extension RoomDetailVC: RoomUserCellDelegate {
    func changedUserVisibility(for username: String) {
      
        if usersThatAreNotVisible.contains(username) {
            if let removeIndex = usersThatAreNotVisible.firstIndex(of: username) {
                usersThatAreNotVisible.remove(at: removeIndex)
            }
        } else {
            usersThatAreNotVisible.append(username)
        }
       updateRoomAggregateVC()
    }
}

extension RoomDetailVC: RoomAggregateResultVCDelegate {
    func updatedAggregateResultVC(events: [Event]) {
        openIntervals = events.map { $0.toTTEvent() }
    }
}

extension RoomDetailVC: RoomUpdateDelegate {
    func roomDidUpdate(for room: TTRoom) {
        self.room = room
        updateView()
    }
}

extension RoomDetailVC: SaveOrCancelIslandDelegate {
    func didCancelIsland() {
        room = originalRoomState
        updateRoomAggregateVC()
    }
    
    func didSaveIsland() {
        let previousStartingDate = originalRoomState.startingDate
        let previousEndingDate = originalRoomState.endingDate
        
        FirebaseManager.shared.updateRoom(for: room.code, with: [
            TTConstants.roomStartingDate: room.startingDate,
            TTConstants.roomEndingDate: room.endingDate,
            TTConstants.roomEvents: originalRoomState.events.map { $0.dictionary }
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
    }
}

