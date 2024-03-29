//
//  TTConstants.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import UIKit

struct TTConstants {
    
    //MARK: - Firebase
    static let usersCollection = "users"
    static let groupsCollection = "groups"
    
    //MARK: - TTUser
    static let firstname = "firstname"
    static let friendRequests = "friendRequests"
    static let friends = "friends"
    static let lastname = "lastname"
    static let id = "id"
    static let groupCodes = "groupCodes"
    static let profilePictureURLString = "profilePictureURLString"
    static let email = "email"
    static let phoneNumber = "phoneNumber"
    static let groupPresets = "groupPresets"
    
    //MARK: - TTFriendRequest
    static let recipientID = "recipientID"
    static let requestType = "requestType"
    static let senderID = "senderID"
    static let senderProfilePictureURLString = "senderProfilePictureURLString"
    static let recipientProfilePictureURLString = "recipientProfilePictureURLString"
    
    //MARK: - TTGroup
    static let groupCode = "code"
    static let groupName = "name"
    static let groupUsers = "users"
    static let groupStartingDate = "startingDate"
    static let groupEndingDate = "endingDate"
    static let groupHistories = "histories"
    static let groupAdmins = "admins"
    static let groupEvents = "events"
    
    static let groupMinNumOfUsers = 2
    static let groupMaxNumOfUsers = 10
    
    //MARK: - TTGroupSetting
    static let groupSettingMinimumNumOfUsers = "setting.minimumNumOfUsers"
    static let groupSettingMaximumNumOfUsers = "setting.maximumNumOfUsers"
    static let groupSettingBoundedStartDate = "setting.boundedStartDate"
    static let groupSettingBoundedEndDate = "setting.boundedEndDate"
    static let groupSettingLockGroupChanges = "setting.lockGroupChanges"
    static let groupSettingAllowGroupJoin = "setting.allowGroupJoin"
    
    static let userDefaultsUpdatedGroupCodes = "userDefaultsUpdatedGroupCodes"
    
    //MARK: - UI
    static let emptyStateViewTag = 100
    static let profileImageViewInCellHeightAndWidth: CGFloat = 48
    static let defaultCellHeight: CGFloat = 60
    static let defaultCellColor: UIColor = .systemGreen
    static let defaultCellHeaderAndFooterHeight: CGFloat = 7
    
    //MARK: - StoreKit
    static let storeProductIDs: [String] = [
        "subscription.pro.monthly",
        "subscription.pro.yearly"
    ]
    static let proMonthlySubscriptionID: String = "subscription.pro.monthly"
    static let proYearlySubscriptionID: String = "subscription.pro.yearly"
    
    //MARK: - Subscription Restrictions
    static let freePlanGroupCountMax: Int = 1
}

