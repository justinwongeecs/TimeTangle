//
//  CreateRoomConfirmationVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit

protocol CreateRoomConfirmationVCDelegate: AnyObject {
    func didSuccessfullyCreateRoom()
}

class CreateRoomConfirmationVC: TTModalCardVC {
    
    private var usersInQueue = [TTUser]()
    
    private let containerViewHeader = UIStackView()
    private var headerLabel = TTTitleLabel(textAlignment: .center, fontSize: 18)
    let roomCodeView = UIView()
    let roomCodeLabel = TTBodyLabel(textAlignment: .center)
    let roomNameTextField = UIStackView()
    let textField = TTTextField()
    let confirmationButton = TTButton(backgroundColor: .systemGreen, title: "Tangle!")

    
    weak var createRoomConfirmationDelegate: CreateRoomConfirmationVCDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.text = "Confirm Room Settings"
        configureContainerViewHeader()
        configureRoomCodeView()
        configureRoomCodeLabel()
        configureRoomNameTitledText()
        configureConfirmationButton()
    }
    
    init(users: [TTUser]) {
        super.init(nibName: nil, bundle: nil)
        self.usersInQueue = users
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureRoomCodeView() {
        view.addSubview(roomCodeView)
        roomCodeView.translatesAutoresizingMaskIntoConstraints = false
        roomCodeView.backgroundColor = .systemGray5
        roomCodeView.layer.masksToBounds = true
        roomCodeView.layer.cornerRadius = 16
        
        roomCodeView.addSubview(roomCodeLabel)
        
        NSLayoutConstraint.activate([
            roomCodeView.topAnchor.constraint(equalTo: containerViewHeader.bottomAnchor, constant: 10),
            roomCodeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50),
            roomCodeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            roomCodeView.heightAnchor.constraint(equalToConstant: 80)
        ])
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
    
    private func configureRoomCodeLabel() {
        roomCodeLabel.font = UIFont.boldSystemFont(ofSize: 50)
        roomCodeLabel.text = generateRandomRoomCode()
        
        let padding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            roomCodeLabel.centerYAnchor.constraint(equalTo: roomCodeView.centerYAnchor),
            roomCodeLabel.topAnchor.constraint(equalTo: roomCodeView.topAnchor, constant: padding),
            roomCodeLabel.leadingAnchor.constraint(equalTo: roomCodeView.leadingAnchor, constant: padding),
            roomCodeLabel.trailingAnchor.constraint(equalTo: roomCodeView.trailingAnchor, constant: -padding),
        ])
    }
    
    private func configureRoomNameTitledText() {
        view.addSubview(roomNameTextField)
        roomNameTextField.translatesAutoresizingMaskIntoConstraints = false
        roomNameTextField.axis = .vertical
        roomNameTextField.distribution = .fillProportionally
        
        let enterRoomNameLabel = UILabel()
        enterRoomNameLabel.text = "Enter Room Name:"
        enterRoomNameLabel.translatesAutoresizingMaskIntoConstraints = false
        enterRoomNameLabel.font = UIFont.boldSystemFont(ofSize: 17)
        
        textField.becomeFirstResponder()
        
        roomNameTextField.addArrangedSubview(enterRoomNameLabel)
        roomNameTextField.addArrangedSubview(textField)
        
        NSLayoutConstraint.activate([
            roomNameTextField.topAnchor.constraint(equalTo: roomCodeView.bottomAnchor, constant: 10),
            roomNameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50),
            roomNameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            roomNameTextField.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func configureConfirmationButton() {
        view.addSubview(confirmationButton)
        confirmationButton.addTarget(self, action: #selector(confirmRoom), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            confirmationButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            confirmationButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50),
            confirmationButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            confirmationButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func generateRandomRoomCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...5).map{ _ in letters.randomElement()! })
    }
    
    @objc private func confirmRoom() {
        guard !textField.text!.isEmpty else {
            self.presentTTAlert(title: "Room Name Can't Be Empty", message: TTError.textFieldsCannotBeEmpty.rawValue, buttonTitle: "Ok")
            return
        }
        
        guard let roomCode = roomCodeLabel.text,
        let currentUser = FirebaseManager.shared.currentUser else { return }
        
        //Create a room instance in Firestore
        let newRoom = TTRoom(name: textField.text!, users: usersInQueue.map{$0.username}, code: roomCode, startingDate: Date(), endingDate: Date(), histories: [], events: [], admins: [currentUser.username])
        FirebaseManager.shared.createRoom(for: newRoom) { [weak self] result in
            switch result {
            case .success(_):
                self?.createRoomConfirmationDelegate.didSuccessfullyCreateRoom()
            case .failure(let error):
                self?.presentTTAlert(title: "Cannot Create New Room", message: error.rawValue, buttonTitle: "Ok")
            }
        }
        
        //add room code to roomCodes property of all of the usersInQueue
        for username in usersInQueue.map({ $0.username }) {
            //fetch the data of each user to get the roomCodes property
            FirebaseManager.shared.fetchUserDocumentData(with: username) { [weak self] result in
                switch result {
                case .success(let user):
                    let roomCodesField = [
                        TTConstants.roomCodes: user.roomCodes.arrayByAppending(roomCode)
                    ]
                    //update the roomCodes property of each user
                    FirebaseManager.shared.updateUserData(for: username, with: roomCodesField) { error in
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
