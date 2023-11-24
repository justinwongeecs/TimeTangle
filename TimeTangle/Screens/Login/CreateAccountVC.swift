//
//  CreateAccountVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import SwiftUI
import UIKit

struct CreateAccountView: View {
    @Environment(\.dismiss) private var dismiss
    
    let config: Configuration
    
    @State private var firstNameText = ""
    @State private var lastNameText = ""
    @State private var emailText = ""
    @State private var passwordText = ""
    @State private var phoneNumberText = ""
    @State private var confirmPasswordText = ""
    
    @State private var showError = false
    @State private var ttError: TTError? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Create Account") {
                    TTSwiftUITextField(textFieldText: $firstNameText, leftTitle: "First Name:", textFieldPlaceholder: "")
                    TTSwiftUITextField(textFieldText: $lastNameText, leftTitle: "Last Name:", textFieldPlaceholder: "")
                }
                
                Section("Info") {
                    TTSwiftUITextField(textFieldText: $emailText, leftTitle: "Email:", textFieldPlaceholder: "")
                    TTSwiftUITextField(textFieldText: $phoneNumberText, leftTitle: "Phone Number:", textFieldPlaceholder: "")
                }
                
                Section("Password") {
                    TTSwiftUITextField(textFieldText: $passwordText, leftTitle: "Password:", textFieldPlaceholder: "", isSecureTextField: true)
                    TTSwiftUITextField(textFieldText: $confirmPasswordText, leftTitle: "Confirm Password:", textFieldPlaceholder: "", isSecureTextField: true)
                }
                
                createAccountButton
                    .listRowBackground(Color.clear)
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
        .tint(.green)
    }
    
    private func createAccount() {
        guard !firstNameText.isEmpty, !lastNameText.isEmpty, !emailText.isEmpty, !phoneNumberText.isEmpty else {
            ttError = .textFieldsCannotBeEmpty
            showError.toggle()
            return
        }
        
        guard passwordText == confirmPasswordText else {
            ttError = .passwordsDoNotMatch
            showError.toggle()
            return
        }
        
        FirebaseManager.shared.createUser(firstName: firstNameText, lastName: lastNameText, email: emailText, password: passwordText, phoneNumber: phoneNumberText) { result in
            switch result {
            case .success():
                break
            case .failure(let error):
                showError.toggle()
                ttError = error
            }
        }
    }
    
    private var createAccountButton : some View {
        Button(action: { createAccount() }) {
            Text("Create Account")
                .padding()
                .bold()
                .foregroundColor(.white)
                .background(.green)
                .cornerRadius(10)
                .centered()
        }
        .onChange(of: showError) {
            config.hostingController?.presentTTAlert(title: "Create Account Error", message: ttError?.rawValue ?? "No Message", buttonTitle: "OK")
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
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .leftAligned()
            } else {
                SecureField(textFieldPlaceholder, text: $textFieldText)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .leftAligned()
            }
        }
    }
}

#Preview {
    CreateAccountView(config: Configuration())
}
