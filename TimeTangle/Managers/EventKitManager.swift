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
    
    let store = EKEventStore()
    
//    init(completed: @escaping(Result<Void, TTError>) -> Void) {
//        store.requestAccess(to: .event) { granted, error in
//            //TODO: parse error and give more specific error messages
//            guard let _ = error, granted == false else {
//                completed(.success(()))
//                return
//            }
//            completed(.failure(.unableToGetEventKitAccess))
//        }
//    }
    
    init() {
        store.requestAccess(to: .event) { [weak self] granted, error in
            //TODO: parse error and give more specific error messages
            guard let _ = error, granted == false else {
                //listen to calendar event changes
                NotificationCenter.default.addObserver(self, selector: Selector("storeChanged:"), name: .EKEventStoreChanged, object: self?.store)
                return
            }
        }
    }
    
    @objc private func storeChanged() {
        updateUserTTEvents()
    }
    
    //Get the user events up to a certain date
    func getCurrentEKEvents(upto upperDateBound: Date) -> [EKEvent]? {
        let calendar = Calendar.current
        var lastYearFromTodayComponents = DateComponents()
        lastYearFromTodayComponents.year = -1
        let lastYearFromTodayDate = Calendar.current.date(byAdding: lastYearFromTodayComponents, to: Date()) ?? Date()
        //start date components (start of today)
        let startOfTodaysDate = calendar.startOfDay(for: lastYearFromTodayDate)
        
        //create the predicate from the event store's instance methdo
        var predicate: NSPredicate? = nil
        predicate = store.predicateForEvents(withStart: startOfTodaysDate, end: upperDateBound, calendars: nil)
        
        var foundEvents: [EKEvent]? = nil
        if let predicate = predicate {
            foundEvents = store.events(matching: predicate)
        }
        
        return foundEvents
    }
    
    private func convertEKEventToTTEvent(for event: EKEvent) -> TTEvent {
        return TTEvent(name: event.title, startDate: event.startDate, endDate: event.endDate, isAllDay: event.isAllDay)
    }
    
    //should be called in the beginning of app
    func storeUserEventsToFirestore(with ekEvents: [EKEvent], for username: String) {
        let ttEvents = ekEvents.filter{ !$0.isAllDay }.map{ convertEKEventToTTEvent(for: $0) }
        do {
            //FIXME: Do Error handing better here
            let encodedTTEvents = try ttEvents.map { try Firestore.Encoder().encode($0) }
            let updatedData = [
                "events": encodedTTEvents
            ]
            
            FirebaseManager.shared.updateUserData(for: username, with: updatedData) { error in
                guard let _ = error else { return }
            }
        } catch {
            print("Store Events Error")
        }
    }
    
    func updateUserTTEvents() {
        guard let currentUserUsername = FirebaseManager.shared.currentUser?.username else { return }
        
        //FIXME: Find a better way than just fetching a period of a year from now
        var oneYearFromNowComponents = DateComponents()
        oneYearFromNowComponents.year = 2
        
        //FIXME: Temporary: Eventually save last "used" date in UserDefaults 
        var lastYearFromTodayComponents = DateComponents()
        lastYearFromTodayComponents.year = -1
        let lastYearFromTodayDate = Calendar.current.date(byAdding: lastYearFromTodayComponents, to: Date()) ?? Date()
        guard let oneYearFromNowDate = Calendar.current.date(byAdding: oneYearFromNowComponents, to: lastYearFromTodayDate) else { return }
        print("oneyearfromnowdate: \(oneYearFromNowDate)")
        
        guard let allEventsUpToOneYearFromNow = getCurrentEKEvents(upto: oneYearFromNowDate) else { return }
        print("AllEventsUpToOneYear: \(allEventsUpToOneYearFromNow)")
        storeUserEventsToFirestore(with: allEventsUpToOneYearFromNow, for: currentUserUsername)
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
