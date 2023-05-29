//
//  Event+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/19/23.
//

import CalendarKit

extension Event {
    func toTTEvent() -> TTEvent {
        return TTEvent(name: self.text, startDate: self.dateInterval.start, endDate: self.dateInterval.end, isAllDay: self.isAllDay, createdBy: self.userInfo.debugDescription)
    }
}
