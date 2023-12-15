//
//  SettingsMyProfileView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI
import Setting
import PhotosUI

struct TTAlert {
    var title: String
    var message: String
}

struct SettingsMyProfileView: View {
    @State private var profileImage: UIImage?
    //TODO: Encapsulate this into one single error via an error struct 
    @State private var showChangeNameAlert = false
    @State private var showChangeIDAlert = false
    @State private var showChangeEmailAlert = false
    @State private var showChangePhoneNumberAlert = false
    @State private var showLogoutConfirmationAlert = false
    
    @State private var firstname = ""
    @State private var lastname = ""
    @State private var id = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    
    @State private var imageSelection = [PhotosPickerItem]()
    
    @State private var ttError: TTError? = nil
    @State private var showErrorAlert = false
    @State private var showPasswordResetConfirmationAlert = false
    
    var body: some View {
        SettingStack(isSearchable: false) {
            SettingPage(title: "My Profile", navigationTitleDisplayMode: .inline) {
                profilePictureSection
                
                //Change Name Section
                SettingGroup(id: "Name", header: "Name") {
                    SettingText(title: "\(firstname) \(lastname)")
                    SettingCustomView(id: "ChangeName") {
                        changeNameButton
                    }
                }
                
                //Id Section
                SettingGroup(id: "User ID", header: "User ID") {
                    SettingCustomView(id: "id") {
                        HStack {
                            Text(id)
                            Spacer()
                            CopyPasteboardView(text: id)
                        }
                        .padding(15)
                    }
                }
                
                SettingGroup(id: "Email", header: "Email") {
                    SettingText(title: email == "" ? "No Email" : email, foregroundColor: email == "" ? .red : .primary)
                    SettingCustomView(id: "ChangeEmail") {
                        changeEmailButton
                    }
                }
                
                SettingGroup(id: "Phone Number", header: "Phone Number") {
                    SettingText(title: phoneNumber == "" ? "No Phone Number" : phoneNumber,
                                foregroundColor: phoneNumber == "" ? .red : .primary)
                    SettingCustomView(id: "ChangePhoneNumber") {
                        changePhoneNumberButton
                    }
                }
                
                SettingGroup {
                    SettingCustomView(id: "ForgotPassword") {
                        Button("Forgot Password") {
                            //Reset Password
                            FirebaseManager.shared.sendPasswordResetEmail { error in
                                if let error = error {
                                    ttError = TTError(rawValue: error.localizedDescription)
                                    showErrorAlert.toggle()
                                } else {
                                    showPasswordResetConfirmationAlert.toggle()
                                }
                            }
                        }
                        .foregroundColor(.red)
                        .padding(15)
                    }
                    SettingCustomView(id: "DeleteAccount") {
                        Button("Delete Account") {
                            //Delete Account From Firestore
                        }
                        .foregroundColor(.red)
                        .padding(15)
                    }
                }
                
                SettingGroup(id: "Logout", backgroundColor: .red) {
                    SettingCustomView(id: "Logout") {
                        logoutButton
                    }
                }
            }
        }
        .onChange(of: imageSelection) {
            Task {
                if let data = try? await imageSelection.first?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        uploadProfileImageDataToFirestore(for: uiImage)
                        profileImage = uiImage
                        return
                    }
                }
                ttError = TTError(rawValue: TTError.unableToFetchImage.rawValue)
                showErrorAlert.toggle()
            }
        }
        .alert("Password Reset Sent", isPresented: $showPasswordResetConfirmationAlert) {
            Button(action: { showPasswordResetConfirmationAlert.toggle() }) {
                Text("OK")
            }
        } message: {
            if let email = FirebaseManager.shared.currentUser?.email {
                Text("Password Reset Sent To: \(email)")
            } else {
                Text("Error: Can't find your email to send.")
            }
        }

    }
    
    //MARK: - Profile Picture Section
    @SettingBuilder private var profilePictureSection: some Setting {
        SettingCustomView(id: "ProfilePicture") {
            VStack(spacing: 6) {
                profileImageView
                PhotosPicker(selection: $imageSelection, maxSelectionCount: 1, matching: .images, photoLibrary: .shared()) {
                    Text("Edit Picture")
                        .font(.system(size: 15).bold())
                        .foregroundColor(.green)
                }
            }
            .onAppear {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }

                currentUser.getProfilePictureUIImage { image in
                    profileImage = image 
                }
                firstname = currentUser.firstname
                lastname = currentUser.lastname
                id = currentUser.id
                email = currentUser.email
                phoneNumber = currentUser.phoneNumber
            }
        }
    }
    
    private var changeNameButton: some View {
        Button(action: {
            showChangeNameAlert.toggle()
        }) {
            Text("Change Name")
                .leftAligned()
                .frame(maxWidth: .infinity)

        }
        .tint(.green)
        .padding(15)
        .alert("Change Name", isPresented: $showChangeNameAlert) {
            TextField("First Name", text: $firstname)
            TextField("Last Name", text: $lastname)
            Button("OK", action: {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                FirebaseManager.shared.updateUserData(for: currentUser.id, with: [
                    TTConstants.firstname: firstname.trimmingCharacters(in: .whitespacesAndNewlines),
                    TTConstants.lastname: lastname.trimmingCharacters(in: .whitespacesAndNewlines)
                ]) { error in
                    guard let error = error else { return }
                    ttError = error
                    showErrorAlert = true
                }
            })
            Button("Cancel", role: .cancel) {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                firstname = currentUser.firstname
                lastname = currentUser.lastname
                showChangeNameAlert.toggle()
            }
        }
    }
    
    private var changeEmailButton: some View {
        Button(action: {
            showChangeEmailAlert.toggle()
        }) {
            Text("Change Email")
                .leftAligned()
                .frame(maxWidth: .infinity)

        }
        .tint(.green)
        .padding(15)
        .alert("Change Email", isPresented: $showChangeEmailAlert) {
            TextField("Email", text: $email)
                .textCase(.lowercase)
            Button("OK", action: {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                FirebaseManager.shared.updateUserData(for: currentUser.id, with: [
                    TTConstants.email: email.trimmingCharacters(in: .whitespacesAndNewlines)
                ]) { error in
                    guard let error = error else { return }
                    ttError = error
                    showErrorAlert = true
                }
            })
            Button("Cancel", role: .cancel) {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                email = currentUser.email
            }
        }
    }
    
    private var changePhoneNumberButton: some View {
        Button(action: {
            showChangePhoneNumberAlert.toggle()
        }) {
            Text("Change Phone Number")
                .leftAligned()
                .frame(maxWidth: .infinity)

        }
        .tint(.green)
        .padding(15)
        .alert("Change Phone Number", isPresented: $showChangePhoneNumberAlert) {
            TextField("📞", text: $phoneNumber)
            Button("OK", action: {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                FirebaseManager.shared.updateUserData(for: currentUser.id, with: [
                    TTConstants.phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                ]) { error in
                    guard let error = error else { return }
                    ttError = error
                    showErrorAlert = true
                }
            })
            Button("Cancel", role: .cancel) {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                phoneNumber = currentUser.phoneNumber
            }
        }
    }
    
    private var logoutButton: some View {
        HStack {
            Button(action: {
                showLogoutConfirmationAlert.toggle()
            }) {
                Text("Log Out")
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .font(.system(size: 20).bold())
            }
            .confirmationDialog("Confirm Logout", isPresented: $showLogoutConfirmationAlert) {
                Button("OK", action: {
                    FirebaseManager.shared.signOutUser { result in
                        switch result {
                        case .success(_):
                            break
                        case .failure(_):
                            ttError = TTError.unableToSignOutUser
                            showErrorAlert = true
                        }
                    }
                })
                Button("Cancel", role: .cancel) {
                    showLogoutConfirmationAlert.toggle()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            Spacer()
        }
        .padding(15)
    }
    
    private var profileImageView: some View {
        HStack {
            Spacer()
            TTSwiftUIProfileImageView(user: FirebaseManager.shared.currentUser, image: profileImage, size: 190)
            Spacer()
        }
    }
    
    private func uploadProfileImageDataToFirestore(for image: UIImage) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        FirebaseStorageManager.shared.uploadProfilePicture(for: image) { result in
            switch result {
            case .success(let url):
                FirebaseManager.shared.updateUserData(for: currentUser.id, with: [
                    TTConstants.profilePictureURLString: url.absoluteString
                ]) { error in
                    guard let error = error else { return }
                    print(error.rawValue)
                }
            case .failure(let error):
                ttError = error
                showErrorAlert.toggle()
            }
        }

       
    }
}

#Preview {
    SettingsMyProfileView()
}

