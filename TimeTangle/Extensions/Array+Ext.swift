//
//  Array+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 10/19/23.
//

import Foundation

protocol FirestoreDataCompatible {
    var dictionary: [String: Any] { get }
}

extension Array where Element == TTUser {
    func getUsernames() -> [String] {
        return self.map{ $0.username }
    }
}

extension Collection where Element == TTGroup {
    func getCodes() -> [String] {
        return self.map{ $0.code }
    }
}

extension Array where Element : FirestoreDataCompatible {
    func getFirestoreDictionaries() -> [[String: Any]] {
        return self.map{ $0.dictionary }
    }
}
