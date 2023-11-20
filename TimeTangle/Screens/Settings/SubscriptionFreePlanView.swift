//
//  SubscriptionProPlanView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI
import StoreKit

struct SubscriptionProPlanView: View {
    @EnvironmentObject var store: StoreViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedSubscriptionProduct: Product?
    @State private var errorTitle = ""
    @State private var isShowingError = false
    
    private var proMonthlyProduct: Product? {
        store.subscriptions.first{
            $0.id == TTConstants.proMonthlySubscriptionID
        }
    }
    
    private var proYearlyProduct: Product? {
        store.subscriptions.first {
            $0.id == TTConstants.proYearlySubscriptionID
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("Looking for a bit more 👀? ...")
                    .bold()
                ZStack {
                    HStack {
                        Spacer()
                        mainSection
                        Spacer()
                    }
                    .background(.green.opacity(0.2))
                    .cornerRadius(10)
                    .padding()
                    
                    Text("🤩")
                        .font(.system(size: 40))
                        .offset(x: 0, y: -230)
                }
                
                VStack(spacing: 10) {
                    getProPerYearButton
                    getProPerMonthButton
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {dismiss()}) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.3))
                            .font(.system(size: 25))
                    }
                }
            }
            .alert(errorTitle, isPresented: $isShowingError) {
                Button(role: .cancel, action: {}) {
                    Text("OK")
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack {
            Text("Pro Plan")
                .font(.largeTitle.bold())
            Text("$39.99 / Year")
                .bold()
                .foregroundColor(.green)
            Text("$3.99 / Month")
                .font(.caption)
                .foregroundColor(.green)
        }
    }
    
    private var mainSection: some View {
        VStack(alignment: .center, spacing: 10) {
            headerView
            
            VStack(alignment: .leading, spacing: 50) {
                SubscriptionFeatureInfoView(iconName: "infinity", featureName: "Unlimited Groups", featureSubtext: "Don't be restricted with just one group! Have and manage an unlimited number of groups")
                SubscriptionFeatureInfoView(iconName: "person.badge.shield.checkmark.fill", featureName: "Manage Groups", featureSubtext: "Assign and manage group admin users & additional group settings!")
                SubscriptionFeatureInfoView(iconName: "person.3.fill", featureName: "Preset Friend Groups", featureSubtext: "Create custom friend group presets so that you easily create a new groups without the hassle of adding one by one!")
            }
            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 20))
        }
        .padding()
    }
    
    private var getProPerYearButton: some View {
        Button(action: {
            selectedSubscriptionProduct = proYearlyProduct
            Task {
                await subscribe()
            }
        }) {
            HStack {
                HStack {
                    Text("Annual: ")
                    Text("$39.99")
                        .font(.title2)
                    Text("/ Year")
                }
                .bold()
                Spacer()
                
                RoundedRectangle(cornerRadius: 5)
                    .fill(.purple)
                    .frame(width: 90, height: 30)
                    .overlay(
                        Text("SAVE 20%!")
                            .font(.caption).bold()
                            .foregroundStyle(.white)
                    )
            }
            .padding()
            .foregroundColor(.white)
            .background(.purple.opacity(0.6))
            .cornerRadius(10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.purple, lineWidth: 2)
        )
    }
    
    private var getProPerMonthButton: some View {
        Button(action: {
            selectedSubscriptionProduct = proMonthlyProduct
            Task{
                await subscribe()
            }
        }) {
            HStack {
                Text("Monthly: ")
                Text("$3.99")
                    .font(.title2)
                Text("/ Month")
                Spacer()
            }
            .bold()
            .padding()
            .foregroundColor(.white)
            .background(.green.opacity(0.7))
            .cornerRadius(10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.green, lineWidth: 2)
        )
    }
    
    private func subscribe() async {
        do {
            if let selectedSubscriptionProduct = selectedSubscriptionProduct, try await store.purchase(selectedSubscriptionProduct) != nil {
                dismiss()
            }
        } catch TTStoreError.failedVerification {
            errorTitle = "Your purchase could not be verified by the App Store"
            isShowingError = true
        } catch {
            errorTitle = "Failed purchase for \(selectedSubscriptionProduct?.id ?? "subscription"): \(error)"
        }
    }
}

//MARK: - SubscriptionFeatureInfoView
struct SubscriptionFeatureInfoView: View {
    var iconName: String
    var featureName: String
    var featureSubtext: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(featureName)
                        .font(.headline.bold())
                }
                Text(featureSubtext)
                    .font(.caption)
            }
        }
    }
}

struct ProPlanInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionProPlanView()
    }
}
