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
    private let confirmButton = UIButton(type: .custom)
    
    private var startingDate: Date!
    private var endingDate: Date!
    private var dateSelectionClosure: (Date) -> Void
    private var selectedDate: Date?
    
    required init(startingDate: Date, endingDate: Date, dateSelectionClosure: @escaping((Date) -> Void)) {
        self.startingDate = startingDate
        self.endingDate = endingDate
        self.dateSelectionClosure = dateSelectionClosure
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureConfirmButton()
        configureCalendarView()
    }
    
    private func configureCalendarView() {
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
            calendarView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -padding)
        ])
    }
    
    private func configureConfirmButton() {
        containerView.addSubview(confirmButton)
        confirmButton.backgroundColor = .systemGreen
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        confirmButton.isHidden = true
        confirmButton.layer.cornerRadius = 10.0
        confirmButton.layer.opacity = 0.0
        confirmButton.addTarget(self, action: #selector(clickedConfirm), for: .touchUpInside)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            confirmButton.heightAnchor.constraint(equalToConstant: 40),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 70),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -70),
            confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }
    
    private func presentConfirmButton() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .beginFromCurrentState) {
            self.confirmButton.layer.opacity = 1.0
            self.confirmButton.isHidden = false
            self.heightConstraint.isActive = false
            self.heightConstraint = self.containerView.heightAnchor.constraint(equalToConstant: 450)
            self.heightConstraint.isActive = true
            self.containerView.layoutIfNeeded()
            self.containerView.layoutSubviews()
        }
    }
    
    @objc private func clickedConfirm() {
        if let selectedDate = selectedDate {
            dateSelectionClosure(selectedDate)
            dismissVC()
        }
    }
}

//MARK: - Delegates
extension CalendarModalCardVC: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        if let dateComponents = dateComponents, let date = Calendar.current.date(from: dateComponents) {
            presentConfirmButton()
            self.selectedDate = date
        }
    }
}
