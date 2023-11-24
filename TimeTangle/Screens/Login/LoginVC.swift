//
//  LoginVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit


class LoginVC: UIViewController {
    private let titleLabel = TTTitleLabel(textAlignment: .center, fontSize: 50)
    private let idTextField = TTTextField()
    private let passwordTextField = TTTextField()
    private let loginButton = TTButton(backgroundColor: .systemGreen, title: "Login")
    private let createAccountButton = TTButton(backgroundColor: .clear, title: "Create Account?")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        createDismissKeyboardTapGesture()
        configureTitleLabel()
        configureIDTextField()
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

    private func configureIDTextField() {
        view.addSubview(idTextField)

        idTextField.placeholder = "Enter email"

        NSLayoutConstraint.activate([
            idTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 100),
            idTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            idTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            idTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func configurePasswordTextField() {
        view.addSubview(passwordTextField)

        passwordTextField.isSecureTextEntry = true
        passwordTextField.placeholder = "Enter password"
        passwordTextField.delegate = self

        NSLayoutConstraint.activate([
            passwordTextField.topAnchor.constraint(equalTo: idTextField.bottomAnchor, constant: 50),
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
        FirebaseManager.shared.signInUser(email: idTextField.text!, password: passwordTextField.text!) { [weak self] result in

            guard let self = self else { return }
            switch result {
            case .success():
                FirebaseManager.shared.goToTabBarController()
            case .failure(let error):
                self.presentTTAlert(title: "Error", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }

    @objc private func presentCreateAccountVC() {
        let configuration = Configuration()
        let controller = TTHostingController(rootView: CreateAccountView(config: configuration))
        configuration.hostingController = controller
        
        present(controller, animated: true)
    }
}

extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        login()
        return true
    }
}

class Configuration {
    weak var hostingController: UIViewController?    // << wraps reference
}


