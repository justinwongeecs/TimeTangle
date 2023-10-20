//
//  Array+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 10/19/23.
//

import Foundation

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
