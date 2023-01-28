//
//  LoginVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

class LoginVC: UIViewController {
    
    let titleLabel = TTTitleLabel(textAlignment: .center, fontSize: 50)
    let usernameTextField = TTTextField()
    let passwordTextField = TTTextField()
    let loginButton = TTButton(backgroundColor: .systemGreen, title: "Login")
    let createAccountButton = TTButton(backgroundColor: .clear, title: "Create Account?")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        createDismissKeyboardTapGesture()
        configureTitleLabel()
        configureUserNameTextField()
        configurePasswordTextField()
        configureLoginButton()
        configureCreateAccountButton()
    }
    
    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.text = "TimeTangle"
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            titleLabel.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func configureUserNameTextField() {
        view.addSubview(usernameTextField)
        
        usernameTextField.placeholder = "Enter email"
        
        NSLayoutConstraint.activate([
            usernameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 100),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            usernameTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configurePasswordTextField() {
        view.addSubview(passwordTextField)
        
        passwordTextField.isSecureTextEntry = true
        passwordTextField.placeholder = "Enter password"
        passwordTextField.delegate = self
        
        NSLayoutConstraint.activate([
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 50),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureLoginButton() {
        view.addSubview(loginButton)
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            loginButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureCreateAccountButton() {
        view.addSubview(createAccountButton)
        createAccountButton.setTitleColor(.systemPink, for: .normal)
        createAccountButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        createAccountButton.addTarget(self, action: #selector(presentCreateAccountVC), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            createAccountButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 5),
            createAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            createAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            createAccountButton.heightAnchor.constraint(equalToConstant: 25)
        ])
    }
    
    @objc private func login() {
//        self.showLoadingView()
        FirebaseManager.shared.signInUser(email: usernameTextField.text!, password: passwordTextField.text!) { [weak self] result in

            guard let self = self else { return }
            switch result {
            case .success():
//                self.dismissLoadingView()
                print("Login Success")
                FirebaseManager.shared.goToTabBarController()
            case .failure(let error):
                self.presentTTAlert(title: "Error", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }
    
    @objc private func presentCreateAccountVC() {
        let destVC = CreateAccountVC(nibName: "CreateAccountVCNib", bundle: nil)
        let navController = UINavigationController(rootViewController: destVC)
        present(navController, animated: true)
    }
}

extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        login()
        return true 
    }
}
