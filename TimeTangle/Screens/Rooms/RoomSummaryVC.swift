//
//  RoomSummaryView.swift
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

class RoomSummaryVC: UIViewController {
    
    private let room: TTRoom!
    private var notVisibleMembers = [String]()
    private var timesHeaderLabel: UILabel!
    private var timesTableView: UITableView!
    private var splittedTTEvents: [TTEvent]!
//    private let timesStackView = UIStackView()
//    private let availableTimesView = RoomTimesView(type: .availableTimes)
//    private let unAvailableTimesView = RoomTimesView(type: .unAvailableTimes)
    
    init(room: TTRoom, notVisibleMembers: [String]) {
        self.room = room
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
        configureTimeHeaderLabel()
        configureTimesTable()
        configureConstraints()
        navigationController?.navigationBar.prefersLargeTitles = false
        
        splitTimeIntervalsByDays()
        DispatchQueue.main.async {
            self.timesTableView.reloadData()
        }
    }

    private func configureVC() {
        view.backgroundColor = .systemBackground
        title = "\(room.name) Summary"
    }
    
    private func configureTimeHeaderLabel() {
        timesHeaderLabel = UILabel()
        timesHeaderLabel.text = "Times:"
        timesHeaderLabel.textAlignment = .left
        timesHeaderLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        timesHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timesHeaderLabel)
    }
    
    private func configureTimesTable() {
        timesTableView = UITableView()
        timesTableView.translatesAutoresizingMaskIntoConstraints = false
        timesTableView.dataSource = self
        timesTableView.delegate = self
        timesTableView.register(RoomTimesViewCell.self, forCellReuseIdentifier: RoomTimesViewCell.reuseID)
        view.addSubview(timesTableView)
    }
    
    private func configureConstraints() {
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            //TimesHeaderLabel
            timesHeaderLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            timesHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            
            timesTableView.topAnchor.constraint(equalTo: timesHeaderLabel.bottomAnchor, constant: padding),
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
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: currentDate)!
            let newTTEvent = TTEvent(name: ttEvent.name, startDate: startOfDay, endDate: endOfDay, isAllDay: ttEvent.isAllDay)
            
            ttEvents.append(newTTEvent)
            currentDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        }
        
        return ttEvents
    }
}

extension RoomSummaryVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return splittedTTEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = timesTableView.dequeueReusableCell(withIdentifier: RoomTimesViewCell.reuseID) as! RoomTimesViewCell
        let event = splittedTTEvents[indexPath.row]
        if event.name.hasPrefix("Open") {
            cell.set(for: event, ofType: .availableTimes)
            
        } else {
            cell.set(for: event, ofType: .unAvailableTimes)
        }

        return cell
    }
}

//MARK: - RoomTimesViewCell
class RoomTimesViewCell: UITableViewCell {
    
    static let reuseID = "RoomTimesViewCell"
    
    private var dateLabel: UILabel!
    private var timePeriodLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        dateLabel = UILabel()
        timePeriodLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(for event: TTEvent, ofType viewType: RoomTimesViewType) {
        if viewType == .unAvailableTimes {
            timePeriodLabel.textColor = .systemRed
        } else {
            timePeriodLabel.textColor = .systemGreen
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.amSymbol = "AM"
        timeFormatter.pmSymbol = "PM"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/dd/yyyy"
        
        timePeriodLabel.text = "\(dateFormatter.string(from: event.startDate)): \(timeFormatter.string(from: event.startDate)) - \(timeFormatter.string(from: event.endDate))"
    }
    
    private func configureCell() {
        addSubview(timePeriodLabel)
        
        backgroundColor = .clear
        isUserInteractionEnabled = true
        selectionStyle = .none
        timePeriodLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let verticalPadding: CGFloat = 5
        
        NSLayoutConstraint.activate([
            timePeriodLabel.topAnchor.constraint(equalTo: topAnchor, constant: verticalPadding),
            timePeriodLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            timePeriodLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            timePeriodLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -verticalPadding)
        ])
    }
    
    //TODO: - Implement Times Voting 
//    private func configureLikeTimeButton() {
//        //adding likeTimeButton to contentView so that it can be clickable in cell
//        contentView.addSubview(likeTimeButton)
//        var config = UIButton.Configuration.plain()
//        config.image = UIImage(systemName: "hand.thumbsup", withConfiguration: UIImage.SymbolConfiguration(scale: .small))
//        likeTimeButton.configuration = config
//        likeTimeButton.translatesAutoresizingMaskIntoConstraints = false
//        likeTimeButton.addTarget(self, action: #selector(likeTime), for: .touchUpInside)
//
//        NSLayoutConstraint.activate([
//            likeTimeButton.topAnchor.constraint(equalTo: topAnchor),
//            likeTimeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
//            likeTimeButton.bottomAnchor.constraint(equalTo: bottomAnchor),
//            likeTimeButton.heightAnchor.constraint(equalToConstant: 40)
//        ])
//    }
//
//    @objc private func likeTime() {
//        //remove like
//    }
}

