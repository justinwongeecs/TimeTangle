//
//  RoomDetailVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/30/22.
//

import UIKit
import CalendarKit
import FirebaseFirestore

class RoomDetailVC: UIViewController {
    
    @IBOutlet weak var usersCountButton: UIButton!
    @IBOutlet weak var startingDatePicker: UIDatePicker!
    @IBOutlet weak var endingDatePicker: UIDatePicker!
    @IBOutlet weak var aggregateResultView: UIView!
    
    private let roomAggregateVC = RoomAggregateResultVC()
    private var roomUsersVC: RoomUsersVC!
    private var room: TTRoom!
    private var roomHistoryVC: RoomHistoryVC!
    private var roomSummaryVC: RoomSummaryVC!
    private var confirmRoomChangesContainerView: UIView!
    
    private var originalRoomState: TTRoom!
    private var isPresentingRoomChangesView: Bool = false
    
    //filters displaying users
    var usersThatAreNotVisible = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBarItems()
        configureRoomAggregateResultView()
        configureRoomChangesContainerView()
    }
    
    //When I set prefersLargeTitles to false, it also changes RoomsVC title as well so I have to go manually change it
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        //Room already initialized here
        setOriginalRoomState()
        configureAdminEnability()
    }
    
    private func setOriginalRoomState() {
        //copy of room assigned to originalRoomState since TTRoom is a struct
        originalRoomState = room
    }
    
    private func configureAdminEnability() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        if !room.doesContainsAdmin(for: currentUser.username) {
            startingDatePicker.isEnabled = false
            startingDatePicker.isUserInteractionEnabled = false
            endingDatePicker.isEnabled = false
            endingDatePicker.isUserInteractionEnabled = false
        }
    }
    
    private func configureNavigationBarItems() {
        view.backgroundColor = .systemBackground
        
        let infoButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(clickedOnViewResultButton))
        
        let roomMoreMenu = UIMenu(title: "", children: [
            UIAction(title: "Show Room History", image: UIImage(systemName: "clock")) { [weak self] action in
                self?.showRoomHistoryVC()
            },
            
            UIAction(title: "Add User", image: UIImage(systemName: "person.badge.plus")) { [weak self] action in
                self?.showAddUserModal()
            },
            
            UIAction(title: "Sync Calendar", image: UIImage(systemName: "calendar")) { [weak self] action in
                self?.syncUserCalendar()
            }
        ])
        
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), primaryAction: nil, menu: roomMoreMenu)
        
        infoButton.tintColor = .systemGreen
        sortButton.tintColor = .systemGreen
        
        navigationItem.rightBarButtonItems = [sortButton, infoButton]
    }
    
    private func configureRoomAggregateResultView() {
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
        let updateFields = ["events" : userEventsWithinRoomRange.map{ $0.dictionary }]
        FirebaseManager.shared.updateRoom(for: room.code, with: updateFields) { [weak self] error in
            guard error == nil else {
                self?.presentTTAlert(title: "Cannot fetch event information from Apple Calendar", message: error!.rawValue, buttonTitle: "Ok")
                return
            }
        }
    }
    
    @objc func clickedOnViewResultButton(_ sender: UIButton) {
        //show summary view
        roomSummaryVC = RoomSummaryVC(room: room, notVisibleMembers: usersThatAreNotVisible)
        navigationController?.pushViewController(roomSummaryVC, animated: true)
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
    
    func set(room: TTRoom) {
        print("Update room")
        loadViewIfNeeded()
        self.room = room
        title = "\(room.name)"
        updateView()
    }
    
    private func updateView() {
        usersCountButton.setTitle("\(room.users.count) \(room.users.count > 1 ? "Members" : "Member")", for: .normal)
        startingDatePicker.date = room.startingDate
        endingDatePicker.date = room.endingDate
        updateRoomAggregateVC()
    }
    
    //MARK: - RoomChangesContainerView
    private func configureRoomChangesContainerView() {
        let innerPadding: CGFloat = 10
        let outerPadding: CGFloat = 20
        
        let outerContainerView = UIView()
        let screenSize = UIScreen.main.bounds.size
        outerContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        let roomChangesStackView = UIStackView()
        roomChangesStackView.axis = .horizontal
        roomChangesStackView.distribution = .fillProportionally
        roomChangesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        confirmRoomChangesContainerView = UIView()
        confirmRoomChangesContainerView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: 50 + innerPadding)
        confirmRoomChangesContainerView.addSubview(outerContainerView)
        view.addSubview(confirmRoomChangesContainerView)
        outerContainerView.layer.cornerRadius = 10.0
        outerContainerView.layer.masksToBounds = true
        outerContainerView.layer.shadowColor = UIColor.gray.cgColor
        outerContainerView.layer.shadowOffset = CGSize.zero
        outerContainerView.layer.shadowOpacity = 1.0
        outerContainerView.layer.shadowRadius = 7.0
        outerContainerView.addSubview(roomChangesStackView)

        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = confirmRoomChangesContainerView.bounds
        blurView.autoresizingMask = .flexibleWidth
        outerContainerView.insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: outerContainerView.topAnchor),
                blurView.leadingAnchor.constraint(equalTo: outerContainerView.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: outerContainerView.trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: outerContainerView.bottomAnchor)
        ])
   
        let closeButton = TTCloseButton()
        closeButton.tintColor = .systemRed
        closeButton.addTarget(self, action: #selector(cancelConfirmRoomChanges), for: .touchUpInside)
        
        let saveButton = UIButton(type: .custom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        saveButton.layer.cornerRadius = 10.0
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.addTarget(self, action: #selector(updateRoomToFirestore), for: .touchUpInside)
        
        roomChangesStackView.addArrangedSubview(closeButton)
        roomChangesStackView.addArrangedSubview(saveButton)

        NSLayoutConstraint.activate([
            outerContainerView.leadingAnchor.constraint(equalTo: confirmRoomChangesContainerView.leadingAnchor, constant: outerPadding),
            outerContainerView.trailingAnchor.constraint(equalTo: confirmRoomChangesContainerView.trailingAnchor, constant:  -outerPadding),
            outerContainerView.topAnchor.constraint(equalTo: confirmRoomChangesContainerView.topAnchor),
            outerContainerView.bottomAnchor.constraint(equalTo: confirmRoomChangesContainerView.bottomAnchor),
            
            roomChangesStackView.topAnchor.constraint(equalTo: outerContainerView.topAnchor, constant: innerPadding),
            roomChangesStackView.leadingAnchor.constraint(equalTo: outerContainerView.leadingAnchor, constant: innerPadding),
            roomChangesStackView.trailingAnchor.constraint(equalTo: outerContainerView.trailingAnchor, constant: -innerPadding),
            roomChangesStackView.bottomAnchor.constraint(equalTo: outerContainerView.bottomAnchor, constant: -innerPadding),
        ])
    }
    
    @objc private func cancelConfirmRoomChanges() {
        room = originalRoomState
        updateConfirmRoomChangesView()
    }
    
    @objc private func updateConfirmRoomChangesView() {
        if isPresentingRoomChangesView || room == originalRoomState{
            //Dismiss
            print("dismiss")
            let screenSize = UIScreen.main.bounds.size
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
                self.confirmRoomChangesContainerView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: 60)
            }
            isPresentingRoomChangesView = false
        } else if !isPresentingRoomChangesView && room != originalRoomState {
            //Present
            let screenSize = UIScreen.main.bounds.size
            guard let tabBarController = tabBarController else { return }
            let tabBarHeight = tabBarController.tabBar.frame.size.height
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
                self.confirmRoomChangesContainerView.frame = CGRect(x: 0, y: screenSize.height - tabBarHeight * 2, width: screenSize.width, height: 60)
            }
            isPresentingRoomChangesView = true
        }
    }
    
    @objc private func updateRoomToFirestore() {
        //update room's ending date in Firestore
        let previousStartingDate = originalRoomState.startingDate
        let previousEndingDate = originalRoomState.endingDate
        
        FirebaseManager.shared.updateRoom(for: room.code, with: [
            TTConstants.roomStartingDate: room.startingDate,
            TTConstants.roomEndingDate: room.endingDate
        ]) { [weak self] error in
            guard let self = self else { return }
            guard let error = error  else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d y, h:mm a"
                dateFormatter.amSymbol = "AM"
                dateFormatter.pmSymbol = "PM"
                
                if room.startingDate != previousStartingDate {
                    self.addRoomHistory(of: .changedStartingDate, before: dateFormatter.string(from: previousStartingDate), after: dateFormatter.string(from: self.room.startingDate))
                }
                
                if room.endingDate != previousEndingDate {
                    self.addRoomHistory(of: .changedEndingDate, before: dateFormatter.string(from: previousEndingDate), after: dateFormatter.string(from: self.room.endingDate))
                    
                }
        
                DispatchQueue.main.async {
                    self.updateConfirmRoomChangesView()
                }
                return
            }
            self.presentTTAlert(title: "Cannot change ending date", message: error.rawValue, buttonTitle: "Ok")
        }
    }
    
    //MARK: - IBAction Buttons
    
    //push new view controller to display list of members view
    @IBAction func clickedUsersCountButton(_ sender: UIButton) {
        roomUsersVC = RoomUsersVC(room: room, usersNotVisible: usersThatAreNotVisible)
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
      
        updateView()
        updateConfirmRoomChangesView()
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
        updateConfirmRoomChangesView()
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
        dismiss(animated: true )
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
       print("hello: \(usersThatAreNotVisible)")
    }
}

extension RoomDetailVC: RoomAggregateResultVCDelegate {
    func updatedAggregateResultVC(events: [Event]) {
        let updatedTTEvents = events.map { convertCalendarKitEventToTTEvent(event: $0) }
        print(updatedTTEvents)
        room.events = updatedTTEvents
    }
    
    private func convertCalendarKitEventToTTEvent(event: Event) -> TTEvent {
        return TTEvent(name: event.text, startDate: event.dateInterval.start, endDate: event.dateInterval.end, isAllDay: event.isAllDay)
    }
}

