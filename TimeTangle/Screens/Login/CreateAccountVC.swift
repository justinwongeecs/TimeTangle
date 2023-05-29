//
//  CreateAccountVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import SwiftUI
import UIKit
import Setting

struct CreateAccountView: View {
    @Environment(\.dismiss) private var dismiss
    
    let config: Configuration
    
    @State private var firstNameText = ""
    @State private var lastNameText = ""
    @State private var userNameText = ""
    @State private var emailText = ""
    @State private var passwordText = ""
    @State private var confirmPasswordText = ""
    
    @State private var showError = false
    @State private var ttError: TTError? = nil
    
    var body: some View {
        NavigationStack {
            SettingStack(isSearchable: false, embedInNavigationStack: true) {
                SettingPage(title: "Create Account", navigationTitleDisplayMode: .inline) {
                    //MARK: First and Last Names
                    SettingGroup(id: "Names", header: "Name") {
                        SettingCustomView(id: "First Name") {
                            TTSwiftUITextField(textFieldText: $firstNameText, leftTitle: "First Name:", textFieldPlaceholder: "John")
                        }
                        SettingCustomView(id: "Last Name") {
                            TTSwiftUITextField(textFieldText: $lastNameText, leftTitle: "Last Name:", textFieldPlaceholder: "Appleseed")
                        }
                    }
                    
                    //MARK: - Info
                    SettingGroup(id: "Info", header: "Info") {
                        SettingCustomView(id: "Username") {
                            TTSwiftUITextField(textFieldText: $userNameText, leftTitle: "Username:", textFieldPlaceholder: "jonnyapple")
                        }
                        SettingCustomView(id: "Email") {
                            TTSwiftUITextField(textFieldText: $emailText, leftTitle: "Email:", textFieldPlaceholder: "jonny@apple.com")
                        }
                    }
                    
                    //MARK: - Password
                    SettingGroup(id: "Passwords", header: "Password") {
                        SettingCustomView(id: "Passwords") {
                            TTSwiftUITextField(textFieldText: $passwordText, leftTitle: "Password:", textFieldPlaceholder: "", isSecureTextField: true)
                        }
                        SettingCustomView(id: "Confirm Password") {
                            TTSwiftUITextField(textFieldText: $confirmPasswordText, leftTitle: "Confirm Password:", textFieldPlaceholder: "", isSecureTextField: true)
                        }
                    }
                    
                    SettingCustomView(id: "CreateAccountButton") {
                        Button(action: { createAccount() }) {
                            Text("Create Account")
                                .padding()
                                .bold()
                                .foregroundColor(.white)
                                .background(.green)
                                .cornerRadius(10)
                                .centered()
                        }
                        .onChange(of: showError) { newValue in
                            config.hostingController?.presentTTAlert(title: "Create Account Error", message: ttError?.rawValue ?? "No Message", buttonTitle: "OK")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        print("Hello")
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
    
    private func createAccount() {
        FirebaseManager.shared.createUser(firstName: firstNameText, lastName: lastNameText, email: emailText, password: passwordText, username: userNameText) { result in
            switch result {
            case .success():
                break
            case .failure(let error):
                showError.toggle()
                ttError = error
            }
        }
    }
}

//MARK: - TTSwiftUITextField
struct TTSwiftUITextField: View {
    @Binding var textFieldText: String
    var leftTitle: String
    var textFieldPlaceholder: String
    var isSecureTextField: Bool = false
    
    var body: some View {
        VStack {
            Text(leftTitle)
                .bold()
                .leftAligned()
            if !isSecureTextField {
                TextField(textFieldPlaceholder, text: $textFieldText)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                    .leftAligned()
            } else {
                SecureField(textFieldPlaceholder, text: $textFieldText)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                    .leftAligned()
            }
        }
        .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
    }
}

//struct CreateAccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreateAccountView()
//    }
//}
