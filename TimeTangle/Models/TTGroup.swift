//
//  TTGroup.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import Foundation
import FirebaseFirestore

typealias TTGroupEditType = TTGroupEdit.TTGroupEditType
typealias TTGroupEditDifference = TTGroupEdit.TTGroupEditDifference

struct TTGroup: Codable, Equatable, Hashable {
    var name: String
    var users: [String]
    var code: String //A 5 letter Code
    var startingDate: Date
    var endingDate: Date
    var histories: [TTGroupEdit]
    var events: [TTEvent]
    var admins: [String]
    var setting: TTGroupSetting
    
    static func == (lhs: TTGroup, rhs: TTGroup) -> Bool {
        return lhs.users == rhs.users &&
        lhs.code == rhs.code &&
        lhs.startingDate == rhs.startingDate &&
        lhs.endingDate == rhs.endingDate &&
        lhs.events == rhs.events
    }
    
    func doesContainsAdmin(for id: String) -> Bool {
        return admins.contains(where: { $0 == id })
    }
}

//MARK: - TTGroupEdit
struct TTGroupEdit: Codable, Hashable {
    var author: String
    var authorID: String
    var createdDate: Date
    var editDifference: TTGroupEditDifference
    var editType: TTGroupEditType
    
    var dictionary: [String: Any] {
         return [
            "author": author,
            "authorID": authorID,
            "createdDate": createdDate,
            "editDifference": editDifference,
            "editType": editType
         ]
    }
    
    struct TTGroupEditDifference: Codable, Hashable {
        var before: String?
        var after: String?
    }
    
    enum TTGroupEditType: String, Hashable {
        case addedUserToGroup
        case removedUserFromGroup
        case changedStartingDate
        case changedEndingDate
        case userSynced
        case none
        
        var description: String {
            get {
                switch self {
                case .addedUserToGroup: return "addedUserToGroup"
                case .removedUserFromGroup: return "removedUserFromGroup"
                case .changedStartingDate: return "changedStartingDate"
                case .changedEndingDate: return "changedEndingDate"
                case .userSynced: return "userSynced"
                case .none: return "none"
                }
            }
        }
        
        static func getTTGroupEditType(editType: String) -> TTGroupEditType {
            switch editType {
            case "addedUserToGroup":
                return .addedUserToGroup
            case "removedUserFromGroup":
                return .removedUserFromGroup
            case "changedStartingDate":
                return .changedStartingDate
            case "changedEndingDate":
                return .changedEndingDate
            case "userSynced":
                return .userSynced
            default:
                return .none
            }
        }
    }
}

extension TTGroupEditType: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = TTGroupEditType.getTTGroupEditType(editType: rawValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}

//MARK: - TTGroupSetting
struct TTGroupSetting: Codable, Hashable {
    var minimumNumOfUsers: Int
    var maximumNumOfUsers: Int
    var boundedStartDate: Date
    var boundedEndDate: Date
    var lockGroupChanges: Bool
    var allowGroupJoin: Bool
}

struct TTGroupModification {
    var group: TTGroup
    var modificationType: DocumentChangeType
}
