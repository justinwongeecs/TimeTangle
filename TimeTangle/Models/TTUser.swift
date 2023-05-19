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
}

struct TTEvent: Codable, Equatable {
    var name: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "startDate": startDate,
            "endDate": endDate,
            "isAllDay": isAllDay
        ]
    }
    
    static func == (lhs: TTEvent, rhs: TTEvent) -> Bool {
        return lhs.name == rhs.name &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.isAllDay == rhs.isAllDay
    }
}

//struct TTRoomEvent: Codable {
//    var ownerUsername: String
//    var events: [TTEvent]
//}
