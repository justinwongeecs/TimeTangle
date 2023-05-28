//
//  RoomOverviewVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/18/23.
//

import UIKit
import CalendarKit

enum RoomTimesViewType {
    case availableTimes
    case unAvailableTimes
}

private struct RoomOverviewSection {
    var date: Date
    var events: [TTEvent]
}

class RoomOverviewVC: UIViewController {
    
    private var room: TTRoom!
    private var roomSummarySections: [RoomOverviewSection]!
    private var notVisibleMembers = [String]()
    private var timesTableView: UITableView!
    private var splittedTTEvents: [TTEvent]!
    
    init(room: TTRoom, notVisibleMembers: [String], openIntervals: [TTEvent]) {
        self.room = room
        self.room.events.append(contentsOf: openIntervals)
        self.notVisibleMembers = notVisibleMembers
        self.splittedTTEvents = []
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureVC()
        configureTimesTable()
        navigationController?.navigationBar.prefersLargeTitles = false
        
        splitTimeIntervalsByDays()
        configureRoomSummarySections()
        DispatchQueue.main.async {
            self.timesTableView.reloadData()
        }
    }
    
    private func configureRoomSummarySections() {
        guard !splittedTTEvents.isEmpty else { return }
        
        var sections = [RoomOverviewSection]()
        let firstEvent = splittedTTEvents.first!
        sections.append(RoomOverviewSection(date: firstEvent.startDate, events: [firstEvent]))
        
        for index in stride(from: 1, to: splittedTTEvents.count, by: 1) {
            let event = splittedTTEvents[index]
            
            if let index = sections.firstIndex(where: { $0.date.compare(with: event.startDate, toGranularity: .day) == .orderedSame}) {
                sections[index].events.append(event)
            } else {
                sections.append(RoomOverviewSection(date: event.startDate, events: [event]))
            }
        }
        
        //Sort events inside each section
        for index in 0..<sections.count {
            sections[index].events.sort(by: { $0.startDate < $1.startDate })
        }
        
        //Sort sections
        roomSummarySections = sections.sorted(by: { $0.date < $1.date })
    }

    private func configureVC() {
        view.backgroundColor = .systemBackground
        title = "\(room.name) Overview"
    }
    
    private func configureTimesTable() {
        timesTableView = UITableView()
        timesTableView.translatesAutoresizingMaskIntoConstraints = false
        timesTableView.dataSource = self
        timesTableView.delegate = self
        timesTableView.register(RoomOverviewCell.self, forCellReuseIdentifier: RoomOverviewCell.reuseID)
        view.addSubview(timesTableView)
        
        let padding: CGFloat = 10

        NSLayoutConstraint.activate([
            timesTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            timesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            timesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            timesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func splitTimeIntervalsByDays() {
        for ttEvent in room.events {
            //check if ttEvent's start and end date are within the same date
            if !checkIfTwoDatesAreSameDay(first: ttEvent.startDate, second: ttEvent.endDate) {
                splittedTTEvents.append(contentsOf: getTTEventsIntervalsForDays(ttEvent: ttEvent))
            } else {
                splittedTTEvents.append(ttEvent)
            }
        }
    }
    
    private func checkIfTwoDatesAreSameDay(first firstDate: Date, second secondDate: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month, .day], from: firstDate)
        let components2 = calendar.dateComponents([.year, .month, .day], from: secondDate)
        return components1.year == components2.year &&
        components1.month == components2.month &&
        components1.day == components2.day
    }
    
    private func getTTEventsIntervalsForDays(ttEvent: TTEvent) -> [TTEvent] {
        let calendar = Calendar.current
        var currentDate = ttEvent.startDate
        var ttEvents = [TTEvent]()
        
        while currentDate <= ttEvent.endDate {
            let startOfDay = calendar.startOfDay(for: currentDate)
            var endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: currentDate)!
            
            if endOfDay >= ttEvent.endDate {
                endOfDay = ttEvent.endDate
            }
            
            let newTTEvent = TTEvent(name: ttEvent.name, startDate: currentDate, endDate: endOfDay, isAllDay: ttEvent.isAllDay)
            
            ttEvents.append(newTTEvent)
            currentDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        }
        
        return ttEvents
    }
}

//MARK: - RoomOverviewVC TableView Delegates
extension RoomOverviewVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return roomSummarySections.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.text = roomSummarySections[section].date.formatted(with: "M/d/yyyy")
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
        return roomSummarySections[section].events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = timesTableView.dequeueReusableCell(withIdentifier: RoomOverviewCell.reuseID) as! RoomOverviewCell
        
        let section = roomSummarySections[indexPath.section]
        let event = section.events[indexPath.row]
     
        //FIX: Really Janky Way of detecting if an event is an open interval or not
        if event.name.hasPrefix("Open") {
            cell.set(for: event, ofType: .availableTimes)
            
        } else {
            cell.set(for: event, ofType: .unAvailableTimes)
        }

        return cell
    }
}

//MARK: - RoomOverviewCell
class RoomOverviewCell: UITableViewCell {
    
    static let reuseID = "RoomOverviewCell"
    
    private var roomNameLabel: UILabel!
    private var timeIntervalLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(for event: TTEvent, ofType viewType: RoomTimesViewType) {
        if viewType == .unAvailableTimes {
            roomNameLabel.textColor = .systemRed
            timeIntervalLabel.textColor = .systemRed
        } else {
            roomNameLabel.textColor = .systemGreen
            timeIntervalLabel.textColor = .systemGreen
        }
    
        //roomNameLabel
        roomNameLabel.text = "\(event.name): "
        
        //timeIntervalLabel
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.amSymbol = "AM"
        timeFormatter.pmSymbol = "PM"
        
        let text = "\(timeFormatter.string(from: event.startDate)) - \(timeFormatter.string(from: event.endDate))"
        timeIntervalLabel.text = text
    }
    
    private func configureCell() {
        let defaultFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        
        roomNameLabel = UILabel()
        roomNameLabel.font = UIFont.boldSystemFont(ofSize: defaultFontSize)
        roomNameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(roomNameLabel)
        
        timeIntervalLabel = UILabel()
        timeIntervalLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeIntervalLabel)
        
        backgroundColor = .clear
        isUserInteractionEnabled = false
        selectionStyle = .none
        
        let hStackView = UIStackView()
        hStackView.axis = .horizontal
        hStackView.distribution = .fill
        hStackView.alignment = .center
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        hStackView.addArrangedSubview(roomNameLabel)
        hStackView.addArrangedSubview(timeIntervalLabel)
        addSubview(hStackView)
        
        NSLayoutConstraint.activate([
            hStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            hStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            hStackView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}

