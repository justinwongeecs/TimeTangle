//
//  SettingsManager.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import Foundation

struct SettingsConstants {
    static let allowNotifications = "AllowNotifications"
    static let friendsDiscoverability = "FriendsDiscoverability"
    static let deleteAccount = "DeleteAccount"
    static let timePeriodToDeleteRoomsIndex = "TimePeriodToDeleteRoomsIndex"
    static let appearanceIndex = "AppearanceIndex"
    static let automaticallyPullsFromCalendar = "AutomaticallyPullsFromCalendar"
    static let subscriptionPlanIsFree = "SubscriptionPlanIsFree"
}

class SettingsManager {
    private static let defaults = UserDefaults.standard
    
    static func setAllowNotifications(to bool: Bool) {
        return defaults.set(bool, forKey: SettingsConstants.allowNotifications)
    }
    
    static func getAllowNotifications() -> Bool {
        return defaults.bool(forKey: SettingsConstants.allowNotifications)
    }
    
    static func setFriendsDiscoverability(to bool: Bool) {
        return defaults.set(bool, forKey: SettingsConstants.friendsDiscoverability)
    }
    
    static func getFriendsDiscoverability() -> Bool {
        return defaults.bool(forKey: SettingsConstants.friendsDiscoverability)
    }
}
