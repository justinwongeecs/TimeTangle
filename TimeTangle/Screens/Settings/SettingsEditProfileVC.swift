//
//  SettingsEditProfileVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/3/23.
//

import UIKit
import PhotosUI

class SettingsEditProfileVC: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    private var profilePictureSelection = [String: PHPickerResult]()
    
    private let firebaseStorageManager = FirebaseStorageManager()
    weak var closeButtonDelegate: CloseButtonDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Edit Profile"
        configure()
        configureCloseButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func configureCloseButton() {
        let closeButton = TTCloseButton()
        closeButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        let closeButtonBarItem = UIBarButtonItem(customView: closeButton)
        navigationItem.rightBarButtonItem = closeButtonBarItem
    }
    
    private func configure() {
        profileImageView.image =  UIImage(systemName: "person.crop.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular))?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
    }
    
    
    //Show UIImagePickerController
    @IBAction func didClickChangeProfilePictureButton(_ sender: UIButton) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = PHPickerFilter.images
        config.preferredAssetRepresentationMode = .current
        config.selection = .ordered
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func dismissVC() {
        closeButtonDelegate.didDismissPresentedView()
    }
}

extension SettingsEditProfileVC: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let selectedResult = results.first else { return }
        getUIImageFromIdentifier(with: selectedResult.assetIdentifier!, result: selectedResult) { [weak self] result in
            switch result {
            case .success(let image):
                self?.fetchImageFromFirebaseStorage(for: image)
            case .failure(let error):
                self?.presentTTAlert(title: "Fetch Image Error", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }
    
    private func getUIImageFromIdentifier(with identifier: String, result: PHPickerResult, completed: @escaping(Result<UIImage, TTError>) -> Void) {
        let itemProvider = result.itemProvider
//        let progress: Progress?
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
    
    private func fetchImageFromFirebaseStorage(for image: UIImage) {
        firebaseStorageManager.uploadProfilePicture(for: image) { [weak self] result in
            switch result {
            case .success(let url):
                self?.firebaseStorageManager.fetchImage(for: url) { result in
                    switch result {
                    case .success(let image):
                        //save to Core Data
                        print(image)
                        break
                    case .failure(let error):
                        self?.presentTTAlert(title: "Fetch Image Error", message: error.rawValue, buttonTitle: "Ok")
                    }
                }
                break
            case .failure(let error):
                self?.presentTTAlert(title: "Fetch Image Error", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }
}

