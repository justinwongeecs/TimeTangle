//
//  RoomHistoryVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/2/23.
//

import UIKit
import FirebaseFirestore

enum RoomHistorySortOrder {
    case dateAscending
    case dateDescending
//    case today
}

class RoomHistoryVC: UIViewController {
    
    var room: TTRoom!
    private let roomHistoryTableView = UITableView()
    private var roomHistorySortOrder: RoomHistorySortOrder = .dateDescending
    
    init(room: TTRoom) {
        self.room = room
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureRoomHistoryTableView()
        configureBarButtonItems()
        title = "\(room.name) Edit History"
        sortFilterTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
        updateTableView()
    }
    
    func setVC(for room: TTRoom) {
        self.room = room
        print(room.histories)
        
    }
    
    private func configureBarButtonItems() {
        let deleteRoomHistoryButton = UIBarButtonItem(image: UIImage(systemName: "x.circle"), style: .plain, target: self, action: #selector(deleteRoomHistory))
        let sortMenu = UIMenu(title: "", children: [
            UIAction(title: "Date Ascending", image: UIImage(systemName: "arrow.up.circle")) { [weak self] action in
                self?.roomHistorySortOrder = .dateAscending
                self?.sortFilterTable()
            },
            
            UIAction(title: "Date Descending", image: UIImage(systemName: "arrow.down.circle")) { [weak self] action in
                self?.roomHistorySortOrder = .dateDescending
                self?.sortFilterTable()
            }

//            UIAction(title: "Today", image: UIImage(systemName: "clock")) { [weak self] action in
//                self?.roomHistorySortOrder = .today
//                self?.sortFilterTable()
//            }
        ])
        
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), primaryAction: nil, menu: sortMenu)
        
        deleteRoomHistoryButton.tintColor = .systemGreen
        sortButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItems = [sortButton, deleteRoomHistoryButton]
    }
    
    @objc private func deleteRoomHistory() {
        self.room.histories = []
        self.updateTableView()
//        let updateFields = [TTConstants.roomHistories: []]
//        FirebaseManager.shared.updateRoom(for: room.code, with: updateFields) { [weak self] error in
//            guard error == nil else {
//                self?.presentTTAlert(title: "Cannot clear room history", message: error!.rawValue, buttonTitle: "Ok")
//                return
//            }
//            self!.room.histories = []
//            self?.updateTableView()
//            print("Delete room histories success")
//        }
    }
    
    private func configureRoomHistoryTableView() {
        view.addSubview(roomHistoryTableView)
        roomHistoryTableView.translatesAutoresizingMaskIntoConstraints = false
        roomHistoryTableView.allowsSelection = false
        roomHistoryTableView.delegate = self
        roomHistoryTableView.dataSource = self
        roomHistoryTableView.register(UINib(nibName: "RoomHistoryCell", bundle: nil), forCellReuseIdentifier: RoomHistoryCell.reuseID)
        
        NSLayoutConstraint.activate([
            roomHistoryTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            roomHistoryTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomHistoryTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomHistoryTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func sortFilterTable() {
        switch roomHistorySortOrder {
        case .dateAscending:
            self.room.histories.sort(by: { $0.createdDate < $1.createdDate })
        case .dateDescending:
            self.room.histories.sort(by: { $0.createdDate > $1.createdDate })
        }
        self.reloadTableView()
    }
    
    private func updateTableView() {
        self.reloadTableView()
        removeEmptyStateView(in: self.view)
        if room.histories.count > 0 {
            self.view.bringSubviewToFront(roomHistoryTableView)
        } else {
            showEmptyStateView(with: "No Room History", in: self.view)
        }
    }
    
    private func reloadTableView() {
        print("reloadTableView")
        DispatchQueue.main.async {
            self.roomHistoryTableView.reloadData()
        }
    }
}

extension RoomHistoryVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return room.histories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = roomHistoryTableView.dequeueReusableCell(withIdentifier: RoomHistoryCell.reuseID) as! RoomHistoryCell
        let roomHistory = room.histories[indexPath.row]
        cell.setCell(for: roomHistory)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
}

//MARK: - RoomHistoryCell 
class RoomHistoryCell: UITableViewCell {
    static let reuseID = "RoomHistoryCell"
    
    @IBOutlet weak var authorImageView: UIImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var historyDateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private var roomHistory: TTRoomEdit!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setCell(for roomHistory: TTRoomEdit) {
        self.roomHistory = roomHistory
        configureCell()
    }
    
    private func configureCell() {
       //Configure authorImageView
        //TODO: - Set image to custom one stored in Firestore
        authorImageView.image = UIImage(systemName: "person.crop.circle")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        authorImageView.layer.masksToBounds = true
        authorImageView.layer.cornerRadius = 10
        
        //Configure authorNameLabel
        authorNameLabel.text = roomHistory.author
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/y h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        historyDateLabel.text = dateFormatter.string(from: roomHistory.createdDate)
        
        switch roomHistory.editType {
        case .changedStartingDate:
            descriptionLabel.text = "Changed starting time from \(roomHistory.editDifference.before ?? "") to \(roomHistory.editDifference.after ?? "")"
        case .changedEndingDate:
            descriptionLabel.text = "Changed ending time from \(roomHistory.editDifference.before ?? "") to \(roomHistory.editDifference.after ?? "")"
        case .addedUserToRoom:
            descriptionLabel.text = "Added \(roomHistory.editDifference.after ?? "") to room"
        default:
            descriptionLabel.text = "No description"
        }
    }
}
