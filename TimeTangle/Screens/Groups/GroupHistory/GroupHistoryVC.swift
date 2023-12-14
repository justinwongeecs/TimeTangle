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
    //TODO: Add case for today
//    case today
}

class GroupHistoryVC: UIViewController {
    var group: TTGroup!
    var groupUsers: [TTUser]!
    private let groupHistoryTableView = UITableView()
    private var groupHistorySortOrder: GroupHistorySortOrder = .dateDescending
    
    init(group: TTGroup, groupUsers: [TTUser]) {
        self.group = group
        self.groupUsers = groupUsers
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

        if group.doesContainsAdmin(for: currentUser.id) && !group.histories.isEmpty {
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
        groupHistoryTableView.register(GroupHistoryCell.self, forCellReuseIdentifier: GroupHistoryCell.reuseID)
        
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
        if let authorUserIndex = groupUsers.firstIndex(where: { $0.id == groupHistory.author }) {
            cell.setCell(for: groupHistory, authorUser: groupUsers[authorUserIndex])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
}

//MARK: - GroupHistoryCell 
class GroupHistoryCell: UITableViewCell {
    static let reuseID = "GroupHistoryCell"
    private var groupHistory: TTGroupEdit!
    private var authorUser: TTUser!
    
    private let authorNameLabel = UILabel()
    private let historyDateLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let authorImageView = TTProfileImageView(widthHeight: TTConstants.profileImageViewInCellHeightAndWidth * 1.3)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setCell(for groupHistory: TTGroupEdit, authorUser: TTUser) {
        self.groupHistory = groupHistory
        self.authorUser = authorUser
        
        configureCell()
    }
    
    private func configureCell() {
        authorUser.getProfilePictureUIImage { [weak self] image in
            if let image = image {
                self?.authorImageView.setImage(to: image)
            } else {
                self?.authorImageView.setToDefaultImage()
            }
        }
        
        authorImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(authorImageView)
        
        //HeaderStackView with authorNameLabel and historyDateLabel
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.distribution = .fill
        headerStackView.spacing = 10
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        authorNameLabel.text = groupHistory.author
        authorNameLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        authorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.addArrangedSubview(authorNameLabel)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/y h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        historyDateLabel.text = dateFormatter.string(from: groupHistory.createdDate)
        historyDateLabel.textColor = .lightGray
        historyDateLabel.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.addArrangedSubview(historyDateLabel)
        
        let vMainContentStackView = UIStackView()
        vMainContentStackView.axis = .vertical
        vMainContentStackView.distribution = .fill
        vMainContentStackView.spacing = 10
        vMainContentStackView.translatesAutoresizingMaskIntoConstraints = false
        vMainContentStackView.addArrangedSubview(headerStackView)
        
        descriptionLabel.textColor = .systemGray
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        vMainContentStackView.addArrangedSubview(descriptionLabel)
        addSubview(vMainContentStackView)
        
        switch groupHistory.editType {
        case .changedStartingDate:
            descriptionLabel.text = "Changed starting time from \(groupHistory.editDifference.before ?? "") to \(groupHistory.editDifference.after ?? "")"
        case .changedEndingDate:
            descriptionLabel.text = "Changed ending time from \(groupHistory.editDifference.before ?? "") to \(groupHistory.editDifference.after ?? "")"
        case .addedUserToGroup:
            descriptionLabel.text = "Added \(groupHistory.editDifference.after ?? "") to group"
        case .userSynced:
            descriptionLabel.text = "Synced their calendar."
        default:
            descriptionLabel.text = "No description"
        }
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            vMainContentStackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            vMainContentStackView.leadingAnchor.constraint(equalTo: authorImageView.trailingAnchor, constant: padding),
            vMainContentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            vMainContentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            
            authorImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            authorImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            authorImageView.widthAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth * 1.3),
            authorImageView.heightAnchor.constraint(equalToConstant: TTConstants.profileImageViewInCellHeightAndWidth * 1.3)
        ])
    }
}
