//
//  RoomInfoVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/30/22.
//

import UIKit
import CalendarKit
import FirebaseFirestore

class RoomInfoVC: UIViewController {
    
    @IBOutlet weak var usersCountButton: UIButton!
    @IBOutlet weak var startingDatePicker: UIDatePicker!
    @IBOutlet weak var endingDatePicker: UIDatePicker!
    @IBOutlet weak var aggregateResultView: UIView!
    
    private let roomAggregateVC = RoomAggregateResultVC()
    private let roomUsersVC = RoomUsersVC()
    private var room: TTRoom!
    private let roomHistoryVC = RoomHistoryVC()
    private var roomSummaryVC: RoomSummaryVC!
    
    //filters displaying users
    var usersThatAreNotVisible = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        roomAggregateVC.roomAggregateResultDelegate = self
        add(childVC: roomAggregateVC, to: aggregateResultView)
    }
    
    //When I set prefersLargeTitles to false, it also changes RoomsVC title as well so I have to go manually change it
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        
        //configure showRoomHistoryButton
        let showRoomHistoryButton = UIBarButtonItem(image: UIImage(systemName: "clock"), style: .plain, target: self, action: #selector(showRoomHistoryVC))
        
        //configure addUserButton
        let addUserToRoomButton = UIBarButtonItem(image: UIImage(systemName: "person.badge.plus"), style: .plain, target: self, action: #selector(showAddUserModal))
        
        showRoomHistoryButton.tintColor = .systemGreen
        addUserToRoomButton.tintColor = .systemGreen
        
        navigationItem.rightBarButtonItems = [addUserToRoomButton, showRoomHistoryButton]
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
        roomHistoryVC.setVC(for: room)
        navigationController?.pushViewController(roomHistoryVC, animated: true)
    }
    
    func set(room: TTRoom) {
        loadViewIfNeeded()
        self.room = room
        title = "\(room.name)"
        roomSummaryVC = RoomSummaryVC(room: room, notVisibleMembers: usersThatAreNotVisible)
        updateView()
    }
    
    private func updateView() {
        usersCountButton.setTitle("\(room.users.count) \(room.users.count > 1 ? "Members" : "Member")", for: .normal)
        startingDatePicker.date = room.startingDate
        endingDatePicker.date = room.endingDate
        roomHistoryVC.setVC(for: room)
        roomUsersVC.setVC(users: room.users, usersNotVisible: usersThatAreNotVisible)
        roomSummaryVC.updateNotVisibleMembers(for: usersThatAreNotVisible)
        updateRoomAggregateVC()
    }
    
    //MARK: - IBAction Buttons
    
    //push new view controller to display list of members view
    @IBAction func clickedUsersCountButton(_ sender: UIButton) {
        navigationController?.pushViewController(roomUsersVC, animated: true)
    }
    
    @IBAction func startingDateChanged(_ sender: UIDatePicker) {
        //check to see if starting date is after ending date
        guard sender.date <= endingDatePicker.date else {
            presentTTAlert(title: "Invalid Starting Date", message: "Starting date cannot be after ending date", buttonTitle: "Ok")
            return
        }
        //update room's starting date in Firestore
        let previousStartingDate = startingDatePicker.date
        FirebaseManager.shared.updateRoom(for: room.code, with: [
            TTConstants.roomStartingDate: sender.date
        ]) { [weak self] error in
            guard let error = error else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d y, HH:mm"
                self?.addRoomHistory(of: .changedStartingDate, before: dateFormatter.string(from: previousStartingDate), after: dateFormatter.string(from: sender.date))
                return
            }
            self?.presentTTAlert(title: "Cannot change starting date", message: error.rawValue, buttonTitle: "Ok")
        }
    }
    
    @IBAction func endingDateChanged(_ sender: UIDatePicker) {
        //check to see if ending date is before starting date
        guard sender.date >= startingDatePicker.date else {
            presentTTAlert(title: "Invalid Ending Date", message: "Ending date cannot be before starting date", buttonTitle: "Ok")
            return
        }
        //update room's ending date in Firestore
        let previousEndingDate = endingDatePicker.date
        FirebaseManager.shared.updateRoom(for: room.code, with: [
            TTConstants.roomEndingDate: sender.date
        ]) { [weak self] error in
            guard let error = error else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d y, h:mm a"
                dateFormatter.amSymbol = "AM"
                dateFormatter.pmSymbol = "PM"
                self?.addRoomHistory(of: .changedEndingDate, before: dateFormatter.string(from: previousEndingDate), after: dateFormatter.string(from: sender.date))
                return
            }
            self?.presentTTAlert(title: "Cannot change ending date", message: error.rawValue, buttonTitle: "Ok")
        }
    }
    
    @IBAction func clickedOnViewResultButton(_ sender: UIButton) {
        //show summary view
        navigationController?.pushViewController(roomSummaryVC, animated: true)
    }
    
    //Should be triggered after every room edit
    private func addRoomHistory(of editType: TTRoomEditType, before: String?, after: String?) {
        guard let currentUserUsername = FirebaseManager.shared.currentUser?.username else { return }
        let editDifference = TTRoomEditDifference(before: before, after: after)
        let newRoomEdit = TTRoomEdit(author: currentUserUsername, createdDate: Date(), editDifference: editDifference, editType: editType)
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
        roomAggregateVC.setView(usersNotVisible: usersThatAreNotVisible, room: room)
    }
}

//MARK: - Delegates

extension RoomInfoVC: CloseButtonDelegate {
    func didDismissPresentedView() {
        dismiss(animated: true )
    }
}

extension RoomInfoVC: AddUsersModalVCDelegate {
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
extension RoomInfoVC: RoomUserCellDelegate {
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

extension RoomInfoVC: RoomAggregateResultVCDelegate {
    func updatedAggregateResultVC(events: [Event]) {
        roomSummaryVC.updateEvents(for: events)
    }
}

