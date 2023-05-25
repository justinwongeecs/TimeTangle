//
//  SettingsProfileEditVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/21/23.
//

import UIKit
import PhotosUI

class SettingsProfileEditVC: UIViewController {

    private var profileAvatarView: TTProfileImageView!
    private let editProfileImageViewButton = UIButton()
    private var profileInfoTableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private var settingSections = [SettingSection]()
    
    private let profileImageWidthHeight: CGFloat = 150
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground
        title = "My Profile"
        
        configureProfileImageView()
        configureEditProfileImageViewButton()
        configureInfoTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard profileAvatarView != nil else { return }
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if traitCollection.userInterfaceStyle == .dark {
                profileAvatarView.setShadowColor(to: UIColor.white.cgColor)
            } else {
                profileAvatarView.setShadowColor(to: UIColor.black.cgColor)
            }
        }
    }
    
    private func configureProfileImageView() {
        guard let currentUser = FirebaseManager.shared.currentUser,
              let imageData = currentUser.profilePictureData,
              let image = UIImage(data: imageData) else { return }
        
        profileAvatarView = TTProfileImageView(image: image, widthHeight: profileImageWidthHeight)
        profileAvatarView.translatesAutoresizingMaskIntoConstraints = false 
        profileAvatarView.showBorder = true
        profileAvatarView.showShadow = true
        view.addSubview(profileAvatarView)
        
        NSLayoutConstraint.activate([
            profileAvatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileAvatarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileAvatarView.widthAnchor.constraint(equalToConstant: profileImageWidthHeight),
            profileAvatarView.heightAnchor.constraint(equalToConstant: profileImageWidthHeight)
        ])
    }
    
    private func configureEditProfileImageViewButton() {
        editProfileImageViewButton.translatesAutoresizingMaskIntoConstraints = false
        editProfileImageViewButton.backgroundColor = .systemGray3
        editProfileImageViewButton.layer.cornerRadius = 5.0
        editProfileImageViewButton.clipsToBounds = true
        editProfileImageViewButton.setTitle("Edit Profile", for: .normal)
        editProfileImageViewButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        editProfileImageViewButton.setTitleColor(.white, for: .normal)
        editProfileImageViewButton.addTarget(self, action: #selector(didClickOnProfileImageView), for: .touchUpInside)
        view.addSubview(editProfileImageViewButton)
        
        NSLayoutConstraint.activate([
            editProfileImageViewButton.topAnchor.constraint(equalTo: profileAvatarView.bottomAnchor, constant: 20),
            editProfileImageViewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editProfileImageViewButton.widthAnchor.constraint(equalToConstant: 130),
            editProfileImageViewButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func configureInfoTableView() {
        profileInfoTableView.translatesAutoresizingMaskIntoConstraints = false
        profileInfoTableView.dataSource = self
        profileInfoTableView.delegate = self
        profileInfoTableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseID)
        profileInfoTableView.register(SettingsButtonCell.self, forCellReuseIdentifier: SettingsButtonCell.reuseID)
        view.addSubview(profileInfoTableView)
        
        
        NSLayoutConstraint.activate([
            profileInfoTableView.topAnchor.constraint(equalTo: editProfileImageViewButton.bottomAnchor, constant: 20),
            profileInfoTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileInfoTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileInfoTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        settingSections.removeAll()
        settingSections.append(
            SettingSection(title: "Name", settings: [
                Setting(title: "\(currentUser.firstname.capitalized)\(currentUser.lastname.capitalized)", actionType: .none),
                Setting(title: "Change Name", titleColor: .systemBlue, actionType: .button) { [weak self] in
                    self?.showChangeNameAlertController()
                }
        ]))
        
        settingSections.append(
            SettingSection(title: "Username", settings: [
                Setting(title: "\(currentUser.username)", actionType: .none),
                Setting(title: "Change Username", titleColor: .systemBlue, actionType: .button) { [weak self] in
                    self?.showChangeUsernameAlertController()
                }
            ])
        )
        
        if let email = FirebaseManager.shared.getCurrentUserEmail() {
            settingSections.append(SettingSection(title: "Email", settings: [
                Setting(title: "\(email)", actionType: .none),
                Setting(title: "Change Email", titleColor: .systemBlue, actionType: .button) { [weak self] in
                    self?.showChangeEmailAlertController()
                }
            ]))
        }
        
        settingSections.append(
            SettingSection(title: "", settings: [
                Setting(title: "Remove Account", titleColor: .systemRed, actionType: .button) {
                    print("remove account")
                }
            ])
        )
        settingSections.append(
            SettingSection(title: "", settings: [
                Setting(title: "Log Out", titleColor: .systemRed, actionType: .button) {
                    print("log out")
                }
            ])
        )
    }
    
    private func showChangeNameAlertController() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        let alertController = UIAlertController(title: "Change Name", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = currentUser.firstname
        }
        
        alertController.addTextField { textField in
            textField.placeholder = currentUser.lastname
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        
        let okayAction = UIAlertAction(title: "OK", style: .default) { _ in
            var newFirstname = ""
            var newLastname = ""
            
            if let textFields = alertController.textFields {
                newFirstname = textFields[0].text ?? ""
                newLastname = textFields[1].text ?? ""
            }
           
            FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
                TTConstants.firstname: newFirstname,
                TTConstants.lastname: newLastname
            ]) { [weak self] error in
                guard error == nil else { return }
                DispatchQueue.main.async {
                    self?.updateVC()
                }
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okayAction)
        present(alertController, animated: true)
    }
    
    private func showChangeUsernameAlertController() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        let alertController = UIAlertController(title: "Change Username", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = currentUser.username
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        
        let okayAction = UIAlertAction(title: "OK", style: .default) { _ in
            var newUsername = ""
            
            if let textFields = alertController.textFields {
                newUsername = textFields[0].text ?? ""
            }
           
            FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
                TTConstants.username: newUsername
            ]) { [weak self] error in
                guard error == nil else { return }
                DispatchQueue.main.async {
                    self?.updateVC()
                }
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okayAction)
        present(alertController, animated: true)
    }
    
    private func showChangeEmailAlertController() {
        guard let email = FirebaseManager.shared.getCurrentUserEmail() else { return }
        
        let alertController = UIAlertController(title: "Change Email", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = email
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        
        let okayAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let textFields = alertController.textFields {
                let email = textFields[0].text ?? ""
                
                FirebaseManager.shared.updateUserEmail(with: email) { [weak self] error in
                    guard let error = error else { return }
                    self?.presentTTAlert(title: "Update Error", message: error.rawValue, buttonTitle: "OK")
                }
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okayAction)
        present(alertController, animated: true)
    }
    
    private func updateVC() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        //first and last name
        settingSections[0].settings[0].title = "\(currentUser.firstname.capitalized)\(currentUser.lastname.capitalized)"
        
        //username
        settingSections[1].settings[0].title = "\(currentUser.username)"
        
        //email
        if let email = FirebaseManager.shared.getCurrentUserEmail() {
            settingSections[2].settings[0].title = email
        }

        profileInfoTableView.reloadData()
    }
    
    @objc private func didClickOnProfileImageView() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = PHPickerFilter.images
        config.preferredAssetRepresentationMode = .current
        config.selection = .ordered
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

//MARK: - Delegates
extension SettingsProfileEditVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = settingSections[section]
        return section.title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settingSections[section]
        return section.settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = settingSections[indexPath.section]
        let setting = section.settings[indexPath.row]
        
        if setting.actionType == .button {
            let buttonCell = tableView.dequeueReusableCell(withIdentifier: SettingsButtonCell.reuseID) as! SettingsButtonCell
            buttonCell.setCell(with: setting)
            return buttonCell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseID) as! SettingsCell
        cell.setCell(for: setting)
        return cell
    }
}

extension SettingsProfileEditVC: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        profileAvatarView.startAnimatingProgressIndicator()
        guard let selectedResult = results.first else { return }
        getUIImageFromIdentifier(with: selectedResult.assetIdentifier!, result: selectedResult) { [weak self] result in
            switch result {
            case .success(let image):
                self?.uploadProfileImageDataToFirestore(for: image)
                self?.uploadProfileURLToFirestore(for: image)
            case .failure(let error):
                self?.profileAvatarView.stopAnimatingProgressIndicator()
                self?.presentTTAlert(title: "Fetch Image Error", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }
    
    private func getUIImageFromIdentifier(with identifier: String, result: PHPickerResult, completed: @escaping(Result<UIImage, TTError>) -> Void) {
        let itemProvider = result.itemProvider
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                guard let image = image as? UIImage, error == nil else {
                    completed(.failure(TTError.unableToFetchProfileImageFromUser))
                    return
                }
                DispatchQueue.main.async {
                    completed(.success(image))
                }
            }
        }
    }
    
    private func uploadProfileURLToFirestore(for image: UIImage) {
        let firebaseStorageManager = FirebaseStorageManager()
        firebaseStorageManager.uploadProfilePicture(for: image) { [weak self] result in
            self?.profileAvatarView.stopAnimatingProgressIndicator()
            switch result {
            case .success(let url):
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
                    TTConstants.profilePictureURL: url.absoluteString
                ]) { error in
                    guard error == nil else { return }
                }
                
                DispatchQueue.main.async {
                    self?.profileAvatarView.setImage(to: image)
                }
                break
            case .failure(let error):
                self?.presentTTAlert(title: "Fetch Image Error", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }
    
    private func uploadProfileImageDataToFirestore(for image: UIImage) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        var compressionQuality = 1.0
        var compressedImageByteCount = image.jpegData(compressionQuality: compressionQuality)?.count ?? 0
        
        while (compressedImageByteCount > TTConstants.firestoreMaximumImageDataBytes) {
            compressedImageByteCount = image.jpegData(compressionQuality: compressionQuality)?.count ?? 0
            compressionQuality -= 0.1
        }
        
        guard let compressedImageData = image.jpegData(compressionQuality: compressionQuality) else { return }

        FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
            TTConstants.profilePictureData: compressedImageData
        ]) { [weak self] error in
            guard let error = error else { return }
            print(error.rawValue)
            self?.profileAvatarView.stopAnimatingProgressIndicator()
        }
    }
    
}
