//
//  CreateGroupConfirmationVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit

protocol CreateGroupConfirmationVCDelegate: AnyObject {
    func didSuccessfullyCreateGroup()
}

class CreateGroupConfirmationVC: TTModalCardVC {
    
    private var usersInQueue = [TTUser]()
    
    private let containerViewHeader = UIStackView()
    private var headerLabel = TTTitleLabel(textAlignment: .center, fontSize: 18)
    private var groupCodeView: TTGroupCodeView!
    private var groupCode: String!
    let groupNameTextField = UIStackView()
    let textField = TTTextField()
    let confirmationButton = TTButton(backgroundColor: .systemGreen, title: "Tangle!")

    
    weak var createGroupConfirmationDelegate: CreateGroupConfirmationVCDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.text = "Confirm Group Settings"
        configureContainerViewHeader()
        configureGroupCodeView()
        configureGroupNameTitledText()
        configureConfirmationButton()
    }
    
    init(users: [TTUser], closeButtonClosure: @escaping () -> Void) {
        self.usersInQueue = users
        super.init(closeButtonClosure: closeButtonClosure)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureContainerViewHeader() {
        containerView.addSubview(containerViewHeader)
        containerViewHeader.translatesAutoresizingMaskIntoConstraints = false
        containerViewHeader.layer.cornerRadius = 16
        containerViewHeader.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerViewHeader.backgroundColor = .systemBackground
        containerViewHeader.axis = .horizontal
    
        headerLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        let closeButton = TTCloseButton()
        closeButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        
        containerViewHeader.addArrangedSubview(headerLabel)
        containerViewHeader.addArrangedSubview(closeButton)
        
        NSLayoutConstraint.activate([
            containerViewHeader.topAnchor.constraint(equalTo: containerView.topAnchor),
            containerViewHeader.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            containerViewHeader.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            containerViewHeader.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureGroupCodeView() {
        groupCode = generateRandomGroupCode()
        groupCodeView = TTGroupCodeView(codeText: groupCode)
        groupCodeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(groupCodeView)
        
        NSLayoutConstraint.activate([
            groupCodeView.topAnchor.constraint(equalTo: containerViewHeader.bottomAnchor, constant: 10),
            groupCodeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50),
            groupCodeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            groupCodeView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func configureGroupNameTitledText() {
        view.addSubview(groupNameTextField)
        groupNameTextField.translatesAutoresizingMaskIntoConstraints = false
        groupNameTextField.axis = .vertical
        groupNameTextField.distribution = .fillProportionally
        
        let enterGroupNameLabel = UILabel()
        enterGroupNameLabel.text = "Enter Group Name:"
        enterGroupNameLabel.translatesAutoresizingMaskIntoConstraints = false
        enterGroupNameLabel.font = UIFont.boldSystemFont(ofSize: 17)
        
        textField.becomeFirstResponder()
        
        groupNameTextField.addArrangedSubview(enterGroupNameLabel)
        groupNameTextField.addArrangedSubview(textField)
        
        NSLayoutConstraint.activate([
            groupNameTextField.topAnchor.constraint(equalTo: groupCodeView.bottomAnchor, constant: 10),
            groupNameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50),
            groupNameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            groupNameTextField.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func configureConfirmationButton() {
        view.addSubview(confirmationButton)
        confirmationButton.addTarget(self, action: #selector(confirmGroup), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            confirmationButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            confirmationButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50),
            confirmationButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            confirmationButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func generateRandomGroupCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...5).map{ _ in letters.randomElement()! })
    }
    
    @objc private func confirmGroup() {
        guard !textField.text!.isEmpty else {
            self.presentTTAlert(title: "Group Name Can't Be Empty", message: TTError.textFieldsCannotBeEmpty.rawValue, buttonTitle: "Ok")
            return
        }
        
        guard let groupCode = groupCode,
        let currentUser = FirebaseManager.shared.currentUser else { return }
        
        //Create a group instance in Firestore
        let dateAMonthAgoFromToday = Date().getDateWithMonthOffset(by: -1) ?? Date()
        let dateAMonthFromToday = Date().getDateWithMonthOffset(by: 1) ?? Date()
        let newGroup = TTGroup(name: textField.text!, users: usersInQueue.map{$0.id}, code: groupCode, startingDate: Date(), endingDate: Date(), histories: [], events: [], admins: [currentUser.id], setting: TTGroupSetting(minimumNumOfUsers: 2, maximumNumOfUsers: 10, boundedStartDate: dateAMonthAgoFromToday, boundedEndDate: dateAMonthFromToday, lockGroupChanges: false, allowGroupJoin: true))
        FirebaseManager.shared.createGroup(for: newGroup) { [weak self] result in
            switch result {
            case .success(_):
                self?.createGroupConfirmationDelegate.didSuccessfullyCreateGroup()
            case .failure(let error):
                self?.presentTTAlert(title: "Cannot Create New Group", message: error.rawValue, buttonTitle: "Ok")
            }
        }
        
        //add group code to groupCodes property of all of the usersInQueue
        for id in usersInQueue.map({ $0.id }) {
            //fetch the data of each user to get the groupCodes property
            FirebaseManager.shared.fetchUserDocumentData(with: id) { [weak self] result in
                switch result {
                case .success(let user):
                    let groupCodesField = [
                        TTConstants.groupCodes: user.groupCodes.arrayByAppending(groupCode)
                    ]
                    //update the groupCodes property of each user
                    FirebaseManager.shared.updateUserData(for: id, with: groupCodesField) { error in
                        guard let error = error else { return }
                        self?.presentTTAlert(title: "Cannot update user", message: error.rawValue, buttonTitle: "Ok")
                    }
                case .failure(let error):
                    self?.presentTTAlert(title: "Cannot fetch user", message: error.rawValue, buttonTitle: "Ok")
                }
            }
        }
    }
}
