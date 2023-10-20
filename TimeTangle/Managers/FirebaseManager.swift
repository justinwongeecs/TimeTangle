//
//  FirebaseManager.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    private let ekManager = EventKitManager()
    private var handle: AuthStateDidChangeListenerHandle?
    private var currentUserGroupsListener: ListenerRegistration?
    private let sceneWindow = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window
    private let notificationCenter = NotificationCenter.default
    
    var currentUser: TTUser?
    
    func listenToAuthChanges() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            print("auth changed")
            if let user = user, let displayName = user.displayName {
                print(displayName)
                self?.fetchUserDocumentData(with: displayName) { result in
                    switch result {
                    case .success(let user):
                        print("User: \(user)")
                        self?.currentUser = user
                        self?.goToSearchScreen()
                        self?.listenToCurrentUser()
                        self?.listenToCurrentUserGroups()
                    case .failure(_):
                        print("failure")
                    }
                }
            } else {
                self?.currentUser = nil
                self?.goToLoginScreen()
            }
        }
    }
    
    private var currentUserListener: ListenerRegistration?
    
    private func listenToCurrentUser() {
        guard let username = currentUser?.username else { return }
        
        currentUserListener = db.collection(TTConstants.usersCollection).document(username).addSnapshotListener { [weak self] docSnapshot, error in
            guard let document = docSnapshot else { return }
            do {
                print("Update to current user")
                let currentUserData = try document.data(as: TTUser.self)
                self?.currentUser = currentUserData
                //Is this the right way to do this lol? 
                self?.currentUserGroupsListener?.remove()
                self?.listenToCurrentUserGroups()
                self?.broadcastUpdatedUser()
            } catch {
                print("Can't listen to current user")
            }
        }
    }
    
    private func stopListeningToCurrentUser() {
        guard let currentUserListener = currentUserListener else { return }
        
        currentUserListener.remove()
    }
    
    func broadcastUpdatedUser() {
        notificationCenter.post(name: .updatedUser, object: currentUser)
    }
    
    private func goToSearchScreen() {
        sceneWindow?.rootViewController = FirebaseManager.shared.createTabbar()
        sceneWindow?.makeKeyAndVisible()
    }
    
    private func goToLoginScreen(animated: Bool = false) {
        if animated {
            UIView.animate(withDuration: 2) {
                self.sceneWindow?.rootViewController = LoginVC()
                self.sceneWindow?.rootViewController?.view.layer.opacity = 0.3
                self.sceneWindow?.makeKeyAndVisible()

            } completion: { _ in
                UIView.animate(withDuration: 1.5) {
                    self.sceneWindow?.rootViewController?.view.layer.opacity = 1
                }
            }
        } else {
            self.sceneWindow?.rootViewController = LoginVC()
            self.sceneWindow?.makeKeyAndVisible()
        }
    }
    
    
    //MARK: - Firestore User
    
    func fetchUsers(completed: @escaping(Result<[TTUser], TTError>) -> Void) {
        db.collection("users").getDocuments() { (querySnapshot, err) in
            if let _ = err {
                completed(.failure(.unableToFetchUsers))
            } else {
                var ttUsers: [TTUser] = []
                guard let documents = querySnapshot?.documents else { return }
                
                //convert all documents into TTUser objects
                ttUsers = documents.compactMap { queryDocumentsnapshot -> TTUser? in
                    return try? queryDocumentsnapshot.data(as: TTUser.self)
                }
                completed(.success(ttUsers))
            }
        }
    }
    
    func fetchUserDocumentData(with docId: String, completed: @escaping(Result<TTUser, TTError>) -> Void) {
        
        let docRef = db.collection("users").document(docId)
        
        //docRef.getDocument(as: TTUser.self) gives ambiguous context error for some reason
        
        docRef.getDocument { document, error in
            guard let _ = error else {
                if let doc = document {
                    do {
                        print("fetch nice")
                        let docUser = try doc.data(as: TTUser.self)
                        completed(.success(docUser))
                    } catch {
                        print("fetch error - -")
                        completed(.failure(.unableToFetchUsers))
                    }
                    
                }
                print("doc error - ")
                return
            }
            print("fetch error - ")
            completed(.failure(.unableToFetchUsers))
        }
    }
    
    func fetchMultipleUsersDocumentData(with usernames: [String], completed: @escaping(Result<[TTUser], TTError>) -> Void) {
        if !usernames.isEmpty {
            db.collection("users").whereField("username", in: usernames).getDocuments() { querySnapshot, err in
                if let _ = err {
                    completed(.failure(TTError.unableToFetchUsers))
                } else {
                    var users = [TTUser]()
                    for document in querySnapshot!.documents {
                        do {
                            users.append( try document.data(as: TTUser.self))
                        } catch {
                            completed(.failure(TTError.unableToFetchUsers))
                        }
                    }
                    completed(.success(users))
                }
            }
        }
    }
    
    func updateUserData(for username: String, with fields: [String: Any], completed: @escaping(TTError?) -> Void) {
        
        db.collection(TTConstants.usersCollection).document(username).updateData(fields) { [weak self] error in
            guard error == nil else {
                completed(TTError.unableToUpdateUser)
                return
            }
            
            self?.fetchUserDocumentData(with: username) { result in
                switch result {
                case .success(_):
                    completed(nil)
                case .failure(_):
                    completed(TTError.unableToUpdateUser)
                }
            }
        }
    }
    
    private func updateUserProfile(displayName: String) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = displayName
        changeRequest?.commitChanges { error in
            guard error == nil else { return }
        }
    }
    
    func updateUserEmail(with newEmail: String, completion: @escaping(TTError?) -> Void) {
        Auth.auth().currentUser?.updateEmail(to: newEmail) { error in
            guard error == nil else {
                completion(TTError.unableToUpdateUserEmail)
                return 
            }
        }
    }
    
    //MARK: - Firestore Group
    func listenToCurrentUserGroups() {
        guard let currentUserGroupCodes = currentUser?.groupCodes, currentUserGroupCodes.count > 0 else { return }

        currentUserGroupsListener = db.collection(TTConstants.groupsCollection).whereField(TTConstants.groupCode, in: currentUserGroupCodes).addSnapshotListener { [weak self] querySnapshot, error in
            guard let documents = querySnapshot?.documentChanges else {
                print("Error fetching doucments")
                return
            }
            
            var groupModifications = [TTGroupModification]()
            
            documents.forEach { diff in
                do {
                    let modifiedGroup = try diff.document.data(as: TTGroup.self)
                    groupModifications.append(TTGroupModification(group: modifiedGroup, modificationType: diff.type))
                    print("send updated groups notification ")
                } catch {
                    //Error get groupsData
                }
            }
            
            self?.notificationCenter.post(name: .updatedCurrentUserGroups, object: groupModifications)
        }
    }
    
    func createGroup(for group: TTGroup, completed: @escaping(Result<Void, TTError>) -> Void) {
        do {
            try db.collection(TTConstants.groupsCollection).document(group.code).setData(from: group)
            completed(.success(()))
        } catch {
            //TODO: Catch Firestore Error
            completed(.failure(.unableToCreateGroup))
        }
    }
    
    func fetchGroup(for groupCode: String, completed: @escaping(Result<TTGroup, TTError>) -> Void) {
        let groupDocRef = db.collection(TTConstants.groupsCollection).document(groupCode)
        groupDocRef.getDocument(as: TTGroup.self) { result in
            switch result {
            case .success(let group):
                completed(.success(group))
            case .failure(let error):
                print("Fetch group error: \(error)")
                completed(.failure(.unableToFetchGroup))
            }
        }
    }
    
    func updateGroup(for groupCode: String, with fields: [String: Any], completed: @escaping(TTError?) -> Void) {
        db.collection(TTConstants.groupsCollection).document(groupCode).updateData(fields) { error in
            //TODO: Manage Firebase errors appropriately
            completed(nil)
            if let _ = error {
                //Error updating document
                completed(TTError.unableToUpdateUser)
            }
        }
    }
    
    func deleteGroup(for groupCode: String, completed: @escaping(TTError?) -> Void) {
        db.collection(TTConstants.groupsCollection).document(groupCode).delete() { err in
            if let _ = err {
                completed(TTError.unableToDeleteGroup)
            } else {
                completed(nil)
            }
        }
    }
    
    //MARK: - Authentication
    
    func createUser(firstName: String, lastName: String, email: String, password: String, username: String, completed: @escaping(Result<Void, TTError>) -> Void) {
        //check to see if email and or password fields are empty
        guard email != "", password != "" else {
            completed(.failure(.textFieldsCannotBeEmpty))
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            
            guard let newUser = authResult?.user, error == nil, let self = self else {
                print("failure")
                completed(.failure(.unableToCreateUser))
                return
            }
            
            //update displayname (separate from data in firestore as it's part of the authentication)
            self.updateUserProfile(displayName: username)
            
            self.createUserDocument(firstName: firstName, lastName: lastName, email: email, username: username, uid: newUser.uid) { result in
                switch result {
                case .success(_):
                    //get user data
                    self.fetchUserDocumentData(with: username) { result in
                        switch result {
                        case .success(let user):
                            self.currentUser = user
                            self.goToSearchScreen()
                        case .failure(let error):
                            completed(.failure(error))
                        }
                    }
                    completed(.success(()))
                case .failure(let error):
                    completed(.failure(error))
                }
            }
        }
    }
    
    private func createUserDocument(firstName: String, lastName: String, email: String, username: String, uid: String, completed: @escaping(Result<Void, TTError>) -> Void) {
        
        db.collection(TTConstants.usersCollection).document(username).setData([
            "uid": uid,
            "firstname": firstName,
            "lastname": lastName,
            "username": username,
            "friends": [],
            "friendRequests": [],
            "groupCodes": []
        ]) { err in
            if let _ = err {
                completed(.failure(.unableToCreateFirestoreAssociatedUser))
            } else {
                completed(.success(()))
            }
        }
    }
    
    func signInUser(email: String, password: String, completed: @escaping(Result<Void, TTError>) -> Void) {
        
        //check to see if email and or password fields are empty
        guard email != "", password != "" else {
            completed(.failure(.textFieldsCannotBeEmpty))
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            guard let _ = error else {
                completed(.success(()))
                return
            }
            completed(.failure(.unableToSignInUser))
        }
    }
    
    func signOutUser(completed: @escaping(Result<Void, TTError>) -> Void) {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            stopListeningToCurrentUser()
            self.goToLoginScreen(animated: true)
            completed(.success(()))
        } catch {
            completed(.failure(.unableToSignOutUser))
        }
    }
    
    func getCurrentUserEmail() -> String? {
        if let currentAuthUser = Auth.auth().currentUser {
            return currentAuthUser.email
        }
        return nil
    }
    
    func goToTabBarController() {
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(createTabbar())
    }
    
    //MARK: - Create UITabBarController
    
    func createTabbar() -> UITabBarController {
        let tabbar = UITabBarController()
        UITabBar.appearance().tintColor = .systemGreen
        tabbar.viewControllers = [createGroupNC(), createGroupsNC(), createFriendsNC(), createSettingsNC()]
        tabbar.tabBar.isTranslucent = true
        tabbar.tabBar.backgroundImage = UIImage()
        tabbar.tabBar.shadowImage = UIImage() // add this if you want remove tabBar separator
        tabbar.tabBar.barTintColor = .clear
        tabbar.tabBar.backgroundColor = .black // here is your tabBar color
        tabbar.tabBar.layer.backgroundColor = UIColor.clear.cgColor
        
        let blurEffect = UIBlurEffect(style: .regular) // here you can change blur style
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = tabbar.view.bounds
        blurView.autoresizingMask = .flexibleWidth
        tabbar.tabBar.insertSubview(blurView, at: 0)
                                              
        return tabbar
    }
    
    private func createGroupNC() -> UINavigationController {
        let searchVC = CreateGroupVC()
        searchVC.title = "Create Group"
        searchVC.tabBarItem = UITabBarItem(title: "Create Group", image: UIImage(systemName: "door.left.hand.open"), tag: 0)
        return UINavigationController(rootViewController: searchVC)
    }
    
    private func createGroupsNC() -> UINavigationController {
        let groupsVC = GroupsVC()
        groupsVC.title = "Groups"
        groupsVC.tabBarItem = UITabBarItem(title: "Groups", image: UIImage(systemName: "rectangle.on.rectangle"), tag: 1)
        return UINavigationController(rootViewController: groupsVC)
    }
    
    private func createFriendsNC() -> UINavigationController {
        let friendsVC = FriendsVC()
        friendsVC.tabBarItem = UITabBarItem(title: "Friends", image: UIImage(systemName: "person.3"), tag: 2)
        return UINavigationController(rootViewController: friendsVC)
    }
    
    private func createSettingsNC() -> UINavigationController {
        let settingsVC = TTHostingController(rootView: SettingsView())
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 3)
        return UINavigationController(rootViewController: settingsVC)
    }

}
