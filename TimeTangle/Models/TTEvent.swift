//
//  TTEvent.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/22/23.
//

import Foundation

struct TTEvent: FirestoreDataCompatible, Codable, Equatable, Hashable {
    var name: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var createdBy: String
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "startDate": startDate,
            "endDate": endDate,
            "isAllDay": isAllDay,
            "createdBy": createdBy
        ]
    }
    
    static func == (lhs: TTEvent, rhs: TTEvent) -> Bool {
        return lhs.name == rhs.name &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.isAllDay == rhs.isAllDay
    }
    
    func getDateInterval() -> DateInterval {
        return DateInterval(start: self.startDate, end: self.endDate)
    }
}

extension TTEvent {
    var isCreatedByUser: Bool {
        self.createdBy != "TimeTangle"
    }
}

