//
//  CreateAccountVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class CreateAccountVC: UIViewController {
    
    @IBOutlet weak var firstNameTextField: TTTextField!
    @IBOutlet weak var lastNameTextField: TTTextField!
    @IBOutlet weak var usernameTextField: TTTextField!
    @IBOutlet weak var emailTextField: TTTextField!
    @IBOutlet weak var passwordTextField: TTTextField!
    @IBOutlet weak var reenterPasswordTextField: TTTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureNotificationsForKeyboardHandling()
        hideKeyboardWhenTappedOutside()
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        title = "Create Account"

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissVC))
        navigationItem.leftBarButtonItem = cancelButton
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().standardAppearance = navBarAppearance
    }
    
    private func configureNotificationsForKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    
    @IBAction func createAccount(_ sender: UIButton) {
        showLoadingView()
        FirebaseManager.shared.createUser(firstName: firstNameTextField.text!, lastName: lastNameTextField.text!, email: emailTextField.text!, password: passwordTextField.text!, username: usernameTextField.text!) { [weak self] result in
            guard let self = self else { return }


            switch result {
            case .success():
                self.dismissLoadingView()
            case .failure(let error):
                self.presentTTAlert(title: "Error!", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }
    
    
    @objc private func keyboardWillChange(notification: Notification) {
//        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
//        
//        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
//            view.frame.origin.y = -keyboardRect.height
//        } else {
//            view.frame.origin.y = 0
//        }
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
}
