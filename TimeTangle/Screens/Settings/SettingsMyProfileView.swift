//
//  SettingsMyProfileView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI
import Setting
import PhotosUI

struct SettingsMyProfileView: View {
    
    @State private var profileImage: UIImage?
    @State private var showChangeNameAlert = false
    @State private var showChangeUsernameAlert = false
    @State private var showLogoutConfirmationAlert = false
    
    @State private var firstname = ""
    @State private var lastname = ""
    @State private var username = ""
    
    @State private var imageSelection = [PhotosPickerItem]()
    
    @State private var ttError: TTError? = nil
    @State private var showErrorAlert = false
    
    var body: some View {
        SettingStack(isSearchable: false) {
            SettingPage(title: "My Profile", navigationTitleDisplayMode: .inline) {
                profilePictureSection
                nameSection
                usernameSection
                
                SettingGroup(id: "Logout") {
                    SettingCustomView(id: "Logout") {
                        HStack {
                            Button(action: {
                                showLogoutConfirmationAlert.toggle()
                            }) {
                                Text("Log Out")
                                    .leftAligned()
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
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
                }
            }
        }
        .onChange(of: imageSelection) { _ in
            Task {
                if let data = try? await imageSelection.first?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        uploadProfileImageDataToFirestore(for: uiImage)
                        profileImage = uiImage
                        return
                    }
                }
                ttError = TTError(rawValue: TTError.unableToFetchImage.rawValue)
                showErrorAlert = true
            }
        }
        .presentScreen(isPresented: $showErrorAlert, modalPresentationStyle: .fullScreen) {
            TTSwiftUIAlertView(alertTitle: "Error", message: ttError?.rawValue ?? "No Message", buttonTitle: "OK")
                .ignoresSafeArea(.all)
        }
    }
    
    //MARK: - Profile Picture Section
    @SettingBuilder private var profilePictureSection: some Setting {
        SettingCustomView(id: "ProfilePicture") {
            VStack(spacing: 10) {
                profileImageView
                PhotosPicker(selection: $imageSelection, maxSelectionCount: 1, matching: .images, photoLibrary: .shared()) {
                    Text("Edit Picture")
                        .font(.system(size: 15).bold())
                        .foregroundColor(.white)
                }
                .padding(10)
                .background(Color(.systemGray3))
                .cornerRadius(10)
            }
            .onAppear {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                print(currentUser)
                if let imageData = currentUser.profilePictureData, let image = UIImage(data: imageData) {
                    profileImage = image
                }
                firstname = currentUser.firstname
                lastname = currentUser.lastname
                username = currentUser.username
            }
        }
    }
    
    private var profileImageView: some View {
        HStack {
            Spacer()
            TTSwiftUIProfileImageView(image: profileImage, size: 120)
            Spacer()
        }
    }
    
    //MARK: - Name Section
    @SettingBuilder private var nameSection: some Setting {
        SettingGroup(id: "Name", header: "Name") {
            SettingText(title: "\(firstname)\(lastname)")
            SettingCustomView(id: "ChangeName") {
                Button(action: {
                    showChangeNameAlert.toggle()
                }) {
                    Text("Change Name")
                        .leftAligned()
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)

                }
                .padding(15)
                .alert("Change Name", isPresented: $showChangeNameAlert) {
                    TextField("First Name", text: $firstname)
                    TextField("Last Name", text: $lastname)
                    Button("OK", action: {
                        guard let currentUser = FirebaseManager.shared.currentUser else { return }
                        FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
                            TTConstants.firstname: firstname,
                            TTConstants.lastname: lastname
                        ]) { error in
                            guard let error = error else { return }
                            ttError = error
                            showErrorAlert = true
                        }
                    })
                    Button("Cancel", role: .cancel) {
                        showChangeNameAlert.toggle()
                    }
                }
            }
        }
    }
    
    //MARK: - Username Section
    @SettingBuilder private var usernameSection: some Setting {
        SettingGroup(id: "Username", header: "Username") {
            SettingText(title: username)
            SettingCustomView(id: "ChangeUsername") {
                HStack {
                    Button(action: {
                        showChangeUsernameAlert.toggle()
                    }) {
                        Text("Change Username")
                            .leftAligned()
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                    }
                    Spacer()
                }
                .padding(15)
                .alert("Change Username", isPresented: $showChangeUsernameAlert) {
                    TextField("Username", text: $username)
                    Button("OK", action: {
                        guard let currentUser = FirebaseManager.shared.currentUser else { return }
                        FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
                            TTConstants.username: username
                        ]) { error in
                            guard error == nil else { return }
                        }
                    })
                    Button("Cancel", role: .cancel) {
                        showChangeUsernameAlert.toggle()
                    }
                }
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
        print("CompressedImageData: \(compressedImageData.count)")

        FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
            TTConstants.profilePictureData: compressedImageData
        ]) { error in
            guard let error = error else { return }
            print(error.rawValue)
        }
    }
}

struct SettingsMyProfilePreviewProvider_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMyProfileView()
    }
}

