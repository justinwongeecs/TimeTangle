//
//  GroupHistoryVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/2/23.
//

import UIKit
import FirebaseFirestore

enum GroupHistorySortOrder {
    case dateAscending
    case dateDescending
//    case today
}

class GroupHistoryVC: UIViewController {
    
    var group: TTGroup!
    private let groupHistoryTableView = UITableView()
    private var groupHistorySortOrder: GroupHistorySortOrder = .dateDescending
    
    init(group: TTGroup) {
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureGroupHistoryTableView()
        configureBarButtonItems()
        title = "\(group.name) Edit History"
        sortFilterTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
        updateTableView()
    }
    
    func setVC(for group: TTGroup) {
        self.group = group
    }
    
    private func configureBarButtonItems() {
        let deleteGroupHistoryButton = UIBarButtonItem(image: UIImage(systemName: "clear"), style: .plain, target: self, action: #selector(deleteGroupHistory))
        let sortMenu = UIMenu(title: "", children: [
            UIAction(title: "Date Ascending", image: UIImage(systemName: "arrow.up.circle")) { [weak self] action in
                self?.groupHistorySortOrder = .dateAscending
                self?.sortFilterTable()
            },
            
            UIAction(title: "Date Descending", image: UIImage(systemName: "arrow.down.circle")) { [weak self] action in
                self?.groupHistorySortOrder = .dateDescending
                self?.sortFilterTable()
            }
        ])
        
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), primaryAction: nil, menu: sortMenu)
        
        deleteGroupHistoryButton.tintColor = .systemRed
        sortButton.tintColor = .systemGreen
         
        guard let currentUser = FirebaseManager.shared.currentUser else { return }

        if group.doesContainsAdmin(for: currentUser.username) && !group.histories.isEmpty {
            navigationItem.rightBarButtonItems = [sortButton, deleteGroupHistoryButton]
        } else {
            navigationItem.rightBarButtonItems = [sortButton]
        }
    }
    
    @objc private func deleteGroupHistory() {
        if let groupDetailVC = previousViewController() as? GroupDetailVC{
            //FIXME: Very not elegant to set both GroupHistoryVC's and GroupDetailVC's group history to be []
            group.histories = []
            groupDetailVC.setGroupHistories(with: [])
            configureBarButtonItems()
            DispatchQueue.main.async {
                self.updateTableView()
            }
            let updateFields = [TTConstants.groupHistories: [TTGroupEdit]()]
            FirebaseManager.shared.updateGroup(for: group.code, with: updateFields) { [weak self] error in
                guard error == nil else {
                    self?.presentTTAlert(title: "Cannot clear group history", message: error!.rawValue, buttonTitle: "Ok")
                    return
                }
            }
        }
    }
    
    private func configureGroupHistoryTableView() {
        view.addSubview(groupHistoryTableView)
        groupHistoryTableView.translatesAutoresizingMaskIntoConstraints = false
        groupHistoryTableView.allowsSelection = false
        groupHistoryTableView.delegate = self
        groupHistoryTableView.dataSource = self
        groupHistoryTableView.register(UINib(nibName: "GroupHistoryCell", bundle: nil), forCellReuseIdentifier: GroupHistoryCell.reuseID)
        
        NSLayoutConstraint.activate([
            groupHistoryTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            groupHistoryTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            groupHistoryTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            groupHistoryTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func sortFilterTable() {
        switch groupHistorySortOrder {
        case .dateAscending:
            self.group.histories.sort(by: { $0.createdDate < $1.createdDate })
        case .dateDescending:
            self.group.histories.sort(by: { $0.createdDate > $1.createdDate })
        }
        self.reloadTableView()
    }
    
    private func updateTableView() {
        self.reloadTableView()
        removeEmptyStateView(in: self.view)
        if group.histories.count > 0 {
            self.view.bringSubviewToFront(groupHistoryTableView)
        } else {
            showEmptyStateView(with: "No Group History", in: self.view)
        }
    }
    
    private func reloadTableView() {
        DispatchQueue.main.async {
            self.groupHistoryTableView.reloadData()
        }
    }
}

extension GroupHistoryVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return group.histories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = groupHistoryTableView.dequeueReusableCell(withIdentifier: GroupHistoryCell.reuseID) as! GroupHistoryCell
        let groupHistory = group.histories[indexPath.row]
        cell.setCell(for: groupHistory)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
}

//MARK: - GroupHistoryCell 
class GroupHistoryCell: UITableViewCell {
    static let reuseID = "GroupHistoryCell"
    
    @IBOutlet weak var authorImageView: UIImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var historyDateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private var groupHistory: TTGroupEdit!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setCell(for groupHistory: TTGroupEdit) {
        self.groupHistory = groupHistory
        configureCell()
    }
    
    private func configureCell() {
       //Configure authorImageView
        //TODO: - Set image to custom one stored in Firestore
        authorImageView.image = UIImage(systemName: "person.crop.circle")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        authorImageView.layer.masksToBounds = true
        authorImageView.layer.cornerRadius = 10
        
        //Configure authorNameLabel
        authorNameLabel.text = groupHistory.author
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/y h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        historyDateLabel.text = dateFormatter.string(from: groupHistory.createdDate)
        
        switch groupHistory.editType {
        case .changedStartingDate:
            descriptionLabel.text = "Changed starting time from \(groupHistory.editDifference.before ?? "") to \(groupHistory.editDifference.after ?? "")"
        case .changedEndingDate:
            descriptionLabel.text = "Changed ending time from \(groupHistory.editDifference.before ?? "") to \(groupHistory.editDifference.after ?? "")"
        case .addedUserToGroup:
            descriptionLabel.text = "Added \(groupHistory.editDifference.after ?? "") to group"
        default:
            descriptionLabel.text = "No description"
        }
    }
}
