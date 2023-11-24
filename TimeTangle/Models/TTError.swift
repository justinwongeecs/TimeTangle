//
//  TTError.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import Foundation

enum TTError: String, Error {
    //MARK: - Firebase
    case passwordsDoNotMatch = "Password and Confirm Password do not match."
    case unableToCreateUser = "Unable to create user. Please try again."
    case unableToCreateFirestoreAssociatedUser = "Unable to create database associated user."
    case textFieldsCannotBeEmpty = "Text fields cannot be empty"
    case unableToSignInUser = "Unable to sign in user. Please try again."
    case unableToSignOutUser = "Unable to sign out user. Please try again."
    case unableToUpdateUserProfile = "Unable to update user profile."
    
    case unableToFetchUsers = "DATABASE ERROR: Unable to fetch users. Please try again."
    case unableToDecodeUsers = "DATABASE ERROR: Unable to decode users."
    case cannotAddCurrentUser = "Cannot add user."
    
    case unableToUpdateUser = "Unable to update user fields."
    case unableToUpdateUserEmail = "Unable to update user email."
    
    case unableToCreateGroup = "Unable to create group. Please try again."
    case unableToFetchGroup = "Unable to fetch group. Please try again."
    case unableToUpdateGroup = "Unable to update group. Please try again."
    case unableToAddGroupHistory = "Unable to add group history."
    case unableToDeleteGroup = "Unable to delete group. Please try again."
    case unableToJoinGroup = "Unable to join specified group. Please check if group code is correctly inputed."
    
    //MARK: - Firebase Storage
    case unableToGetImageMetadata = "Unable to get image metadata"
    case unableToGetDownloadURL = "Unable to get image download URL."
    case unableToFetchImage = "Unable to fetch image from database."
    
    //MARK: - EventKit
    case unableToGetEventKitAccess = "Unable to get access to calendars."
    
    //MARK: - Internal App
    case friendAlreadyAdded = "User has already been added."
    case friendAlreadyRequested = "User has already been requested."
    
    case unableToFetchProfileImageFromUser = "Unable to get requested profile picture."
    
    //MARK: - Group Settings
    case invalidBoundedStartDate = "Bounded start date cannot be greater than bounded end date"
    case invalidBoundedEndDate = "Bounded end date cannot be less than bounded start date"
    case invalidMinimumNumOfUsersIndex = "Minimum number of users cannot be greater than maximmum number of users"
    case invalidMaximumNumOfUsersIndex = "Maximum number of users cannot be greater than minimum number of users"
}
