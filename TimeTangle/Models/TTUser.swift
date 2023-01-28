//
//  TTUser.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import Foundation
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
    var events: [TTEvent]
}

struct TTEvent: Codable {
    var name: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
}

//struct TTRoomEvent: Codable {
//    var ownerUsername: String
//    var events: [TTEvent]
//}
