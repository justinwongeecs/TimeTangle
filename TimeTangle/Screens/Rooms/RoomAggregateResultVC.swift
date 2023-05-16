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
    
    private var room: TTRoom?
    private var allUsersEvents = [TTEvent]()
    private var openIntervals = [DateInterval]()
    private var usersNotVisible = [String]()
//    private var openIntervalIndex = 1
    
    weak var roomAggregateResultDelegate: RoomAggregateResultVCDelegate?
    
    override func loadView() {
        dayView = DayView(calendar: calendar)
//        dayView.state = DayViewState(date: room?.startingDate ?? Date())
        view = dayView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dayView.isHeaderViewVisible = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        move(to: room?.startingDate ?? Date())
//        fetchAllUsersEvents()
        dayView.autoScrollToFirstEvent = true
    }
    
    
    func setView(usersNotVisible: [String], room: TTRoom) {
        self.usersNotVisible = usersNotVisible
        self.room = room
//        fetchAllUsersEvents()
    }
    
    private func configureTimelinePagerView() {
        NSLayoutConstraint.activate([
            dayView.timelinePagerView.topAnchor.constraint(equalTo: dayView.topAnchor),
            dayView.timelinePagerView.leadingAnchor.constraint(equalTo: dayView.leadingAnchor),
            dayView.timelinePagerView.trailingAnchor.constraint(equalTo: dayView.trailingAnchor),
            dayView.timelinePagerView.bottomAnchor.constraint(equalTo: dayView.bottomAnchor)
        ])
    }
    
    //MARK: - Event Data Source
    
//    private func fetchAllUsersEvents() {
//        guard let roomUsers = room?.users else { return }
//        //fetch user's events
//        FirebaseManager.shared.fetchMultipleUsersDocumentData(with: roomUsers) { [weak self] result in
//            switch result {
//            case .success(let users):
//                //setting allUsersEvents to an empty array here fixes the bug where there are duplicate events interesting....
//                //maybe because of the success case so it's in sync?
//                self?.allUsersEvents = []
//                //FIXME: Is this the best place to have the filtering users logic? Because I want to minimize firebase fetch requests
//                let filteredVisibleUsers = users.filter { !(self?.usersNotVisible.contains($0.username) ?? true) }
//                print("usersNotVisible: \(self?.usersNotVisible) filteredVisibleUsers: \(filteredVisibleUsers.map{$0.username})")
//                filteredVisibleUsers.map{$0.events}.forEach{ self?.allUsersEvents.append(contentsOf: $0) }
//                self?.reloadData()
//            case .failure(let error):
//                self?.presentTTAlert(title: "Cannot fetch user", message: error.rawValue, buttonTitle: "Ok")
//            }
//        }
//    }
    
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        print("event for date")
        var events = [Event]()
        openIntervals = [DateInterval]()
        
        let fetchedUserEventsMatchingDate = allUsersEvents.filter({
            Calendar.current.isDate(date, equalTo: $0.startDate, toGranularity: .day)
        })
        
        if let room = room {
            var eventsBetweenStartingEndingDates = fetchedUserEventsMatchingDate.filter({
                $0.startDate >= room.startingDate && $0.endDate <= room.endingDate
            })
            eventsBetweenStartingEndingDates = eventsBetweenStartingEndingDates.sorted(by: ({ $0.startDate < $1.startDate}))
            
            for ttEvent in eventsBetweenStartingEndingDates {
                let newEvent = Event()
                newEvent.text = ttEvent.name
                newEvent.dateInterval = DateInterval(start: ttEvent.startDate, end: ttEvent.endDate)
                newEvent.color = .systemGreen
                newEvent.isAllDay = ttEvent.isAllDay
                newEvent.lineBreakMode = .byTruncatingTail
                events.append(newEvent)
            }
            
            if let openIntervalEvents = createEventsForOpenIntervals(with: eventsBetweenStartingEndingDates) {
                events.append(contentsOf: openIntervalEvents)
            }
            
            //show empty state view if there are not events
            if events.isEmpty {
                showEmptyStateView(with: "No Events", in: view)
            } else {
                removeEmptyStateView(in: view)
            }
            
            if let delegate = roomAggregateResultDelegate {
                delegate.updatedAggregateResultVC(events: events)
            }
            
            return events
        }
        return []
    }
    
    private func createEventsForOpenIntervals(with occupiedEvents: [TTEvent]) -> [Event]?{
        var openInternalEvents = [Event]()
        guard let room = room else { return nil }
        
        var startingComparisonDate = room.startingDate
        for occupiedEvent in occupiedEvents {
            //if startingComparisonDate equals the next occupied start date continue to find next starting date that does not conflict
            if startingComparisonDate == occupiedEvent.startDate {
                print("skip")
                startingComparisonDate = occupiedEvent.endDate
                continue
            }
            
            if startingComparisonDate < occupiedEvent.startDate {
                openIntervals.append(DateInterval(start: startingComparisonDate, end: occupiedEvent.startDate))
                startingComparisonDate = occupiedEvent.endDate
            }
        }
        
        //add last open interval if there is one ending at room's end date
        openIntervals.append(DateInterval(start: startingComparisonDate, end: room.endingDate))
        
        //create events based on openIntervals
        for openInterval in openIntervals {
            let newEvent = Event()
            newEvent.text = "Open Interval \(openIntervals.firstIndex(of: openInterval))"
            newEvent.dateInterval = openInterval
            newEvent.color = .systemPurple
            newEvent.lineBreakMode = .byTruncatingTail
            openInternalEvents.append(newEvent)
//            openIntervalIndex += 1
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
    
//    public func moveToFirstOpenInterval() {
//        print(openIntervals.count)
//        DispatchQueue.main.async {
//            if self.openIntervals.count > 0 {
//                self.move(to: self.openIntervals[0].start)
//            }
//        }
//    }
}
