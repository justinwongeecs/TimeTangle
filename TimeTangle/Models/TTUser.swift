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
    
    var firstname: String
    var lastname: String
    var username: String
    var uid: String
    var friends: [String]
    var friendRequests: [TTFriendRequest]
    var groupCodes: [String]
    var profilePictureData: Data?
    
    //Contact Information
    var phoneNumber: String = ""
    var email: String = ""
    
    func getFullName() -> String {
        return "\(firstname) \(lastname)"
    }
    
    func getProfilePictureUIImage() -> UIImage? {
        if let imageData = profilePictureData, let image = UIImage(data: imageData) {
            return image
        }
        return nil
    }
}
