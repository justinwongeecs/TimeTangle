//
//  CalendarModalCardVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/18/23.
//

import UIKit

//Only Supports Single Date Selection
class CalendarModalCardVC: TTModalCardVC {
    
    private let calendarView = UICalendarView()
    
    private var startingDate: Date!
    private var endingDate: Date!
    private var dateSelectionClosure: (Date) -> Void
    
    required init(startingDate: Date,
                  endingDate: Date,
                  closeButtonClosure: @escaping () -> Void,
                  dateSelectionClosure: @escaping((Date) -> Void)) {
        self.startingDate = startingDate
        self.endingDate = endingDate
        self.dateSelectionClosure = dateSelectionClosure
        super.init(closeButtonClosure: closeButtonClosure)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCalendarView()
    }
    
    private func configureCalendarView() {
        calendarView.tintColor = .systemGreen
        
        let calendarViewDateRange = DateInterval(start: startingDate, end: endingDate)
        containerView.addSubview(calendarView)
        calendarView.calendar = Calendar(identifier: .gregorian)
        calendarView.availableDateRange = calendarViewDateRange
        calendarView.fontDesign = .rounded
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
            calendarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            calendarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            calendarView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
        ])
    }
}

//MARK: - Delegates
extension CalendarModalCardVC: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        if let dateComponents = dateComponents, let date = Calendar.current.date(from: dateComponents) {
            dateSelectionClosure(date)
            closeButtonClosure()
        }
    }
}
