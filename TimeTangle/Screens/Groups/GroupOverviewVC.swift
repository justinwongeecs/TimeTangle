//
//  GroupOverviewVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/18/23.
//

import UIKit
import CalendarKit

enum GroupOverviewFilterType {
    case availableTimes
    case unAvailableTimes
    case all
}

private struct GroupOverviewSection {
    var date: Date
    var events: [TTEvent]
}

protocol GroupOverviewCellDelegate: AnyObject {
    func didSelectInterval(for event: TTEvent?)
}

class GroupOverviewVC: UIViewController {
    private var group: TTGroup!
    private var groupsUsersCache: TTCache<String, TTUser>!
    private var groupSummarySections: [GroupOverviewSection]!
    private var filteredGroupSummarySections = [GroupOverviewSection]()
    private var notVisibleMembers = [String]()
    private let timesTableView = UITableView()
    
    private let filterIndicatorView = UIView()
    private let filterIndicatorViewLabel = UILabel()
    private var filterIndicatorViewWidthConstraint: NSLayoutConstraint!
    private var currentFilterMode: GroupOverviewFilterType = .all
    
    private var selectedInterval: TTEvent?
    
    init(
        group: TTGroup,
        groupsUsersCache: TTCache<String,TTUser>,
        notVisibleMembers: [String],
        openIntervals: [TTEvent]
    ) {
        self.group = group
        self.groupsUsersCache = groupsUsersCache
        self.group.events.append(contentsOf: openIntervals)
        self.notVisibleMembers = notVisibleMembers
        super.init(nibName: nil, bundle: nil)
        funcRemoveAllDayEvents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = .systemGreen
        
        configureNavigationBarItems()
        configureVC()
        configureFilterIndicatorView()
        configureTimesTable()
        navigationController?.navigationBar.prefersLargeTitles = false
        
        configureGroupSummarySections()
        updateTimesTable()
    }
    
    private func configureVC() {
        view.backgroundColor = .systemBackground
        title = "\(group.name) Overview"
    }
    
