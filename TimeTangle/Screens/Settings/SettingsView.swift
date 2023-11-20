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
    
    @State private var currentSubscription: Product? = nil
    @State private var subscriptionStatus: Product.SubscriptionInfo.Status? = nil
    
    init(storeViewModel: StoreViewModel) {
        _storeViewModel = StateObject(wrappedValue: storeViewModel)
    }
    
    var body: some View {
        GeometryReader { geo in
            SettingStack {
                SettingPage(title: "Settings") {
                    profileHeaderSection
                    
                    SettingGroup(id: "SubscriptionHeaderView") {
                        if currentSubscription == nil {
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
                        privacySection
                        if currentSubscription != nil {
                            subscriptionSection
                        }
                        contributionsSection
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
                    await updateSubscriptionStatus()
                }
            }
            .onChange(of: storeViewModel.purchasedSubscriptions) {
                Task {
                    await updateSubscriptionStatus()
                }
            }
        }
    }
    
    @SettingBuilder private var profileHeaderSection: some Setting {
        SettingGroup(id: "SettingsProfileHeaderView") {
            SettingCustomView {
                SettingsProfileHeaderView(currentSubscription: currentSubscription)
            }
        }
    }
   
    //MARK: - Privacy Section
    @SettingBuilder private var privacySection: some Setting {
        SettingPage(title: "Privacy") {
            SettingGroup {
                SettingToggle(title: "Automatically Pulls From Calendar", isOn: $settingsViewModel.automaticallyPullsFromCalendar)
                SettingToggle(title: "Enable Public Discoverability", isOn: $settingsViewModel.friendsDiscoverability)
            }
        }
        .previewIcon("lock.fill", foregroundColor: .white, backgroundColor: .gray.opacity(0.7))
    }
    
    //MARK: - Subscription Section
    @SettingBuilder private var subscriptionSection: some Setting {
        SettingPage(title: "Subscription") {
            SettingCustomView(id: "Subscription View") {
                SettingsSubscriptionView(currentSubscription: currentSubscription, subscriptionStatus: subscriptionStatus)
                    .environmentObject(storeViewModel)
                    .centered()
                    
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
    
    //MARK: - Feedback Section
    @State private var isShowingFeatureRequestForm = false
    
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
    
    @MainActor
    func updateSubscriptionStatus() async {
        do {
            //This app has only one subscription group, so products in the subscriptions
            //array all belong to the same group. The statuses that
            //`product.subscription.status` returns apply to the entire subscription group.
            guard let product = storeViewModel.subscriptions.first,
                  let statuses = try await product.subscription?.status else {
                return
            }
            
//            var newSubscription: Product?

            //Iterate through `statuses` for this subscription group and find
            //the `Status` with the highest level of service that isn't
            //in an expired or revoked state. For example, a customer may be subscribed to the
            //same product with different levels of service through Family Sharing.
            for status in statuses {
                switch status.state {
                case .expired, .revoked:
                    continue
                default:
                    let renewalInfo = try storeViewModel.checkVerified(status.renewalInfo)

                    //Find the first subscription product that matches the subscription status renewal info by comparing the product IDs.
                    guard let newSubscription = storeViewModel.subscriptions.first(where: { $0.id == renewalInfo.currentProductID }) else {
                        continue
                    }
                    subscriptionStatus = status
                    currentSubscription = newSubscription
                    
                }
            }
        } catch {
            print("Could not update subscription status \(error)")
        }
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
    @State private var username: String = ""
    
    var body: some View {
        NavigationLink(destination: SettingsMyProfileView()) {
            HStack(spacing: 20) {
                TTSwiftUIProfileImageView(image: profileImage, size: 70)
                VStack(alignment: .leading) {
                    Text(name)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .font(.title2.bold())
                    Text(username)
                        .foregroundColor(.secondary)
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
            if let imageData = currentUser.profilePictureData, let image = UIImage(data: imageData) {
                profileImage = image
            }
            name = currentUser.getFullName()
            username = currentUser.username
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static let storeViewModel = StoreViewModel()
    static var previews: some View {
        SettingsView(storeViewModel: storeViewModel)
    }
}
