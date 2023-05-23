//
//  FirebaseStorageManager.swift
//  TimeTangle
//
//  Created by Justin Wong on 1/4/23.
//

import UIKit
import FirebaseStorage

class FirebaseStorageManager {
    
    private let storageRef = Storage.storage().reference()
    
    func uploadProfilePicture(for image: UIImage, completion: @escaping(Result<URL, TTError>) -> Void) {
        guard let imageData: Data = image.jpegData(compressionQuality: 0.5) else { return }
        
        guard let currentUserUsername = FirebaseManager.shared.currentUser?.username else { return }
        let profileImageRef = storageRef.child("profileImages/\(currentUserUsername).png")
        let uploadTask = profileImageRef.putData(imageData, metadata: nil) { metaData, error in
//            guard let metaData = metaData else {
//                completion(.failure(TTError.unableToGetImageMetadata))
//                return
//            } //error occurred
            //access download url
            profileImageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print(error)
                    completion(.failure(TTError.unableToGetDownloadURL))
                    return
                } // error occurred
                completion(.success(downloadURL))
            }
        }
    }
    
    func fetchImage(for url: URL, completion: @escaping(Result<UIImage, TTError>) -> Void) {
        guard let currentUserUsername = FirebaseManager.shared.currentUser?.username else { return }
        let profileImageRef = storageRef.child("profileImages/\(currentUserUsername).png")
        profileImageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let _ = error{
                completion(.failure(TTError.unableToFetchImage))
            } else {
                guard let data = data else { return }
                if let image = UIImage(data: data) {
                    completion(.success(image))
                }
            }
        }
    }
}
