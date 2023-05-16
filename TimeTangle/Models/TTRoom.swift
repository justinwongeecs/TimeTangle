//
//  TTRoom.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/26/22.
//

import Foundation

typealias TTRoomEditType = TTRoomEdit.TTRoomEditType
typealias TTRoomEditDifference = TTRoomEdit.TTRoomEditDifference

struct TTRoom: Codable, Equatable {
    var name: String
    var users: [String]
    var code: String //A 5 letter Code
    var startingDate: Date
    var endingDate: Date
    var histories: [TTRoomEdit]
    var events: [TTEvent]
    
    static func == (lhs: TTRoom, rhs: TTRoom) -> Bool {
        return lhs.users == rhs.users &&
        lhs.code == rhs.code &&
        lhs.startingDate == rhs.startingDate &&
        lhs.endingDate == rhs.endingDate &&
        lhs.events == rhs.events
    }
}

struct TTRoomEdit: Codable {
    var author: String
    var createdDate: Date
    var editDifference: TTRoomEditDifference
    var editType: TTRoomEditType
    
    var dictionary: [String: Any] {
         return [
            "author": author,
            "createdDate": createdDate,
            "editDifference": editDifference,
            "editType": editType
         ]
    }
    
    struct TTRoomEditDifference: Codable {
        var before: String?
        var after: String?
    }
    
    enum TTRoomEditType: String {
        case addedUserToRoom 
        case changedStartingDate
        case changedEndingDate
        case none
        
        var description: String {
            get {
                switch self {
                case .addedUserToRoom: return "addedUserToRoom"
                case .changedStartingDate: return "changedStartingDate"
                case .changedEndingDate: return "changedEndingDate"
                case .none: return "none"
                }
            }
        }
        
        static func getTTRoomEditType(editType: String) -> TTRoomEditType {
            switch editType {
            case "addedUserToRoom":
                return .addedUserToRoom
            case "changedStartingDate":
                return .changedStartingDate
            case "changedEndingDate":
                return .changedEndingDate
            default:
                return .none
            }
        }
    }
}

extension TTRoomEditType: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = TTRoomEditType.getTTRoomEditType(editType: rawValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}
