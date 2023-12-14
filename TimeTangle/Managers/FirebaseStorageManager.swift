//
//  FirebaseStorageManager.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/4/23.
//

import UIKit
import FirebaseStorage

class FirebaseStorageManager {
    
    static let shared = FirebaseStorageManager()
    let userImagesCache = TTCache<URL, UIImage>()
    private let storageRef = Storage.storage().reference()
    
    func uploadProfilePicture(for image: UIImage, completion: @escaping(Result<URL, TTError>) -> Void) {
        guard let imageData: Data = image.jpegData(compressionQuality: 0.001) else { return }
        
        guard let currentUserID = FirebaseManager.shared.currentUser?.id else { return }
        let profileImageRef = storageRef.child("profileImages/\(currentUserID).png")
        _ = profileImageRef.putData(imageData, metadata: nil) { metaData, error in
            //access download url
            profileImageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    completion(.failure(TTError.unableToGetDownloadURL))
                    return
                } // error occurred
                completion(.success(downloadURL))
            }
        }
    }
    
    func fetchImage(for userID: String, url: URL, completion: @escaping(Result<UIImage, TTError>) -> Void) {
        print("Fetch Image")
        
        let profileImageRef = storageRef.child("profileImages/\(userID).png")
        profileImageRef.getData(maxSize: 1 * 1024 * 1024) { [weak self] data, error in
            if let error = error {
                completion(.failure(TTError.unableToFetchImage))
            } else {
                guard let data = data else { return }
                if let image = UIImage(data: data) {
                    self?.userImagesCache.insert(image, forKey: url)
                    completion(.success(image))
                }
            }
        }
    }
}
