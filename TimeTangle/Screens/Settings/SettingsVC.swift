//
//  SettingsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class SettingsVC: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstAndLastNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileView: UIView!
    
    var currentUser: TTUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentUser = FirebaseManager.shared.currentUser
        configureProfileView()
        configureProfileTapGesture()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser(_:)), name: .updatedUser, object: nil)
        
        title = "Settings"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func configureProfileView() {
        guard let currentUser = currentUser else { return }
        profileImageView.image =  UIImage(systemName: "person.crop.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 80, weight: .regular))?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        firstAndLastNameLabel.text = "\(currentUser.firstname) \(currentUser.lastname)"
        usernameLabel.text = "\(currentUser.username)"
        firstAndLastNameLabel.sizeToFit()
        usernameLabel.sizeToFit()
    }
    
    private func configureProfileTapGesture() {
        let tapProfileViewGesture = UITapGestureRecognizer(target: self, action: #selector(showProfileEditSheet))
        profileView.isUserInteractionEnabled = true 
        profileView.addGestureRecognizer(tapProfileViewGesture)
    }
    
    @objc private func showProfileEditSheet() {
        print("tapped")
        let editProfileVC = SettingsEditProfileVC(nibName: "SettingsEditProfileVCNib", bundle: nil)
        editProfileVC.closeButtonDelegate = self 
        let navController = UINavigationController(rootViewController: editProfileVC)
        present(navController, animated: true)
    }
    
    @IBAction func clickedSignOutButton(_ sender: UIButton) {
        FirebaseManager.shared.signOutUser { result in
            switch result {
            case .success():
                //go to login screen though it should be automatic?
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(LoginVC())
            case .failure(let error):
                self.presentTTAlert(title: "Error", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }
    
    @objc private func fetchUpdatedUser(_ notification: Notification) {
        guard let updatedUser = notification.object as? TTUser else { return }
        currentUser = updatedUser
        configureProfileView()
    }
}

extension SettingsVC: CloseButtonDelegate {
    func didDismissPresentedView() {
        dismiss(animated: true)
    }
}

