//
//  SettingsMyProfileView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI
import Setting

struct SettingsMyProfileView: View {
    
    @State private var profileImage: UIImage?
    @State private var showChangeNameAlert = false
    @State private var showChangeUsernameAlert = false
    
    @State private var firstname = ""
    @State private var lastname = ""
    @State private var username = ""
    
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
                                
                            }) {
                                Text("Log Out")
                                    .leftAligned()
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                            }
                
                            Spacer()
                        }
                        .padding(15)
                    }
                }
            }
        }
    }
    
    //MARK: - Profile Picture Section
    @SettingBuilder private var profilePictureSection: some Setting {
        SettingCustomView(id: "ProfilePicture") {
            VStack(spacing: 10) {
                profileImageView
                Button(action: {}) {
                    Text("Edit Picture")
                        .foregroundColor(.white)
                        .bold()
                }
                .padding(10)
                .background(Color(.systemGray3))
                .cornerRadius(10)
            }
            .onAppear {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
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
            SettingText(title: "Justin Wong")
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
                            //TODO: Figure out how to present TTError
                            guard error == nil else { return }
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
            SettingText(title: "jwongeecs")
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
    
    //MARK: - Logout Section
//    @SettingBuilder private var logoutSection: some Setting {
//
//    }
}

struct SettingsMyProfilePreviewProvider_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMyProfileView()
    }
}

