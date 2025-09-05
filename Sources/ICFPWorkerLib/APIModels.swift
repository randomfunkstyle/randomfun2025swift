import Foundation

// MARK: - Register
public struct RegisterRequest: Codable {
    public let name: String
    public let pl: String
    public let email: String
    
    public init(name: String, pl: String, email: String) {
        self.name = name
        self.pl = pl
        self.email = email
    }
}

public struct RegisterResponse: Codable {
    public let id: String
}

// MARK: - Select
public struct SelectRequest: Codable {
    public let id: String
    public let problemName: String
    
    public init(id: String, problemName: String) {
        self.id = id
        self.problemName = problemName
    }
}

public struct SelectResponse: Codable {
    public let problemName: String
}

// MARK: - Explore
public struct ExploreRequest: Codable {
    public let id: String
    public let plans: [String]
    
    public init(id: String, plans: [String]) {
        self.id = id
        self.plans = plans
    }
}

public struct ExploreResponse: Codable {
    public let results: [[Int]]
    public let queryCount: Int
}

// MARK: - Guess
public struct GuessRequest: Codable {
    public let id: String
    public let map: MapDescription
    
    public init(id: String, map: MapDescription) {
        self.id = id
        self.map = map
    }
}

public struct GuessResponse: Codable {
    public let correct: Bool
}

public struct MapDescription: Codable {
    public let rooms: [Int]
    public let startingRoom: Int
    public let connections: [Connection]
    
    public init(rooms: [Int], startingRoom: Int, connections: [Connection]) {
        self.rooms = rooms
        self.startingRoom = startingRoom
        self.connections = connections
    }
}

public struct Connection: Codable {
    public let from: RoomDoor
    public let to: RoomDoor
    
    public init(from: RoomDoor, to: RoomDoor) {
        self.from = from
        self.to = to
    }
}

public struct RoomDoor: Codable {
    public let room: Int
    public let door: Int
    
    public init(room: Int, door: Int) {
        self.room = room
        self.door = door
    }
}


public extension  Array where Element == Connection {
    mutating func connect(room: Int, door: Int, toRoom: Int, toDoor: Int) {
        self.append(Connection(from: RoomDoor(room: room, door: door), to: RoomDoor(room: toRoom, door: toDoor)))
    }
}