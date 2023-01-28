//
//  RoomSummaryView.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/18/23.
//

import UIKit
import CalendarKit

class RoomSummaryVC: UIViewController {
    
    private let room: TTRoom!
    private var notVisibleMembers = [String]()


    private let timesStackView = UIStackView()
    private let availableTimesView = RoomTimesView(type: .availableTimes)
    private let unAvailableTimesView = RoomTimesView(type: .unAvailableTimes)
    
    init(room: TTRoom, notVisibleMembers: [String]) {
        self.room = room
        self.notVisibleMembers = notVisibleMembers
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureVC()
        configureTimesStackView()
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func configureVC() {
        view.backgroundColor = .systemBackground
        title = "\(room.name) Summary"
    }
    
    func updateEvents(for events: [Event]) {
        availableTimesView.updateEvents(for: events)
        unAvailableTimesView.updateEvents(for: events)
    }
    
    func updateNotVisibleMembers(for members: [String]) {
        availableTimesView.updateNotVisibleMembers(for: members)
        unAvailableTimesView.updateNotVisibleMembers(for: members)
    }
    
    private func configureTimesStackView() {
        view.addSubview(timesStackView)
        timesStackView.distribution = .fillEqually
        timesStackView.spacing = 20.0
        timesStackView.axis = .vertical
        timesStackView.translatesAutoresizingMaskIntoConstraints = false

        timesStackView.addArrangedSubview(availableTimesView)
        timesStackView.addArrangedSubview(unAvailableTimesView)

        NSLayoutConstraint.activate([

            timesStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            timesStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timesStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timesStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }
}


//MARK: - RoomAvailableTimesView
class RoomTimesView: UIView {
    
    enum RoomTimesViewType {
        case availableTimes
        case unAvailableTimes
    }
    
    private var events = [Event]()
    
    private let viewType: RoomTimesViewType!
    private let headerLabel = UILabel()
    private let timesTable = UITableView()
    
    init(type: RoomTimesViewType) {
        viewType = type
        super.init(frame: .zero)
        configureView()
        configureHeaderLabel()
        configureAvailableTimesTable()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateEvents(for events: [Event]) {
        if viewType == .unAvailableTimes {
            //FIXME: - How to identify if event is an open interval event? Improve.
            self.events = events.filter({ $0.color == .systemPurple })
        } else { // availableTimes
            //FIXME: - How to identify if event is not an open interval event? Improve.
            self.events = events.filter({ $0.color != .systemPurple })
        }
        DispatchQueue.main.async {
            self.timesTable.reloadData()
        }
    }
    
    func updateNotVisibleMembers(for: [String]) {
        
    }
    
    private func configureView() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 10
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureHeaderLabel() {
        addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = viewType == .availableTimes ? "Available Times" : "Unavailable Times"
        headerLabel.textAlignment = .left
        headerLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        
        let horizontalPadding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
            headerLabel.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    private func configureAvailableTimesTable() {
        addSubview(timesTable)
        timesTable.backgroundColor = .clear
        timesTable.translatesAutoresizingMaskIntoConstraints = false
        timesTable.dataSource = self
        timesTable.delegate = self
        timesTable.register(RoomTimesViewCell.self, forCellReuseIdentifier: RoomTimesViewCell.reuseID)
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            timesTable.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: padding / 2),
            timesTable.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            timesTable.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            timesTable.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
    }
}

extension RoomTimesView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = timesTable.dequeueReusableCell(withIdentifier: RoomTimesViewCell.reuseID) as! RoomTimesViewCell
        cell.set(for: events[indexPath.row], ofType: viewType)
        print("Event: \(events[indexPath.row])")
        return cell
    }
}

//MARK: - RoomTimesViewCell
class RoomTimesViewCell: UITableViewCell {
    
    static let reuseID = "RoomTimesViewCell"
    
    private let timePeriodLabel = UILabel()
//    private let likeTimeButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
//        configureLikeTimeButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(for event: Event, ofType viewType: RoomTimesView.RoomTimesViewType) {
        if viewType == .unAvailableTimes {
            timePeriodLabel.textColor = .systemRed
        } else {
            timePeriodLabel.textColor = .systemGreen
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        timePeriodLabel.text = "\(dateFormatter.string(from: event.dateInterval.start)) - \(dateFormatter.string(from: event.dateInterval.end))"
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

