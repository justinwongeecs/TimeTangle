//
//  RoomAggregateResultVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/3/23.
//

import UIKit
import EventKitUI
import CalendarKit

protocol RoomAggregateResultVCDelegate: AnyObject {
    func updatedAggregateResultVC(events: [Event])
}

class RoomAggregateResultVC: DayViewController {
    
    private var room: TTRoom!
    private var openDateIntervals = [DateInterval]()
    private var usersNotVisible = [String]()
    private var currentPresentedDate: Date!
    
    private var stepperDayHeaderView = UIView()
    private var rightStepper = UIButton(type: .custom)
    private var calendarViewButton = UIButton(type: .custom)
    private var leftStepper = UIButton(type: .custom)
    
    
    weak var roomAggregateResultDelegate: RoomAggregateResultVCDelegate?
    
    required init(room: TTRoom, usersNotVisible: [String]) {
        self.room = room
        self.currentPresentedDate = room.startingDate
        self.usersNotVisible = usersNotVisible
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        dayView = DayView(calendar: calendar)
        view = dayView
        dayView.isHeaderViewVisible = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureStepperDayHeaderView()
        configureTimelinePagerView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        move(to: currentPresentedDate)
        dayView.autoScrollToFirstEvent = true
    }
    
    func setView(usersNotVisible: [String], room: TTRoom) {
        self.usersNotVisible = usersNotVisible
        self.room = room

        dayView.reloadData()
    }
    
    private func configureStepperDayHeaderView() {
        //TODO: maybe subclass in the future?
        view.addSubview(stepperDayHeaderView)
        stepperDayHeaderView.isUserInteractionEnabled = true
        stepperDayHeaderView.frame.size = CGSize(width: UIScreen.main.bounds.size.width, height: 40)
        stepperDayHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 17.0, weight: .bold, scale: .large)
        let tintColor = UIColor.lightGray
        