    private func configureNavigationBarItems() {
        let filterEventsMenu = UIMenu(title: "", children: [
            UIAction(title: "Show All", image: UIImage(systemName: "list.bullet")) { [weak self] action in
                self?.filterShowAll()
            },
            UIAction(title: "Show Open Intervals", image: UIImage(systemName: "checkmark.circle")) { [weak self] action in
                self?.filterAndShowOpenIntervals()
            },
            UIAction(title: "Show Unavailable Intervals", image: UIImage(systemName: "xmark.circle")) { [weak self] action in
                self?.filterAndShowUnavailableIntervals()
            }
        ])
        
        let filterEventsButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), primaryAction: nil, menu: filterEventsMenu)
        
        filterEventsButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = filterEventsButton
    }
    
    private func configureFilterIndicatorView() {
        filterIndicatorView.backgroundColor = .systemIndigo.withAlphaComponent(0.7)
        filterIndicatorView.layer.cornerRadius = 15
        filterIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterIndicatorView)
        
  
        filterIndicatorViewLabel.text = "Show All"
        filterIndicatorViewLabel.textColor = .white
        filterIndicatorViewLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        filterIndicatorViewLabel.translatesAutoresizingMaskIntoConstraints = false
        filterIndicatorView.addSubview(filterIndicatorViewLabel)
        
        filterIndicatorViewWidthConstraint = filterIndicatorView.widthAnchor.constraint(equalToConstant: 100)
        filterIndicatorViewWidthConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            filterIndicatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            filterIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterIndicatorView.heightAnchor.constraint(equalToConstant: 30),
            
            filterIndicatorViewLabel.centerXAnchor.constraint(equalTo: filterIndicatorView.centerXAnchor),
            filterIndicatorViewLabel.centerYAnchor.constraint(equalTo: filterIndicatorView.centerYAnchor)
        ])
    }
    
    private func filterShowAll() {
        if currentFilterMode != .all {
            filteredGroupSummarySections = groupSummarySections
            currentFilterMode = .all
            filterIndicatorViewLabel.text = "Show All"
            
            UIView.animate(withDuration: 0.5) {
                self.filterIndicatorViewWidthConstraint.constant = 100
                self.filterIndicatorView.layoutIfNeeded()
            }
            
            updateTimesTable()
        }
    }
    
    private func filterAndShowOpenIntervals() {
        if currentFilterMode != .availableTimes {
            guard let groupSummarySections = groupSummarySections else { return }
            var openIntervalSections = groupSummarySections
            
            for i in 0..<openIntervalSections.count {
                openIntervalSections[i].events = openIntervalSections[i].events.filter { $0.createdBy == "TimeTangle" }
            }
            filteredGroupSummarySections = openIntervalSections.filter { !$0.events.isEmpty }
            currentFilterMode = .availableTimes
            
            UIView.animate(withDuration: 0.5) {
                self.filterIndicatorViewWidthConstraint.constant = 180
                self.filterIndicatorView.layoutIfNeeded()
            }
            
            filterIndicatorViewLabel.text = "Show Open Intervals"
            updateTimesTable()
        }
    }
    
    private func filterAndShowUnavailableIntervals() {
        if currentFilterMode != .unAvailableTimes {
            guard let groupSummarySections = groupSummarySections else { return }
            var unavailableSections = groupSummarySections
            
            for i in 0..<unavailableSections.count {
                unavailableSections[i].events = unavailableSections[i].events.filter { $0.createdBy != "TimeTangle" }
            }
            
            filteredGroupSummarySections = unavailableSections.filter { !$0.events.isEmpty }
            currentFilterMode = .unAvailableTimes
            filterIndicatorViewLabel.text = "Show Unavailable Intervals"
            
            UIView.animate(withDuration: 0.5) {
                self.filterIndicatorViewWidthConstraint.constant = 220
                self.filterIndicatorView.layoutIfNeeded()
            }
            
            updateTimesTable()
        }
    }
    
    private func funcRemoveAllDayEvents() {
        self.group.events = self.group.events.filter { !$0.isAllDay }
    }
    
    private func configureGroupSummarySections() {        
        guard !group.events.isEmpty, let firstEvent = group.events.first, firstEvent.endDate != firstEvent.startDate else {
            groupSummarySections = []
            timesTableView.backgroundView = TTEmptyStateView(message: "No Events")
            return
        }
        
        timesTableView.backgroundView = nil
        var sections = [GroupOverviewSection]()
        sections.append(GroupOverviewSection(date: firstEvent.startDate, events: [firstEvent]))
        
        for index in stride(from: 1, to: group.events.count, by: 1) {
            let event = group.events[index]
            
            if let index = sections.firstIndex(where: { $0.date.compare(with: event.startDate, toGranularity: .day) == .orderedSame}) {
                sections[index].events.append(event)
            } else {
                sections.append(GroupOverviewSection(date: event.startDate, events: [event]))
            }
        }
        
        //Sort events inside each section
        for index in 0..<sections.count {
            sections[index].events.sort(by: { $0.startDate < $1.startDate })
        }
        
        //Sort sections
        groupSummarySections = sections.sorted(by: { $0.date < $1.date })
        filteredGroupSummarySections = groupSummarySections
    }
    
    private func configureTimesTable() {
        timesTableView.separatorStyle = .none
        timesTableView.translatesAutoresizingMaskIntoConstraints = false
        timesTableView.dataSource = self
        timesTableView.delegate = self
        timesTableView.register(GroupOverviewCell.self, forCellReuseIdentifier: GroupOverviewCell.reuseID)
        view.addSubview(timesTableView)

        NSLayoutConstraint.activate([
            timesTableView.topAnchor.constraint(equalTo: filterIndicatorView.bottomAnchor),
            timesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateTimesTable() {
        if filteredGroupSummarySections.isEmpty {
            timesTableView.backgroundView = TTEmptyStateView(message: "No Matching Results")
        } else {
            timesTableView.backgroundView = nil
        }
        
        timesTableView.reloadData()
    }
}

//MARK: - GroupOverviewVC TableView Delegates
extension GroupOverviewVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredGroupSummarySections.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.text = filteredGroupSummarySections[section].date.formatted(with: "M/d/yyyy")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 5),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredGroupSummarySections[section].events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = timesTableView.dequeueReusableCell(withIdentifier: GroupOverviewCell.reuseID) as! GroupOverviewCell
        
        let section = filteredGroupSummarySections[indexPath.section]
        let event = section.events[indexPath.row]
        cell.set(for: event, selectedInterval: selectedInterval, groupsUsersCache: groupsUsersCache)
        cell.groupOverviewCellDelegate = self

        return cell
    }
}

