//
//  SettingsView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI
import Setting
import StoreKit
import MessageUI

//MARK: - SettingsViewModel
class SettingsViewModel: ObservableObject {
    @AppStorage(SettingsConstants.allowNotifications) var allowNotifications = true
    @AppStorage(SettingsConstants.friendsDiscoverability) var friendsDiscoverability = true
    @AppStorage(SettingsConstants.timePeriodToDeleteGroupsIndex) var timePeriodToDeleteGroupsIndex = 0
    @AppStorage(SettingsConstants.appearanceIndex) var appearanceIndex = 0
    @AppStorage(SettingsConstants.automaticallyPullsFromCalendar) var automaticallyPullsFromCalendar = true
    @AppStorage(SettingsConstants.subscriptionPlanIsFree) var subscriptionPlanIsFree = true 
}

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var storeViewModel = StoreViewModel()
    
    @State private var size: CGSize = .zero
    @State private var isPresentingSubscriptionSheet = false
    
    init(storeViewModel: StoreViewModel) {
        _storeViewModel = StateObject(wrappedValue: storeViewModel)
    }
    
    var body: some View {
        GeometryReader { geo in
            SettingStack {
                SettingPage(title: "Settings") {
                    profileHeaderSection
                    
                    SettingGroup(id: "SubscriptionHeaderView") {
                        if storeViewModel.currentSubscription == nil {
                            SettingCustomView {
                                Button(action: {
                                    isPresentingSubscriptionSheet.toggle()
                                }) {
                                    SubscriptionHeaderView()
                                }
                            }
                        }
                    }
                    
                    
                    SettingGroup {
                        if AppStore.canMakePayments && storeViewModel.currentSubscription != nil {
                            subscriptionSection
                        }
                        feedbackSection
                        aboutSection
                    }
                }
            }
            .tint(.green)
            .onAppear {
                size = geo.size
            }.onChange(of: geo.size) { newSize in
                size = newSize
            }
            .sheet(isPresented: $isPresentingSubscriptionSheet) {
                SubscriptionProPlanView()
                    .environmentObject(storeViewModel)
            }
            .onAppear {
                Task {
                    await storeViewModel.updateSubscriptionStatus()
                }
            }
            .onChange(of: storeViewModel.purchasedSubscriptions) {
                Task {
                    await storeViewModel.updateSubscriptionStatus()
                }
            }
        }
    }
    
    @SettingBuilder private var profileHeaderSection: some Setting {
        SettingGroup(id: "SettingsProfileHeaderView") {
            SettingCustomView {
                SettingsProfileHeaderView(currentSubscription: storeViewModel.currentSubscription)
            }
        }
    }
    
    //MARK: - Subscription Section
    @SettingBuilder private var subscriptionSection: some Setting {
        SettingPage(title: "Subscription") {
            SettingCustomView(id: "Subscription View") {
                SettingsSubscriptionView(currentSubscription: storeViewModel.currentSubscription, subscriptionStatus: storeViewModel.subscriptionStatus)
                    .environmentObject(storeViewModel)
                    .centered()
                    
            }
        }
        .previewIcon("bubbles.and.sparkles", foregroundColor: .white, backgroundColor: .purple)
    }
    
    //MARK: - Feedback Section
    @State private var isShowingFeatureRequestForm = false
    @State private var isShowingReportBugForm = false
    
    @SettingBuilder private var feedbackSection: some Setting {
        SettingPage(title: "Feedback") {
            SettingGroup {
                SettingCustomView {
                    VStack(spacing: 20) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 60))
                            .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .blue.opacity(0.7), strokeColor: .blue, frameWidth: 80, frameHeight: 80)
                            .shadow(color: .blue, radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                     
                        Text("TimeTangle is constantly improving, and we need your help! If you encounter any bugs or have a new idea please feel free to let us know!")
                            .bold()
                    }
                    .padding()
                    .background(.blue.opacity(0.2))
                    .sheet(isPresented: $isShowingFeatureRequestForm) {
                        FeedbackEmailFormView(formType: .featureRequest)
                            .ignoresSafeArea(.all)
                    }
                    .sheet(isPresented: $isShowingReportBugForm) {
                        FeedbackEmailFormView(formType: .bugReport)
                            .ignoresSafeArea(.all)
                    }
                }
            }
            
            if MFMailComposeViewController.canSendMail() {
                SettingGroup {
                    SettingButton(title: "Request New Feature") {
                        isShowingFeatureRequestForm.toggle()
                    }
                    .icon("hand.raised.fill", backgroundColor: .purple)
                }

                SettingGroup {
                    SettingButton(title: "Report Bug") {
                        isShowingReportBugForm.toggle()
                    }
                    .icon("ladybug.fill", backgroundColor: .red)
                }
            } else {
                SettingGroup {
                    SettingText(title: "Mail Services Are Not Available", foregroundColor: .red)
                }
            }
        }
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
                Text("TimeTangle is built by Justin Wong, a passionate iOS developer, Apple 🐑, & student at UC Berkeley studying Electrical Engineering & Computer Sciences.")
                    .foregroundColor(.gray)
                    .centered()
                    .padding(15)
            }
            
            SettingGroup {
                SettingCustomView(id: "PrivacyPolicy") {
                    Group {
                        Button(action: {}) {
                            Text("Personal Website")
                                .foregroundColor(.green)
                                .leftAligned()
                        }
                        Button(action: {}) {
                            Text("Privacy Policy")
                                .foregroundColor(.green)
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

//MARK: - SubscriptionHeaderView
struct SubscriptionHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Unleash With Pro!")
                    .font(.system(size: 25))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                Text("⭐️ Unlimited Groups")
                Text("⭐️ Custom Group Presets")
            }
            .foregroundColor(.primary)
            
            .fontWeight(.bold)
            Spacer()
            Text("🤩")
                .font(.system(size: 90))
            Spacer()
        }
        .padding(15)
        .background(.green.opacity(0.3))
    }
}

//MARK: - SettingsProfileHeaderView
struct SettingsProfileHeaderView: View {
    var currentSubscription: Product?
    
    @State private var profileImage: UIImage?
    @State private var name: String = ""
    @State private var id: String = ""
    
    var body: some View {
        NavigationLink(destination: SettingsMyProfileView()) {
            HStack(spacing: 20) {
                TTSwiftUIProfileImageView(user: FirebaseManager.shared.currentUser, image: profileImage, size: 120)
                VStack(alignment: .leading) {
                    Text(name)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .font(.title2.bold())
                    if currentSubscription == nil {
                        SubscriptionPlanBadgeView(isPro: false)
                    } else {
                        SubscriptionPlanBadgeView(isPro: true)
                    }
                   
                }
                Spacer()
            }
            .padding(15)
        }
        .onAppear {
            guard let currentUser = FirebaseManager.shared.currentUser else { return }
            currentUser.getProfilePictureUIImage { image in
                guard let image = image else { return }
                print("Gotten Image")
                profileImage = image
            }
            name = currentUser.getFullName()
            id = currentUser.id
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static let storeViewModel = StoreViewModel()
    static var previews: some View {
        SettingsView(storeViewModel: storeViewModel)
    }
}