        leftStepper.setImage(UIImage(systemName: "chevron.left.circle.fill", withConfiguration: largeConfig), for: .normal)
        leftStepper.tintColor = tintColor
        leftStepper.translatesAutoresizingMaskIntoConstraints = false
        leftStepper.addTarget(self, action: #selector(gotoPreviousDate), for: .touchUpInside)
        stepperDayHeaderView.addSubview(leftStepper)
        
        rightStepper.setImage(UIImage(systemName: "chevron.right.circle.fill", withConfiguration: largeConfig), for: .normal)
        rightStepper.tintColor = tintColor
        rightStepper.translatesAutoresizingMaskIntoConstraints = false
        rightStepper.addTarget(self, action: #selector(goToNextDate), for: .touchUpInside)
        stepperDayHeaderView.addSubview(rightStepper)
        
        //CalendarViewButton
        calendarViewButton.layer.cornerRadius = 5.0
        calendarViewButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
        calendarViewButton.setTitleColor(.white, for: .normal)
        calendarViewButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        calendarViewButton.translatesAutoresizingMaskIntoConstraints = false
        calendarViewButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        calendarViewButton.addTarget(self, action: #selector(presentCalendarModalCardVC), for: .touchUpInside)
        stepperDayHeaderView.addSubview(calendarViewButton)
        
        NSLayoutConstraint.activate([
            leftStepper.leadingAnchor.constraint(equalTo: stepperDayHeaderView.leadingAnchor, constant: 10),
            leftStepper.centerYAnchor.constraint(equalTo: stepperDayHeaderView.centerYAnchor),
            
            calendarViewButton.centerYAnchor.constraint(equalTo: stepperDayHeaderView.centerYAnchor),
            calendarViewButton.centerXAnchor.constraint(equalTo: stepperDayHeaderView.centerXAnchor),
            calendarViewButton.widthAnchor.constraint(equalToConstant: 150),
            calendarViewButton.heightAnchor.constraint(equalToConstant: 30),
            
            rightStepper.trailingAnchor.constraint(equalTo: stepperDayHeaderView.trailingAnchor, constant: -10),
            rightStepper.centerYAnchor.constraint(equalTo: stepperDayHeaderView.centerYAnchor),
            
            stepperDayHeaderView.topAnchor.constraint(equalTo: dayView.topAnchor),
            stepperDayHeaderView.leadingAnchor.constraint(equalTo: dayView.leadingAnchor),
            stepperDayHeaderView.trailingAnchor.constraint(equalTo: dayView.trailingAnchor),
            stepperDayHeaderView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func gotoPreviousDate() {
        moveToYesterdayDate()
    }
    
    @objc private func goToNextDate() {
        moveToTomorrowDate()
    }
    
    
    @objc private func presentCalendarModalCardVC() {
        let calendarModalCardVC = CalendarModalCardVC(startingDate: room.startingDate, endingDate: room.endingDate) { [weak self] selectedDate in
            DispatchQueue.main.async {
                self?.move(to: selectedDate)
            }
        }
        calendarModalCardVC.delegate = self
        calendarModalCardVC.modalPresentationStyle = .overFullScreen
        calendarModalCardVC.modalTransitionStyle = .crossDissolve
       
        present(calendarModalCardVC, animated: true)
    }
    
    private func moveToYesterdayDate() {
        if let yesterdayDate = dayView.calendar.date(byAdding: .day, value: -1, to: currentPresentedDate) {
            move(to: yesterdayDate)
        }
    }
    
    private func moveToTomorrowDate() {
        if let tomorrowDate = dayView.calendar.date(byAdding: .day, value: 1, to: currentPresentedDate) {
            move(to: tomorrowDate)
        }
    }
    
    private func configureStepperButtons() {
        if let yesterdayDate = dayView.calendar.date(byAdding: .day, value: -1, to: currentPresentedDate) {
            let result = Calendar.current.compare(yesterdayDate, to: room.startingDate, toGranularity: .day)
            if result == .orderedSame || result == .orderedDescending{
                leftStepper.isEnabled = true
            } else if result == .orderedAscending {
                //Yesterday date is before room.startingDate
                leftStepper.isEnabled = false
            }
        }
        
        if let tomorrowDate = dayView.calendar.date(byAdding: .day, value: 1, to: currentPresentedDate) {
            let result = Calendar.current.compare(tomorrowDate, to: room.endingDate, toGranularity: .day)
            if result == .orderedSame || result == .orderedAscending{
                rightStepper.isEnabled = true
            } else if result == .orderedDescending {
                //room date is before room.endingDate
                rightStepper.isEnabled = false
            }
        }
    }
    
    
    private func configureTimelinePagerView() {
        NSLayoutConstraint.activate([
            dayView.timelinePagerView.topAnchor.constraint(equalTo: stepperDayHeaderView.bottomAnchor),
            dayView.timelinePagerView.leadingAnchor.constraint(equalTo: dayView.leadingAnchor),
            dayView.timelinePagerView.trailingAnchor.constraint(equalTo: dayView.trailingAnchor),
            dayView.timelinePagerView.bottomAnchor.constraint(equalTo: dayView.bottomAnchor)
        ])
    }
    
    //MARK: - Event Data Source
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        guard let room = room else { return [] }
        
        var events = [Event]()
        openDateIntervals = [DateInterval]()

        for ttEvent in room.events {
            let newEvent = Event()
            newEvent.text = ttEvent.name
            newEvent.dateInterval = DateInterval(start: ttEvent.startDate, end: ttEvent.endDate)
            newEvent.color = .systemGreen
            newEvent.isAllDay = ttEvent.isAllDay
            newEvent.lineBreakMode = .byTruncatingTail
            events.append(newEvent)
        }
        
        let openIntervalEvents = createEventsForOpenIntervals(with: room.events)
        events.append(contentsOf: openIntervalEvents)
        
        //show empty state view if there are not events
        if events.isEmpty {
            showEmptyStateView(with: "No Events", in: view)
        } else {
            removeEmptyStateView(in: view)
        }
        
        if let delegate = roomAggregateResultDelegate {
            delegate.updatedAggregateResultVC(events: openIntervalEvents)
        }
        
        return events
    }
    
    func createEventsForOpenIntervals(with occupiedEvents: [TTEvent]) -> [Event] {
        var openInternalEvents = [Event]()
        guard let room = room else { return [Event]() }
        
        var startingComparisonDate = room.startingDate
        for occupiedEvent in occupiedEvents {
            //if startingComparisonDate equals the next occupied start date continue to find next starting date that does not conflict
            if startingComparisonDate == occupiedEvent.startDate {
                startingComparisonDate = occupiedEvent.endDate
                continue
            }
            
            if startingComparisonDate < occupiedEvent.startDate {
                openDateIntervals.append(DateInterval(start: startingComparisonDate, end: occupiedEvent.startDate))
                startingComparisonDate = occupiedEvent.endDate
            }
        }
        
        //add last open interval if there is one ending at room's end date
        openDateIntervals.append(DateInterval(start: startingComparisonDate, end: room.endingDate))
        
        //create events based on openIntervals
        for openInterval in openDateIntervals {
            let newEvent = Event()
            newEvent.text = "Open Interval"
            newEvent.dateInterval = openInterval
            newEvent.color = .systemPurple
            newEvent.lineBreakMode = .byTruncatingTail
            openInternalEvents.append(newEvent)
        }
        return openInternalEvents
    }
    
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let eventDescriptor = eventView.descriptor else { return }
        let ekManager = EventKitManager()
        let ekEvent = ekManager.createEKEventFromEventDescriptor(for: eventDescriptor)
        
        presentDetailView(ekEvent)
    }
    
    private func presentDetailView(_ ekEvent: EKEvent) {
        let eventViewController = EKEventViewController()
        eventViewController.event = ekEvent
        eventViewController.allowsCalendarPreview = true
        eventViewController.allowsEditing = false
        navigationController?.pushViewController(eventViewController, animated: true)
    }
    
    override func dayView(dayView: DayView, willMoveTo date: Date) {
        calendarViewButton.setTitle(date.formatted(with: "MMM d y"), for: .normal)
        self.currentPresentedDate = date
        configureStepperButtons()
    }
}

//MARK: - Delegates

extension RoomAggregateResultVC: CloseButtonDelegate {
    func didDismissPresentedView() {
        dismiss(animated: true)
    }
}