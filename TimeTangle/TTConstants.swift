//
//  TTConstants.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import Foundation

struct TTConstants {
    
    //MARK: - Firebase
    static let usersCollection = "users"
    static let roomsCollection = "rooms"
    
    //TTUser
    static let firstname = "firstname"
    static let friendRequests = "friendRequests"
    static let friends = "friends"
    static let lastname = "lastname"
    static let username = "username"
    static let roomCodes = "roomCodes"
    static let profilePictureURL = "profilePictureURL"
    static let profilePictureData = "profilePictureData"
    
    //TTFriendRequest
    static let recipientUsername = "recipientUsername"
    static let requestType = "requestType"
    static let senderUsername = "senderUsername"
    
    //TTRoom
    static let roomCode = "code"
    static let roomName = "name"
    static let roomUsers = "users"
    static let roomStartingDate = "startingDate"
    static let roomEndingDate = "endingDate"
    static let roomHistories = "histories"
    static let roomAdmins = "admins"
    static let roomEvents = "events"
    //MARK: - UI
    static let emptyStateViewTag = 100
    
    static let firestoreMaximumImageDataBytes = 1048487
}
