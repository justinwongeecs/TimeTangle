//
//  RoomsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit

class RoomsVC: UIViewController {
    
    private var rooms = [TTRoom]() {
        didSet {
            if rooms.isEmpty {
                if #available(iOS 16.4, *) {
                    roomsSearchBar.isEnabled = false
                } else {
                    // Fallback on earlier versions
                    roomsSearchBar.isHidden = true
                }
            } else {
                if #available(iOS 16.4, *) {
                    roomsSearchBar.isEnabled = true
                } else {
                    // Fallback on earlier versions
                    roomsSearchBar.isHidden = false
                }
            }
        }
    }
    
    private var filterRooms = [TTRoom]()
    
    private let roomsSearchBar = UISearchBar()
    private let searchCountLabel = UILabel().withSearchCountStyle()
    private let roomsTable = UITableView()
    private let refreshControl = UIRefreshControl()
    
    private var selectedVCIndex: Int?
    private var roomsTableTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureSearchBar()
        configureSearchCountLabel()
        configureRoomsTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
        getRoomsFromCurrentUser()
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        configureDismissEditingTapGestureRecognizer()
    }
    
    private func configureSearchBar() {
        view.addSubview(roomsSearchBar)
        roomsSearchBar.placeholder = "Search for a room"
        roomsSearchBar.delegate = self
        roomsSearchBar.searchBarStyle = .minimal
        roomsSearchBar.autocapitalizationType = .none 
        roomsSearchBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            roomsSearchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            roomsSearchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            roomsSearchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            roomsSearchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureSearchCountLabel() {
        view.addSubview(searchCountLabel)
    
        NSLayoutConstraint.activate([
            searchCountLabel.topAnchor.constraint(equalTo: roomsSearchBar.bottomAnchor, constant: 3),
            searchCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchCountLabel.heightAnchor.constraint(equalToConstant: 20),
            searchCountLabel.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func configureRoomsTable() {
        view.addSubview(roomsTable)
        roomsTable.translatesAutoresizingMaskIntoConstraints = false
        roomsTable.separatorStyle = .none
        roomsTable.delegate = self
        roomsTable.dataSource = self
        roomsTable.register(RoomCell.self, forCellReuseIdentifier: RoomCell.reuseID)
        
        roomsTableTopConstraint = roomsTable.topAnchor.constraint(equalTo: roomsSearchBar.bottomAnchor, constant: 10)
        roomsTableTopConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            roomsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            roomsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            roomsTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10)
        ])
    }
    
    private func getRoomsFromCurrentUser() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        print(currentUser.username)
        fetchRooms(for: currentUser)

    } 
    
    //FIXME: - Not sure if it best practice to fetch for every single room for user because we only have the room codes for the user
    private func fetchRooms(for user: TTUser) {
        removeEmptyStateView(in: self.view)
        self.rooms = []
        self.filterRooms = []
        
        if user.roomCodes.count > 0 {
            for roomCode in user.roomCodes {
                FirebaseManager.shared.fetchRoom(for: roomCode) { [weak self] result in
                    switch result {
                    case .success(let room):
                        self?.rooms.append(room)
                        self?.filterRooms.append(room)
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
        
        DispatchQueue.main.async {
            self.roomsTable.reloadData()
        }
    }
    
    private func displaySearchCountLabel(isHidden: Bool) {
        UIView.transition(with: searchCountLabel, duration: 0.5, options: .transitionCrossDissolve) {
            self.searchCountLabel.isHidden = isHidden
        }
        
        //update roomsTable top constraint
        if isHidden {
            UIView.animate(withDuration: 0.35) {
                let newConstraint = self.roomsTable.topAnchor.constraint(equalTo: self.roomsSearchBar.bottomAnchor, constant: 10)
                self.updateRoomsTableTopConstraint(for: newConstraint)
            }
        } else {
            UIView.animate(withDuration: 0.35) {
                let newConstraint = self.roomsTable.topAnchor.constraint(equalTo: self.searchCountLabel.bottomAnchor, constant: 10)
                self.updateRoomsTableTopConstraint(for: newConstraint)
            }
        }
    }
    
    private func updateRoomsTableTopConstraint(for constraint: NSLayoutConstraint) {
        roomsTableTopConstraint.isActive = false
        roomsTableTopConstraint = constraint
        roomsTableTopConstraint.isActive = true
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    private func updateSearchCountLabel(with count: Int) {
        searchCountLabel.text = "\(count) Found"
    }
}

//MARK: - Delegates
extension RoomsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filterRooms.count
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
        let room = filterRooms[indexPath.section]
        cell.set(for: room)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRoom = filterRooms[indexPath.section]
        let roomInfoVC = RoomDetailVC(room: selectedRoom, nibName: "RoomDetailNib")
        selectedVCIndex = indexPath.section
        
        navigationController?.pushViewController(roomInfoVC, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        roomsSearchBar.resignFirstResponder()
    }
}

extension RoomsVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        removeEmptyStateView(in: self.view)
        
        guard !searchText.isEmpty else {
            filterRooms = rooms
            roomsTable.reloadData()
            displaySearchCountLabel(isHidden: true)
            return
        }
        
        filterRooms = rooms.filter{ $0.name.lowercased().contains(searchText.lowercased()) }
        if filterRooms.isEmpty {
            displaySearchCountLabel(isHidden: true)
            //show empty room search view
            showEmptyStateView(with: "No Rooms Found", in: self.view)
        } else {
            updateSearchCountLabel(with: filterRooms.count)
            displaySearchCountLabel(isHidden: false)
        }
        roomsTable.reloadData()
    }
}

//MARK: - RoomCell
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
