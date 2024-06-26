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

//MARK: - TTEventStoreError
enum TTEventStoreError: Error {
    case denied
    case restricted
    case unknown
    case upgrade
}

extension TTEventStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .denied:
            return NSLocalizedString("The app doesn't have permission to Calendar in Settings.", comment: "Access denied")
         case .restricted:
            return NSLocalizedString("This device doesn't allow access to Calendar.", comment: "Access restricted")
        case .unknown:
            return NSLocalizedString("An unknown error occured.", comment: "Unknown error")
        case .upgrade:
            let access = "The app has write-only access to Calendar in Settings."
            let update = "Please grant it full access so the app can fetch and delete your events."
            return NSLocalizedString("\(access) \(update)", comment: "Upgrade to full access")
        }
    }
}


//MARK: - EventKitManager
class EventKitManager {
    static let shared = EventKitManager()
    var store = EKEventStore()
    var authorizationStatus: EKAuthorizationStatus
    
    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    func setupEventStore() async throws {
        let response = try await verifyAuthorizationStatus()
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    private func verifyAuthorizationStatus() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            return try await requestFullAccess()
        case .restricted:
            throw TTEventStoreError.restricted
        case .denied:
            throw TTEventStoreError.denied
        case .fullAccess:
            return true
        case .writeOnly:
            throw TTEventStoreError.upgrade
        @unknown default:
            throw TTEventStoreError.unknown
        }

    }

    private func requestFullAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            // Fall back on earlier versions.
            return try await store.requestAccess(to: .event)
        }
    }
    
    //Get the user events up to a certain date
    func getCurrentEKEvents(from startDateBound: Date, to upperDateBound: Date) -> [EKEvent] {
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
        return TTEvent(name: event.title, startDate: event.startDate, endDate: event.endDate, isAllDay: event.isAllDay, createdBy: currentUser.id, eventIdentifier: event.eventIdentifier)
    }
    
    func getUserTTEvents(from startDateBound: Date, to upperDateBound: Date, with userEKEvents: [EKEvent]? = nil) -> [TTEvent] {
        var ttEvents = [TTEvent]()
        var ekEvents = [EKEvent]()
        
        if let userEKEvents = userEKEvents {
            ekEvents = userEKEvents
        } else {
            ekEvents = getCurrentEKEvents(from: startDateBound, to: upperDateBound)
        }
       
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
