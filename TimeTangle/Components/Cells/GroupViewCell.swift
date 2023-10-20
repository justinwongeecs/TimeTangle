//
//  GroupViewCell.swift
//  TimeTangle
//
//  Created by Justin Wong on 10/18/23.
//

import UIKit

class GroupViewCell: UITableViewCell {
    
    static let reuseID = "GroupViewCell"
    
    private var group: TTGroup!
    
    private let labelsStackView = UIStackView()
    private var groupNameLabel = TTTitleLabel(textAlignment: .left, fontSize: 20)
    private let dateCreatedLabel = TTBodyLabel(textAlignment: .left)
    private let updatedGroupIndicatorView = UIView()
    
    private let groupViewCellPadding: CGFloat = 10
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
        addSubview(groupNameLabel)
        addSubview(dateCreatedLabel)
        configureLabelsStackView()
        configureUpdatedGroupIndicatorView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateCellBackgroundColor()
    }
    
    private func updateCellBackgroundColor() {
        if traitCollection.userInterfaceStyle == .dark {
            backgroundColor = .systemIndigo.withAlphaComponent(0.4)
        } else {
            backgroundColor = .systemIndigo.withAlphaComponent(0.2)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureCell() {
        updateCellBackgroundColor()
        layer.borderColor = UIColor.systemIndigo.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 10
        accessoryType = .disclosureIndicator
        selectionStyle = .none
    }
    
    func set(for group: TTGroup, isUpdated: Bool) {
        self.group = group
        groupNameLabel.text = group.name
      
        formatandSetGroupDates()
        updatedGroupIndicatorView.isHidden = isUpdated ? false : true
    
    }
    
    private func formatandSetGroupDates() {
        let formattedStartDate = group.startingDate.formatted(date: .numeric, time: .omitted)
        let formattedEndDate = group.endingDate.formatted(date: .numeric, time: .omitted)
        
        if formattedStartDate == formattedEndDate {
            dateCreatedLabel.text = formattedStartDate
        } else {
            dateCreatedLabel.text = "\(formattedStartDate) - \(formattedEndDate)"
        }
    }
    
    private func configureLabelsStackView() {
        addSubview(labelsStackView)
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.distribution = .fill
        
        labelsStackView.addArrangedSubview(groupNameLabel)
        labelsStackView.addArrangedSubview(dateCreatedLabel)
        
        NSLayoutConstraint.activate([
            labelsStackView.topAnchor.constraint(equalTo: topAnchor, constant: groupViewCellPadding),
            labelsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: groupViewCellPadding + 20),
            labelsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -groupViewCellPadding),
            labelsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -groupViewCellPadding)
        ])
    }
    
    private func configureUpdatedGroupIndicatorView() {
        let widthAndHeight: CGFloat = 10
        updatedGroupIndicatorView.backgroundColor = .systemIndigo
        updatedGroupIndicatorView.frame = CGRect(origin: .zero, size: CGSize(width: widthAndHeight, height: widthAndHeight))
        updatedGroupIndicatorView.layer.cornerRadius = updatedGroupIndicatorView.frame.width / 2
        updatedGroupIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        updatedGroupIndicatorView.isHidden = true 
        addSubview(updatedGroupIndicatorView)
        
        NSLayoutConstraint.activate([
            updatedGroupIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            updatedGroupIndicatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            updatedGroupIndicatorView.widthAnchor.constraint(equalToConstant: widthAndHeight),
            updatedGroupIndicatorView.heightAnchor.constraint(equalToConstant: widthAndHeight)
        ])
    }
}

