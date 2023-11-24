//
//  EventKitManager.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/30/22.
//

import Foundation
import EventKit
import FirebaseFirestore
import CalendarKit

class EventKitManager {
    static let shared = EventKitManager()
    var store = EKEventStore()
    
    init() {
        store.requestFullAccessToEvents { granted, error in
            //            guard let _ = error, granted == false else {
            //                //listen to calendar event changes
            ////                NotificationCenter.default.addObserver(self, selector: Selector("storeChanged:"), name: .EKEventStoreChanged, object: self?.store)
            //                return
            //            }
        }
    }
//
//    @objc private func storeChanged() {
//        updateUserTTEvents()
//    }
    
    //Get the user events up to a certain date
    private func getCurrentEKEvents(from startDateBound: Date, to upperDateBound: Date) -> [EKEvent] {
        let calendar = Calendar.current
        //start date components (start of today)
        let startOfTodaysDate = calendar.startOfDay(for: startDateBound)
        //create the predicate from the event store's instance methdo
        var predicate: NSPredicate? = nil
        predicate = store.predicateForEvents(withStart: startOfTodaysDate, end: upperDateBound, calendars: nil)
        
        var foundEvents = [EKEvent]()
        if let predicate = predicate {
            foundEvents = store.events(matching: predicate)
        }
        
        return foundEvents
    }
    
    func convertEKEventToTTEvent(for event: EKEvent) -> TTEvent? {
        guard let currentUser = FirebaseManager.shared.currentUser else { return nil }
        return TTEvent(name: event.title, startDate: event.startDate, endDate: event.endDate, isAllDay: event.isAllDay, createdBy: currentUser.id)
    }
    
    func getUserTTEvents(from startDateBound: Date, to upperDateBound: Date) -> [TTEvent] {
        var ttEvents = [TTEvent]()
        let ekEvents = getCurrentEKEvents(from: startDateBound, to: upperDateBound)
        for ekEvent in ekEvents {
            if let convertedEKEventToTTEvent = convertEKEventToTTEvent(for: ekEvent) {
                ttEvents.append(convertedEKEventToTTEvent)
            }
        }
        
        return ttEvents
    }
    
    func createEKEvent(isAllDay: Bool, title: String, startDate: Date, endDate: Date) -> EKEvent {
        let ekEvent = EKEvent(eventStore: store)
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        ekEvent.isAllDay = isAllDay
        ekEvent.title = title
        return ekEvent
    }
    
    func createEKEventFromEventDescriptor(for eventDescriptor: EventDescriptor) -> EKEvent {
        return createEKEvent(isAllDay: eventDescriptor.isAllDay, title: eventDescriptor.text, startDate: eventDescriptor.dateInterval.start, endDate: eventDescriptor.dateInterval.end)
    }
}
