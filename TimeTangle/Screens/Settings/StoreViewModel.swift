//
//  StoreViewModel.swift
//  TimeTangle
//
//  Created by Justin Wong on 10/31/23.
//

import SwiftUI
import StoreKit

typealias Transaction = StoreKit.Transaction
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

enum TTStoreError: Error {
    case failedVerification
}

enum TTSubscriptionType {
    case proMonthly
    case proYearly
    case none
}

class StoreViewModel: ObservableObject {
    @Published private(set) var subscriptions = [Product]()
    @Published private(set) var purchasedSubscriptions = [Product]()
    @Published private(set) var subscriptionGroupStatus: RenewalState?
    @Published private(set) var currentSubscription: Product? = nil
    @Published private(set) var subscriptionStatus: Product.SubscriptionInfo.Status? = nil
    
    var isSubscriptionPro: Bool {
        return currentSubscription != nil
    }
    
    var updateListenerTask: Task<Void, Error>? = nil
    var subscriptionStatusUpdateListenerTask: Task<Void, Error>? = nil
    
    init() {
        updateListenerTask = listenForTransactions()
        subscriptionStatusUpdateListenerTask = listenForSubscriptionUpdates()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        subscriptionStatusUpdateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            print("Listen for transactions")
            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    //TODO: Deliver products to the user.
                    await self.updateCustomerProductStatus()
                    
                    //Always finish a transaction.
                    await transaction.finish()
                } catch {
                    //StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    func listenForSubscriptionUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await _ in Product.SubscriptionInfo.Status.updates {
                await self.updateCustomerProductStatus()
            }
        }
    }
    
    @MainActor
    func requestProducts() async {
        do {
            //Request products from the App Store using the identifiers that the Products.plist file defines.
            let storeProducts = try await Product.products(for: TTConstants.storeProductIDs)

            var newSubscriptions: [Product] = []

            //Filter the products into categories based on their type.
            for product in storeProducts {
                switch product.type {
                case .consumable:
                    break
                case .nonConsumable:
                    break
                case .autoRenewable:
                    newSubscriptions.append(product)
                case .nonRenewable:
                    break
                default:
                    //Ignore this product.
                    print("Unknown product")
                }
            }

            //Sort each product category by price, lowest to highest, to update the store.
            subscriptions = sortByPrice(newSubscriptions)
        } catch {
            print("Failed product request from the App Store server: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        //Begin purchasing the `Product` the user selects.
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            //Check whether the transaction is verified. If it isn't,
            //this function rethrows the verification error.
            let transaction = try checkVerified(verification)

            //The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()

            //Always finish a transaction.
            await transaction.finish()

            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }

    func isPurchased(_ product: Product) async throws -> Bool {
        //Determine whether the user purchases a given product.
        switch product.type {
        case .nonRenewable:
            break
        case .nonConsumable:
            break
        case .autoRenewable:
            return purchasedSubscriptions.contains(product)
        default:
            return false
        }
        return false 
    }

    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedSubscriptions: [Product] = []

        //Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)

                //Check the `productType` of the transaction and get the corresponding product from the store.
                print("Transaction: \(transaction)")
                switch transaction.productType {
                case .nonConsumable:
                    break
                case .nonRenewable:
                    break
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }
                default:
                    break
                }
            } catch {
                print()
            }
        }
        
        //Update the store information with auto-renewable subscription products.
        self.purchasedSubscriptions = purchasedSubscriptions
        print("Purchased Subscriptions: \(purchasedSubscriptions)")

        //Check the `subscriptionGroupStatus` to learn the auto-renewable subscription state to determine whether the customer
        //is new (never subscribed), active, or inactive (expired subscription). This app has only one subscription
        //group, so products in the subscriptions array all belong to the same group. The statuses that
        // `product.subscription.status` returns apply to the entire subscription group.
        subscriptionGroupStatus = try? await subscriptions.first?.subscription?.status.first?.state
    }
    
    @MainActor
    func updateSubscriptionStatus() async {
        do {
            //This app has only one subscription group, so products in the subscriptions
            //array all belong to the same group. The statuses that
            //`product.subscription.status` returns apply to the entire subscription group.
            guard let product = subscriptions.first,
                  let statuses = try await product.subscription?.status else {
                return
            }

            //Iterate through `statuses` for this subscription group and find
            //the `Status` with the highest level of service that isn't
            //in an expired or revoked state. For example, a customer may be subscribed to the
            //same product with different levels of service through Family Sharing.
            for status in statuses {
                switch status.state {
                case .expired, .revoked:
                    continue
                default:
                    let renewalInfo = try checkVerified(status.renewalInfo)

                    //Find the first subscription product that matches the subscription status renewal info by comparing the product IDs.
                    guard let newSubscription = subscriptions.first(where: { $0.id == renewalInfo.currentProductID }) else {
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
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw TTStoreError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }
    
    func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { return $0.price < $1.price })
    }
    
    func getSubscriptionType(for productID: String) -> TTSubscriptionType {
        switch productID {
        case TTConstants.proMonthlySubscriptionID:
            return .proMonthly
        case TTConstants.proYearlySubscriptionID:
            return .proYearly
        default:
            return .none
        }
    }
    
    func getSubscriptionRenewalOrExpirationDate(product: Product) async -> String {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if product.id == transaction.productID {
                    // A susbcriptions expiration date is returns the information for a renewal or expiration.
                    if let date = transaction.expirationDate {
                        return date.formatted(date: .numeric, time: .omitted)
                    } else {
                        // The product is a subscription but does not have a renewal or expiration date.
                        return "Does Not Have Renewal Or Expiration Date"
                    }
                }
            } catch {
                // Do Nothing
            }
        }

        return ""
    }
}
