//
//  Notification.Name+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/27/22.
//

import Foundation

extension Notification.Name {
    static var updatedUser: Notification.Name {
        return .init(rawValue: "Firebase.updatedUser")
    }
    
    static var updatedCurrentUserGroups: Notification.Name {
        return .init(rawValue: "Firebase.updatedCurrentUserGroups")
    }
}
