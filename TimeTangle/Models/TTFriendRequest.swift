//
//  TTFriendRequest.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import Foundation

typealias TTFriendRequestType = TTFriendRequest.TTFriendRequestType

struct TTFriendRequest: Codable {
    var profilePictureData: Data?
    var senderUsername: String
    var recipientUsername: String
    var requestType: TTFriendRequestType
    
    var dictionary: [String: String] {
        return [
            "senderUsername": senderUsername,
            "recipientUsername": recipientUsername,
            "requestType": requestType.description,
            "profilePictureData": convertProfilePictureDataToString()
        ]
    }
    
    enum TTFriendRequestType: String {
        //We can see which "way" outgoing is either from the current user's or the receiving end's perspective by comparing the user property vs the current user
        case outgoing
        case receiving
        case accepted
        case declined

        var description: String {
            get {
                switch self {
                case .outgoing: return "Outgoing"
                case .receiving: return "Receiving"
                case .accepted: return "Accepted"
                case .declined: return "Declined"
                }
            }
        }
        
        static func getTTFriendRequestType(requestType: String) -> TTFriendRequestType  {
            switch requestType {
            case "Outgoing":
                return .outgoing
            case "Receiving":
                return .receiving
            case "Accepted":
                return .accepted
            case "Declined":
                return .declined
            default:
                return .outgoing
            }
        }
    }
    
    private func convertProfilePictureDataToString() -> String {
        if let profilePictureData = profilePictureData, let dataString = String(data: profilePictureData, encoding: .utf8) {
            return dataString
        }
        return ""
    }
}

extension TTFriendRequestType: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = TTFriendRequestType.getTTFriendRequestType(requestType: rawValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}



