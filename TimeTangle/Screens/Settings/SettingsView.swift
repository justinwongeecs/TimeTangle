//
//  SettingsView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI
import Setting

//MARK: - SettingsViewModel
class SettingsViewModel: ObservableObject {
    @AppStorage(SettingsConstants.allowNotifications) var allowNotifications = true
    @AppStorage(SettingsConstants.friendsDiscoverability) var friendsDiscoverability = true
    @AppStorage(SettingsConstants.timePeriodToDeleteRoomsIndex) var timePeriodToDeleteRoomsIndex = 0
    @AppStorage(SettingsConstants.appearanceIndex) var appearanceIndex = 0
    @AppStorage(SettingsConstants.automaticallyPullsFromCalendar) var automaticallyPullsFromCalendar = true
    @AppStorage(SettingsConstants.subscriptionPlanIsFree) var subscriptionPlanIsFree = true 
}

struct SettingsView: View {
    @StateObject private var model = SettingsViewModel()
    @State private var size: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            SettingStack {
                SettingPage(title: "Settings") {
                    SettingGroup {
                        SettingCustomView {
                            SettingsProfileHeaderView()
                        }
                    }
                    
                    SettingGroup {
                        generalSection
                        appearanceSection
                        privacySection
                        subscriptionSection
                        contributionsSection
                        helpSection
                        aboutSection
                    }
                }
            }
            .onAppear {
                size = geo.size
            }.onChange(of: geo.size) { newSize in
                size = newSize
            }
        }
    }
    
    //MARK: - General Section
    @SettingBuilder private var generalSection: some Setting {
        SettingPage(title: "General") {
            SettingGroup {
                SettingToggle(title: "Enable Notifications", isOn: $model.allowNotifications)
            }
            
            SettingGroup {
                SettingCustomView {
                    SettingPicker(title: "Delete Rooms After Ending Date", choices: [
                        "1 Week",
                        "1 Month",
                        "6 Months",
                        "1 Year",
                        "Never"
                    ], selectedIndex: $model.timePeriodToDeleteRoomsIndex)
                    Text("If specified, rooms will be deleted after a period of inactivity")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(15)
                }
            }
            
            SettingGroup {
                SettingCustomView(id: "ForgotPassword") {
                    Button("Forgot Password") {
                        //Reset Password
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
        }
        .previewIcon("gear", foregroundColor: .white, backgroundColor: .gray)
    }
    
    //MARK: - Appearance Section
    @SettingBuilder private var appearanceSection: some Setting {
        SettingPage(title: "Appearance") {
            SettingGroup {
                SettingCustomView(id: "SettingAppearanceSectionHeader") {
                    HStack {
                        Text("Choose an appearance for TimeTangle. \"Auto\" will match TimeTangle to the system-wide appearance")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                        Image(systemName: "sun.max.fill")
                            .frame(width: 70, height: 70)
                            .background(.black)
                            .foregroundColor(.yellow)
                            .cornerRadius(10)
                            .font(.system(.largeTitle))
                    }
                    .padding(15)
                }
            }
            
            SettingGroup {
                SettingPicker(title: "Appearance", choices: [
                "Auto",
                "Light",
                "Dark"
                ], selectedIndex: $model.appearanceIndex, choicesConfiguration: .init(pickerDisplayMode: .inline))
            }
        }
        .previewIcon("sun.max.fill", foregroundColor: .yellow, backgroundColor: .black)
    }
    
    //MARK: - Privacy Section
    @SettingBuilder private var privacySection: some Setting {
        SettingPage(title: "Privacy") {
            SettingGroup {
                SettingToggle(title: "Automatically Pulls From Calendar", isOn: $model.automaticallyPullsFromCalendar)
                SettingToggle(title: "Enable Public Discoverability", isOn: $model.friendsDiscoverability)
            }
        }
        .previewIcon("lock.fill", foregroundColor: .white, backgroundColor: .gray.opacity(0.7))
    }
    
    //MARK: - Subscription Section
    @SettingBuilder private var subscriptionSection: some Setting {
        SettingPage(title: "Subscription") {
            SettingCustomView(id: "ProPlan") {
                Color.purple
                    .opacity(0.3)
                    .overlay {
                        SubscriptionProPlanView()
                    }
                    .frame(height: size.height * 0.7)
                    .cornerRadius(12)
                    .padding(.horizontal, 15)

            }
            
            if model.subscriptionPlanIsFree {
                SettingCustomView(id: "FreePlan") {
                    Color(uiColor: UIColor.lightGray)
                        .opacity(0.3)
                        .overlay {
                            SubscriptionFreePlanView()
                        }
                        .frame(height: size.height * 0.25)
                        .cornerRadius(12)
                        .padding(.horizontal, 15)
                }
            }
        }
        .previewIcon("bubbles.and.sparkles", foregroundColor: .white, backgroundColor: .purple)
    }
    
    //MARK: - Contributions Section
    @SettingBuilder private var contributionsSection: some Setting {
        SettingPage(title: "Contributions") {
            SettingGroup(id: "ContributionsExplaination") {
                SettingCustomView {
                    Text("Keeping TimeTangle's internal organs up and running is no joke! As a solo student developer, any help would be greatly appreciated! 🙏")
                        .foregroundColor(.gray)
                        .centered()
                        .padding(15)
                }
            }
            
            SettingGroup(id: "$0.99") {
                SettingCustomView(id: "$0.99") {
                    Button(action: {}) {
                        HStack {
                            Text("🎁 Gift")
                            Text("$0.99")
                                .bold()
                        }
                        .leftAligned()
                        .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.green)
                   
                    .padding(15)
                }
            }
            
            SettingGroup(id: "$1.99") {
                SettingCustomView(id: "$1.99") {
                    Button(action: {}) {
                        HStack {
                            Text("🎁 Gift")
                            Text("$1.99")
                                .bold()
                        }
                        .leftAligned()
                        .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.green)
                    .padding(15)
                }
            }
            
            SettingGroup(id: "$2.99") {
                SettingCustomView(id: "$2.99") {
                    Button(action: {}) {
                        HStack {
                            Text("🎁 Gift")
                            Text("$2.99")
                                .bold()
                        }
                        .leftAligned()
                        .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.green)
                    .padding(15)
                }
            }
        }
        .previewIcon("dollarsign", foregroundColor: .white, backgroundColor: .green)
    }
    
    //MARK: - Help Section
    @SettingBuilder private var helpSection: some Setting {
        SettingPage(title: "Help") {}
            .previewIcon("questionmark.circle.fill", foregroundColor: .white, backgroundColor: .blue)
    }
    
    //MARK: - About Section
    @SettingBuilder private var aboutSection: some Setting {
        SettingPage(title: "About") {
            SettingCustomView(id: "AppIcon") {
                Image(systemName: "app.fill")
                    .font(.system(size: 100))
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color(uiColor: .lightGray))
                    .centered()
            }
            
            SettingCustomView(id: "AppInfo") {
                VStack(spacing: 10) {
                    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("TimeTangle \(appVersion)")
                    }
                    
                    if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text("Build \(buildNumber)")
                    }
                    
                    Text("iOS \(UIDevice.current.systemVersion)")
                }
                .foregroundColor(.gray)
                .centered()
            }
            
            SettingCustomView(id: "About Me") {
                Text("TimeTangle is built by Justin Wong, a passionate iOS developer, Apple 🐑, & student at UC Berkeley studying EECS.")
                    .foregroundColor(.gray)
                    .centered()
                    .padding(15)
            }
            
            SettingGroup {
                SettingCustomView(id: "PrivacyPolicy") {
                    Group {
                        Button(action: {}) {
                            Text("Personal Website")
                                .foregroundColor(.blue)
                                .leftAligned()
                        }
                        Button(action: {}) {
                            Text("Privacy Policy")
                                .foregroundColor(.blue)
                                .leftAligned()
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(15)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .previewIcon("info.circle.fill", foregroundColor: .white, backgroundColor: .green)
    }
}

//MARK: - SettingsProfileHeaderView
struct SettingsProfileHeaderView: View {
    
    @State private var profileImage: UIImage?
    @State private var name: String = ""
    @State private var username: String = ""
    
    var body: some View {
        NavigationLink(destination: SettingsMyProfileView()) {
            HStack(spacing: 20) {
                TTSwiftUIProfileImageView(image: profileImage, size: 70)
                VStack(alignment: .leading) {
                    Text(name)
                        .foregroundColor(.primary)
                        .font(.title2.bold())
                    Text(username)
                        .foregroundColor(.secondary)
                    Text("Free Plan")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(15)
        }
        .onAppear {
            guard let currentUser = FirebaseManager.shared.currentUser else { return }
            if let imageData = currentUser.profilePictureData, let image = UIImage(data: imageData) {
                profileImage = image
            }
            name = currentUser.getFullName()
            username = currentUser.username
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
