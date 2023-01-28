//
//  RoomsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit

class RoomsVC: UIViewController {
    
    private var rooms = [TTRoom]()
    
    private let roomsTable = UITableView()
    private let refreshControl = UIRefreshControl()
    private var selectedVCIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureRefreshControl()
        configureRoomsTable()
        getRoomsFromCurrentUser()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .updatedUser, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        //get updates from current user
//        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser(_:)), name: .updatedUser, object: nil)
        //get updates from current user rooms
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedCurrentUserRooms(_:)), name: .updatedCurrentUserRooms, object: nil)
    }
    
    private func configureRefreshControl() {
//        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        roomsTable.addSubview(refreshControl)
    }
    
    @objc private func refresh(_ sender: AnyObject) {
        getRoomsFromCurrentUser()
        refreshControl.endRefreshing()
    }
    
    private func configureRoomsTable() {
        view.addSubview(roomsTable)
        roomsTable.translatesAutoresizingMaskIntoConstraints = false
        roomsTable.separatorStyle = .none
        roomsTable.delegate = self
        roomsTable.dataSource = self
        roomsTable.register(RoomCell.self, forCellReuseIdentifier: RoomCell.reuseID)
        
        NSLayoutConstraint.activate([
            roomsTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            roomsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            roomsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            roomsTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10)
        ])
    }
    
    @objc private func fetchUpdatedCurrentUserRooms(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let fetchedRooms = notification.object as? [TTRoom] else { return }
            self.rooms = fetchedRooms
            self.roomsTable.reloadData()
            if let pushedVC = self.navigationController?.viewControllers.last as? RoomInfoVC, let selectedVCIndex = self.selectedVCIndex {
                pushedVC.set(room: self.rooms[selectedVCIndex])
            }
        }
    }
    
    private func getRoomsFromCurrentUser() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        fetchRooms(for: currentUser)
        roomsTable.reloadData()
    }
    
//    @objc private func fetchUpdatedUser(_ notification: Notification) {
//        DispatchQueue.main.async {
//            guard let fetchedUser = notification.object as? TTUser else { return }
//            self.fetchRooms(for: fetchedUser)
//            self.roomsTable.reloadData()
//        }
//    }
    
    //FIXME: - Not sure if it best practice to fetch for every single room for user because we only have the room codes for the user
    private func fetchRooms(for user: TTUser) {
        removeEmptyStateView(in: self.view)
        self.rooms = []
        if user.roomCodes.count > 0 {
            for roomCode in user.roomCodes {
                FirebaseManager.shared.fetchRoom(for: roomCode) { [weak self] result in
                    switch result {
                    case .success(let room):
                        self?.rooms.append(room)
                        DispatchQueue.main.async {
                            self?.roomsTable.reloadData()
                        }
                    case .failure(let error):
                        self?.presentTTAlert(title: "Cannot fetch room", message: error.rawValue, buttonTitle: "Ok")
                    }
                }
            }
        } else {
            //show empty view
            showEmptyStateView(with: "No Rooms", in: self.view)
        }
    }
}

extension RoomsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return rooms.count
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = roomsTable.dequeueReusableCell(withIdentifier: RoomCell.reuseID) as! RoomCell
        let room = rooms[indexPath.section]
        cell.set(for: room)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRoom = rooms[indexPath.section]
        let roomInfoVC = RoomInfoVC(nibName: "RoomDetailNib", bundle: nil)
        roomInfoVC.set(room: selectedRoom)
        selectedVCIndex = indexPath.section
        
        navigationController?.pushViewController(roomInfoVC, animated: true)
    }
}

class RoomCell: UITableViewCell {
    
    static let reuseID = "RoomCell"
    
    private var room: TTRoom!
    
    private let labelsStackView = UIStackView()
    private var roomNameLabel = TTTitleLabel(textAlignment: .left, fontSize: 20)
    private let dateCreatedLabel = TTBodyLabel(textAlignment: .left)
    
    private let roomCellPadding: CGFloat = 10
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
        configureRoomNameLabel()
        configureDateCreatedLabel()
        configureLabelsStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(for room: TTRoom) {
        self.room = room
        roomNameLabel.text = room.name
    }
    
    private func configureCell() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        accessoryType = .disclosureIndicator
        selectionStyle = .none
    }
    
    private func configureLabelsStackView() {
        addSubview(labelsStackView)
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.distribution = .fill
        
        labelsStackView.addArrangedSubview(roomNameLabel)
        labelsStackView.addArrangedSubview(dateCreatedLabel)
        
        NSLayoutConstraint.activate([
            labelsStackView.topAnchor.constraint(equalTo: topAnchor, constant: roomCellPadding),
            labelsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: roomCellPadding),
            labelsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -roomCellPadding),
            labelsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -roomCellPadding)
        ])
    }
    
    private func configureRoomNameLabel() {
        addSubview(roomNameLabel)
    }
    
    private func configureDateCreatedLabel() {
        addSubview(dateCreatedLabel)
        dateCreatedLabel.text = "12/28/22"
    }
}
