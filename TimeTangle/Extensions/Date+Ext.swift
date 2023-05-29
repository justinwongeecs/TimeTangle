//
//  Date+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/18/23.
//

import Foundation

extension Date {
    func formatted(with format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        return dateFormatter.string(from: self)
    }
    
    func getYearComponent() -> Int {
        return Calendar.current.component(.year, from: self)
    }
    
    func getMonthComponent() -> Int {
        return Calendar.current.component(.month, from: self)
    }
    
    func getDayComponent() -> Int {
        return Calendar.current.component(.day, from: self)
    }
    
    func compare(with date: Date, toGranularity: Calendar.Component) -> ComparisonResult {
        return Calendar.current.compare(self, to: date, toGranularity: toGranularity)
    }
    
    func getDateWithMonthOffset(by monthOffset: Int) -> Date? {
        let calendar = Calendar.current
        var dateComponent = DateComponents()
        dateComponent.month = monthOffset
        if let monthOffsetedDate = calendar.date(byAdding: dateComponent, to: self) {
            return monthOffsetedDate
        }
        return nil
    }
}
