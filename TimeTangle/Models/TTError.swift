//
//  TTError.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import Foundation

enum TTError: String, Error {
    //MARK: - Firebase
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
    
    case unableToCreateRoom = "Unable to create room. Please try again."
    case unableToFetchRoom = "Unable to fetch room. Please try again."
    case unableToUpdateRoom = "Unable to update room. Please try again."
    case unableToAddRoomHistory = "Unable to add room history."
    case unableToDeleteRoom = "Unable to delete room. Please try again."
    case unableToJoinRoom = "Unable to join specified room. Please check if room code is correctly inputed."
    
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
    
    //MARK: - Room Settings
    case invalidBoundedStartDate = "Bounded start date cannot be greater than bounded end date"
    case invalidBoundedEndDate = "Bounded end date cannot be less than bounded start date"
    case invalidMinimumNumOfUsersIndex = "Minimum number of users cannot be greater than maximmum number of users"
    case invalidMaximumNumOfUsersIndex = "Maximum number of users cannot be greater than minimum number of users"
}
