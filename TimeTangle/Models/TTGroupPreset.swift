//
//  TTGroupPreset.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/14/23.
//

import Foundation

//MARK: - TTGroupPreset
struct TTGroupPreset: Hashable, Codable, Identifiable {
    var id: String
    var name: String
    var userIDs: [String]
    private var users: [TTUser]?
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "userIDs": userIDs
        ]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(id: String, name: String, userIDs: [String]) {
        self.id = id
        self.name = name
        self.userIDs = userIDs
    }
    
    func getUsers() -> [TTUser]? {
        return users
    }
}
