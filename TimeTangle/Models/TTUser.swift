//
//  TTUser.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit
import FirebaseFirestoreSwift

struct TTUser: Codable, Equatable {
    static func == (lhs: TTUser, rhs: TTUser) -> Bool {
        lhs.uid == rhs.uid
    }
    
//    @DocumentID public var id: String?
    
    var firstname: String
    var lastname: String
    var username: String
    var uid: String
    var friends: [String]
    var friendRequests: [TTFriendRequest]
    var roomCodes: [String]
    var profilePictureURL: String?
    var profilePictureData: Data?
}
