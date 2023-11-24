//
//  SettingsSubscriptionView.swift
//  TimeTangle
//
//  Created by Justin Wong on 11/1/23.
//

import SwiftUI
import StoreKit

struct SettingsSubscriptionView: View {
    @EnvironmentObject var store: StoreViewModel
    
    var currentSubscription: Product?
    var otherSubscription: Product? {
        availableSubscriptions.filter{ $0.id != currentSubscription?.id }.first
    }
    var subscriptionStatus: Product.SubscriptionInfo.Status?
    
    var availableSubscriptions: [Product] {
        store.subscriptions.filter { $0.id != currentSubscription?.id }
    }
    
    @State private var currentSubscriptionRenewalDate: String = ""
    @State private var otherSubscriptionRenewalDate: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if let currentSubscription = currentSubscription {
                    Text("CURRENT SUBSCRIPTION")
                        .foregroundStyle(.secondary)
                    SubscriptionView(subscription: currentSubscription, currentSubscription: currentSubscription)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
                  
                    
                    if let otherSubscription = otherSubscription {
                        Text("OTHER SUBSCRIPTIONS")
                            .foregroundStyle(.secondary)
                        SubscriptionView(subscription: otherSubscription, currentSubscription: currentSubscription)
                                .environmentObject(store)
                    }
                } else {
                    if let subscriptionGroupStatus = store.subscriptionGroupStatus, subscriptionGroupStatus == .inBillingRetryPeriod {
                        //The best practice for subscriptions in the billing retry state is to provide a deep link
                        //from your app to https://apps.apple.com/account/billing.
                        inBillingRetryPeriodView
                    } else {
                        emptyView
                    }
                }
                restorePurchasesButton
            }
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                if let currentSubscription = currentSubscription {
                    currentSubscriptionRenewalDate = await store.getSubscriptionRenewalOrExpirationDate(product: currentSubscription)
                }
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            exclamationTriangleView
            Text("Unable to find current subscription information")
                .font(.title).bold()
                .multilineTextAlignment(.center)
        }
    }
    
    private var restorePurchasesButton: some View {
        Button(action: {
            Task {
                try? await AppStore.sync()
            }
        }) {
            Text("Restore Purchases")
                .foregroundStyle(.green)
        }
        .padding()
    }
    
    private var inBillingRetryPeriodView: some View {
        VStack(spacing: 20) {
            exclamationTriangleView
            Text("Please verify your account billing information")
                .font(.title2).bold()
                .multilineTextAlignment(.center)
            HStack {
                Image(systemName: "link")
                Link("Visit Account Billing Information", destination: URL(string: "https://www.apple.com")!)
                    .font(.headline)
            }
            .foregroundStyle(.green)
            .padding(8)
            .background(.green.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
        }
    }
    
    private var exclamationTriangleView: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .font(.system(size: 70))
    }
}

//MARK: - SubscriptionView
struct SubscriptionView: View {
    @EnvironmentObject var store: StoreViewModel
    var subscription: Product
    var currentSubscription: Product
    
    private var isCurrentSubscription: Bool {
        subscription.id == currentSubscription.id
    }
    
    @State private var isHidingSubscriptionStatusView = false
    @State private var subscriptionStatusText = ""
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Spacer()
                if !isCurrentSubscription {
                    subscriptionBadgeView
                    Spacer()
                }
                subscriptionInfoView
                Spacer()
                
                if isCurrentSubscription {
                    activeSubscriptionBadge
                } else {
                    switchButton
                }
                Spacer()
            }
            
            if !isHidingSubscriptionStatusView {
                subscriptionStatusView
            }
        }
        .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: isCurrentSubscription ? .green : .purple, fillColorOpacity: 0.2, strokeColor: isCurrentSubscription ? .green : .purple, strokeLineWidth: 1, frameHeight: 150)
        .padding()
        .onAppear {
            Task {
                if let subscriptionStatus = try await subscription.subscription?.status.first {
                    let renewalInfo = try store.checkVerified(subscriptionStatus.renewalInfo)
                    let transaction = try store.checkVerified(subscriptionStatus.transaction)
                    let autoRenewProductId = renewalInfo.autoRenewPreference
                    
                    let renewalOrEndingDate = transaction.expirationDate?.formatted(with: "MM/d/YYYY") ?? "[Can't Fetch Date]"
                    
                    if subscription.id == currentSubscription.id && autoRenewProductId == currentSubscription.id {
                        subscriptionStatusText = "Renews or Ends on \(renewalOrEndingDate)"
                    } else if autoRenewProductId == subscription.id {
                        subscriptionStatusText = "Begins After Current Subscription Ends"
                    } else if subscription.id == currentSubscription.id {
                        subscriptionStatusText = "Ends on \(renewalOrEndingDate)"
                    } else {
                        isHidingSubscriptionStatusView = true
                    }
                }
            }
        }
    }
    
    private var subscriptionBadgeView: some View {
        VStack {
            Text("PRO")
                .font(.title2).fontWeight(.heavy)
            durationText
        }
        .foregroundStyle(.white)
        .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .purple, strokeColor: .purple, frameWidth: 80, frameHeight: 80)
    }
    
    private var durationText: some View {
        Text(subscription.id == TTConstants.proYearlySubscriptionID ? "Yearly" : "Monthly")
            .font(.subheadline).bold()
    }
    
    private var subscriptionInfoView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(subscription.displayName)
                .font(.title2).bold()
            HStack {
                Text(subscription.displayPrice )
                Text(subscription.id == TTConstants.proMonthlySubscriptionID ? "\\ Month" : "\\ Year")
            }
            .foregroundStyle(.secondary)
        }
    }
    
    private var activeSubscriptionBadge: some View {
        Text("Active")
            .fontWeight(.heavy)
            .foregroundStyle(.green)
    }
    
    private var switchButton: some View {
        Button(action: {
            Task {
                await subscribe()
            }
        }) {
            Text("Switch")
                .foregroundStyle(.purple)
                .bold()
        }
        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
        .background(.purple.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var subscriptionStatusView: some View {
        Text(subscriptionStatusText)
                .bold()
                .foregroundStyle(.gray)
    }
    
    private func subscribe() async {
        do {
            if try await store.purchase(subscription) != nil {
                print("Buy succeeded")
            }
        }/* catch StoreError.failedVerification {*/
//            errorTitle = "Your purchase could not be verified by the App Store."
//            isShowingError = true
        catch {
//            print("Failed purchase for \(product.id): \(error)")
        }
    }
}

#Preview {
    SettingsSubscriptionView()
        .environmentObject(StoreViewModel())
}
