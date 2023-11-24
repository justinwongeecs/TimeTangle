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
        lhs.id == rhs.id
    }
    
    var firstname: String
    var lastname: String
    var id: String
    var friends: [String]
    var friendRequests: [TTFriendRequest]
    var groupCodes: [String]
    var groupPresets: [[String]]
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
    
    func getCompressedProfilePictureData(withQuality compressionQuality: CGFloat) -> Data? {
        guard let image = getProfilePictureUIImage() else { return nil }
        return image.jpegData(compressionQuality: compressionQuality)
    }
}
