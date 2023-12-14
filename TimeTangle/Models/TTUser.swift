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
    var groupPresets: [TTGroupPreset]
    var profilePictureURLString: String?
    
    //Contact Information
    var phoneNumber: String = ""
    var email: String = ""
    
    func getFullName() -> String {
        return "\(firstname) \(lastname)"
    }
    
    func getProfilePictureUIImage(completion: @escaping(UIImage?) -> Void) {
        guard let profilePictureURLString = profilePictureURLString, let profilePictureURL = URL(string: profilePictureURLString) else { return completion(nil) }
        if let image = FirebaseStorageManager.shared.userImagesCache.value(forKey: profilePictureURL) {
            return completion(image)
        } else {
            FirebaseStorageManager.shared.fetchImage(for: id, url: profilePictureURL) { result in
                switch result {
                case .success(let image):
                    FirebaseStorageManager.shared.userImagesCache.insert(image, forKey: profilePictureURL)
                    completion(image)
                case .failure(_):
                    completion(nil)
                }
            }
        }
    }
}