extension GroupOverviewVC: GroupOverviewCellDelegate {
    func didSelectInterval(for event: TTEvent?) {
        selectedInterval = event
        updateTimesTable()
    }
}

//MARK: - GroupOverviewCell
class GroupOverviewCell: UITableViewCell {
    static let reuseID = "GroupOverviewCell"
    
    private var event: TTEvent?
    private var groupsUsersCache: TTCache<String, TTUser>!
    private var isCellSelected = false
    
    private var createdByUserLabel = UILabel()
    private var groupNameAndTimeLabel = UILabel()
    private var selectedIntervalImageView = UIImageView()
    
    weak var groupOverviewCellDelegate: GroupOverviewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(for event: TTEvent, selectedInterval: TTEvent?, groupsUsersCache: TTCache<String, TTUser>) {
        self.event = event
        self.groupsUsersCache = groupsUsersCache
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.amSymbol = "AM"
        timeFormatter.pmSymbol = "PM"
        
        //TODO: Implement Ability for User to Choose if they want to display their event names
        let attrs = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 15)]
        
        let timeIntervalText = "\(timeFormatter.string(from: event.startDate)) - \(timeFormatter.string(from: event.endDate))"
        groupNameAndTimeLabel.text = timeIntervalText
        
        //configure cell based on event.createdBy
        if event.isCreatedByUser {
            groupNameAndTimeLabel.textColor = .systemRed
            createdByUserLabel.isHidden = false
            createdByUserLabel.text = getUserFullNameFromID(for: event.createdBy)
            backgroundColor = .systemRed.withAlphaComponent(0.15)
        } else {
            groupNameAndTimeLabel.textColor = .systemGreen
            createdByUserLabel.isHidden = true
            backgroundColor = .systemGreen.withAlphaComponent(0.15)
        }
        
        if selectedInterval == event {
            selectedIntervalImageView.isHidden = false
        } else {
            selectedIntervalImageView.isHidden = true
        }
    }
    
    func getUserFullNameFromID(for id: String) -> String {
        if let user = groupsUsersCache.value(forKey: id) {
            return user.getFullName().uppercased()
        } else {
            //Fetch User
            FirebaseManager.shared.fetchUserDocumentData(with: id) { [weak self] result in
                switch result {
                case .success(let ttUser):
                    self?.groupsUsersCache.insert(ttUser, forKey: id)
                    self?.createdByUserLabel.text = ttUser.getFullName().uppercased()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        return id.uppercased()
    }
    
    private func configureCell() {
        let defaultFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        groupNameAndTimeLabel.numberOfLines = 2
        groupNameAndTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        createdByUserLabel.font = UIFont.boldSystemFont(ofSize: defaultFontSize * 0.8)
        createdByUserLabel.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = .clear
        selectionStyle = .none
        isUserInteractionEnabled = false
        
        let onTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectInterval))
        addGestureRecognizer(onTapGestureRecognizer)
        
        let vStackView = UIStackView()
        vStackView.axis = .vertical
        vStackView.distribution = .fill
        vStackView.alignment = .leading
        vStackView.spacing = 5
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStackView)
        
        let hStackView = UIStackView()
        hStackView.axis = .horizontal
        hStackView.distribution = .fill
        hStackView.alignment = .center
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        hStackView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        hStackView.addArrangedSubview(groupNameAndTimeLabel)
        
        vStackView.addArrangedSubview(hStackView)
        vStackView.addArrangedSubview(createdByUserLabel)
        vStackView.addSubview(hStackView)
        
        selectedIntervalImageView.image = UIImage(systemName: "checkmark.circle.fill")
        selectedIntervalImageView.tintColor = .systemGreen
        selectedIntervalImageView.translatesAutoresizingMaskIntoConstraints = false
        selectedIntervalImageView.isHidden = true
        addSubview(selectedIntervalImageView)
        
        NSLayoutConstraint.activate([
            vStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -50),
            vStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            vStackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            vStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            
            selectedIntervalImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            selectedIntervalImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            selectedIntervalImageView.widthAnchor.constraint(equalToConstant: 25),
            selectedIntervalImageView.heightAnchor.constraint(equalToConstant: 25)
        ])
    }
    
    @objc private func selectInterval() {
        guard let event = event, let delegate = groupOverviewCellDelegate else { return }
        
        if !event.isCreatedByUser {
            delegate.didSelectInterval(for: event)
        }
    }
}

